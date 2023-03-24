#! /usr/bin/env python3

"""Dotfiles setup
--------------

run this script with:
python3 <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig/mkconfig.py) -h

INSTALL:
- fd-find (Linux),        ln -s /bin/fdfind ~/bin/fd
- batcat  (debian),       ln -s /bin/batcat ~/bin/bat
- wslu    (Windows wsl2), open browser pages
"""

# TODO:
# ssh -T git@github.com to accept IP
# migrate `scripts/db-create` to python
# add more type hints
# mkconfig -L issue on macOS: delete last with Path(argv[0])?
# Remove hard-coded reference of ~/repos in help messages + README file

from dataclasses import dataclass
from os import environ as env, PathLike
from sys import argv, stderr, platform, version_info
from pathlib import Path
from subprocess import run
from multiprocessing import Process
from signal import signal, SIGINT
from pprint import pprint
from textwrap import dedent
import asyncio
import argparse

try:
    from git.repo import Repo as GitRepo
    from git.exc import GitCommandError, NoSuchPathError, InvalidGitRepositoryError
    from decorate import Text  # pyright: ignore reportMissingImports
except (ModuleNotFoundError, ImportError) as err:
    print(err, file=stderr)

    if "git" in str(err):
        dedent(
            """
            Please Install `mkconfig`:

            cd ~/repos/github/scripts/mkconfig
            python3 -mvenv .venv
            source .venv/bin/activate
            pip install -U pip
            pip install -e mkconfig

            now you can use `mkconfig`
            """
        ).strip()

    if "decorate" in str(err):
        dedent(
            """
            Please Install `decorate`:

            mkdir -p ~/repos/gitlab
            cd ~/repos/gitlab
            git clone git@gitlab.com:kurkale6ka/styles.git
            source ~/repos/github/scripts/mkconfig/.venv/bin/activate
            pip install -U pip
            pip install -e styles
            """
        ).strip()

    exit(1)


def interrupt_handler(sig, frame):  # pyright: ignore reportUnusedVariable
    print("\nBye")
    exit()


signal(SIGINT, interrupt_handler)

# NB: can't be commented out. REPOS_BASE is used in other parts (e.g. zsh)
if not "REPOS_BASE" in env:
    print(Text("exporting REPOS_BASE to").red, Text("~/repos").dir, file=stderr)
    env["REPOS_BASE"] = env["HOME"] + "/repos"
    Path(env["REPOS_BASE"]).mkdir(exist_ok=True)

base = env["REPOS_BASE"]
user = "kurkale6ka"

# XDG Variables
if not "XDG_CONFIG_HOME" in env:
    print(Text("setting XDG Variables to their default values").red, file=stderr)
    env["XDG_CONFIG_HOME"] = f"{env['HOME']}/.config"
    env["XDG_DATA_HOME"] = f"{env['HOME']}/.local/share"
    Path(env["XDG_CONFIG_HOME"]).mkdir(exist_ok=True)
    Path(env["XDG_DATA_HOME"]).mkdir(parents=True, exist_ok=True)

# TODO: --dry-run?
parser = argparse.ArgumentParser(prog="mkconfig", description="Dotfiles setup")
parser.add_argument(
    "-N",
    "--install-nvim-python-client",
    action="store_true",
    help="Install/Upgrade Neovim's Python client, plus other `venv`s in `~/py-envs` and their packages",
)
parser.add_argument(
    "-i", "--init", action="store_true", help="Initial setup"
)  # TODO: make mutually exclusive with the rest
parser.add_argument(
    "-d",
    "--cd-db-create",
    action="store_true",
    help="Create fuzzy cd database (needs sqlite3)",
)
parser.add_argument("-g", "--git-config", action="store_true", help="git config")
parser.add_argument(
    "-t",
    "--tags",
    action="store_true",
    help="Generate ~/repos/tags (needs universal ctags)",
)
parser.add_argument("-v", "--verbose", action="store_true")
grp_ln = parser.add_mutually_exclusive_group()
grp_ln.add_argument("-l", "--links", action="store_true", help="Make links")
grp_ln.add_argument("-L", "--delete-links", action="store_true", help="Remove links")
grp_git = parser.add_mutually_exclusive_group()
grp_git.add_argument("-s", "--status", action="store_true", help="git status")
grp_git.add_argument("-u", "--update", action="store_true", help="Update repositories")
grp_cln = parser.add_argument_group("Clone repositories")
grp_cln.add_argument("-c", "--clone", action="store_true", help="git clone")
grp_cln.add_argument(
    "-p",
    "--clone-protocol",
    type=str,
    choices=["git", "https"],
    default="git",
    help="'git clone' protocol",
)
grp_cln.add_argument(
    "-C", dest="clone_dst", type=str, help="cd to this directory before cloning"
)
grp_extra = parser.add_argument_group("Extra")
grp_extra.add_argument(
    "--vim-plug-help", action="store_true", help="https://github.com/junegunn/vim-plug"
)
grp_extra.add_argument("--perl-cpan-help", action="store_true", help="CPAN modules")
args = parser.parse_args()


class Link:
    # args is a string, e.g '-rT' => makes a relative link to a directory
    def __init__(self, src, dst, args=None):
        self._src = src
        self._dst = dst
        self._args = args

    # source getter/setter
    @property
    def src(self):
        return self._src

    @src.setter
    def src(self, value):
        self._src = value

    # destination getter/setter
    @property
    def dst(self):
        return self._dst

    @dst.setter
    def dst(self, value):
        self._dst = value

    def create(self, verbose=False):
        cmd = ["ln", "-sf"]

        # extra args
        if verbose:
            cmd.append("-v")
        if self._args:
            cmd.append(self._args)

        cmd.append(self._src)
        cmd.append(self._dst)

        p = Process(target=run, args=(cmd,))
        p.start()
        p.join()

    def remove(self, verbose=False):
        cmd = ["rm"]

        if verbose:
            cmd.append("-v")

        if Path(self._dst).is_dir() and not Path(self._dst).is_symlink():
            cmd.append(self._dst + "/" + Path(self._src).name)
        else:
            cmd.append(self._dst)

        p = Process(target=run, args=(cmd,))
        p.start()
        p.join()


class Repo:
    """A github/gitlab repository"""

    def __init__(self, root, links=(), action=None):
        self._links = links
        self._root = root
        self._name = Path(self._root).name
        try:
            self._repo = GitRepo(self._root)
        except (NoSuchPathError, InvalidGitRepositoryError):
            if action != "clone":
                raise

    async def clone(self, where, protocol="git", hub="github", verbose=False):
        if protocol == "git":
            url = f"{protocol}@{hub}.com:{user}/{self._name}.git"
        else:
            url = f"{protocol}://{hub}.com/{user}/{self._name}.git"

        cmd = ["git", "-C", where, "clone", url]
        if not verbose:
            cmd.append("-q")

        proc = await asyncio.create_subprocess_exec(*cmd)
        code = await proc.wait()

        if code == 0:
            print(Text("*").cyan, f"cloned {self._name}")

    def create_links(self, verbose=False):
        for link in self._links:
            if link.src:
                link.src = self._root + "/" + link.src
            else:
                link.src = self._root  # needed for the nvim/vim folder links
            link.create(verbose)

    async def fetch(self):
        proc = await asyncio.create_subprocess_exec(
            "git", "-C", self._root, "fetch", "--prune", "-q"
        )
        await proc.wait()

    async def status(self, verbose=False):
        # TODO: include stash info
        await self.fetch()
        if (
            self._repo.is_dirty(untracked_files=True)
            or self._repo.active_branch.name not in ("main", "master")
            or self._repo.git.rev_list("--count", "HEAD...HEAD@{u}") != "0"
        ):
            if verbose:
                print(
                    Text(self._name).cyan + ":",
                    self._repo.git(P=True).diff("--color=always", "-w"),
                )
            else:
                print(
                    Text(self._name).cyan + ":",
                    self._repo.git(c="color.status=always").status("-sb"),
                )

    # TODO: is it safe? make safer?
    async def update(self):
        try:
            print(
                Text(self._name).cyan + ":",
                self._repo.git(c="color.ui=always").pull("--prune"),
            )
        except GitCommandError as err:
            print(
                Text(self._name).cyan + ":",
                Text(err.stderr.lstrip().replace("\n", "\n\t")).red,
            )


@dataclass
class RepoData:
    name: str
    hub: str = "github"
    enabled: bool = True  # TODO: ~/.config/myrepos -- enable/disable in a .rc file
    links: tuple = ()
    dirs: tuple = ()  # create repository dirs as needed. e.g. ln -s src [dst], ...
    make_links: bool = True

    # dirs
    def __post_init__(self):
        Path(f"{base}/{self.hub}").mkdir(parents=True, exist_ok=True)
        for dir in self.dirs:
            Path(dir).mkdir(exist_ok=True)


repos = (
    RepoData(
        "nvim",
        links=(Link(None, f"{env['XDG_CONFIG_HOME']}/nvim", "-T"),),
    ),
    RepoData(
        "vim",
        links=(
            Link(None, f"{env['HOME']}/.vim", "-rT"),
            Link(".vimrc", f"{env['HOME']}", "-r"),
            Link(".gvimrc", f"{env['HOME']}", "-r"),
        ),
    ),
    RepoData(
        "zsh",
        dirs=(
            f"{env['XDG_CONFIG_HOME']}/zsh",
            f"{env['XDG_DATA_HOME']}/zsh",  # for zsh history file
        ),
        links=(
            Link(".zshenv", f"{env['HOME']}", "-r"),
            Link(".zprofile", f"{env['XDG_CONFIG_HOME']}/zsh"),
            Link(".zshrc", f"{env['XDG_CONFIG_HOME']}/zsh"),
            Link("autoload", f"{env['XDG_CONFIG_HOME']}/zsh"),
        ),
    ),
    RepoData(
        "bash",
        links=(
            Link(".bash_profile", f"{env['HOME']}", "-r"),
            Link(".bashrc", f"{env['HOME']}", "-r"),
            Link(".bash_logout", f"{env['HOME']}", "-r"),
        ),
        make_links=False,
    ),
    RepoData(
        "scripts",
        dirs=(f"{env['HOME']}/bin",),
        links=(
            Link("helpers.py", f"{env['HOME']}/.pyrc", "-r"),
            Link("backup.pl", f"{env['HOME']}/bin/b"),
            Link("ex.py", f"{env['HOME']}/bin/ex"),
            Link("calc.pl", f"{env['HOME']}/bin/="),
            Link("cert.pl", f"{env['HOME']}/bin/cert"),
            Link("mkconfig/.venv/bin/mkconfig", f"{env['HOME']}/bin"),
            Link("mini.pl", f"{env['HOME']}/bin/mini"),
            Link("pics.pl", f"{env['HOME']}/bin/pics"),
            Link("pc.pl", f"{env['HOME']}/bin/pc"),
            Link("rseverywhere.pl", f"{env['HOME']}/bin/rseverywhere"),
            Link("vpn.py", f"{env['HOME']}/bin/vpn"),
            Link("www.py", f"{env['HOME']}/bin/www"),
            Link("colors_term.bash", f"{env['HOME']}/bin"),
            Link("colors_tmux.bash", f"{env['HOME']}/bin"),
        ),
    ),
    RepoData(
        "config",
        dirs=(
            f"{env['HOME']}/bin",
            f"{env['XDG_CONFIG_HOME']}/git",
            f"{env['XDG_CONFIG_HOME']}/bat",
        ),
        links=(
            Link("tmux/lay.pl", f"{env['HOME']}/bin/lay"),
            Link("tmux/Nodes.pm", f"{env['HOME']}/bin/nodes"),
            Link("dotfiles/.gitignore", f"{env['XDG_CONFIG_HOME']}/git/ignore"),
            Link("dotfiles/.irbrc", f"{env['HOME']}", "-r"),
            Link("dotfiles/.Xresources", f"{env['HOME']}", "-r"),
            Link("ctags/.ctags", f"{env['HOME']}", "-r"),
            Link("tmux/.tmux.conf", f"{env['HOME']}", "-r"),
            Link("XDG/bat_config", f"{env['XDG_CONFIG_HOME']}/bat/config"),
        ),
    ),
    RepoData("help"),
    RepoData("styles", hub="gitlab"),
    RepoData("vim-chess", enabled=False),
    RepoData("vim-desertEX", enabled=False),
    RepoData("vim-pairs", enabled=False),
)

# Don't use a tuple here!
# We loop over this variable in many functions, which means we can't have it
# exhausted after a single pass through
repos = [repo for repo in repos if repo.enabled]


def upgrade_venvs(msg="Installing pip modules (pynvim, ...)", clear=False):
    from venv import EnvBuilder

    class Venv(EnvBuilder):
        def __init__(self, packages=()):
            super().__init__(with_pip=True, upgrade_deps=True, clear=clear)
            self._packages = packages
            # self._tasks = []

        # async def install_packages(self):
        #     # TODO: gather results to improve display
        #     for task in asyncio.as_completed(self._tasks):
        #         await task

        def post_setup(self, context):
            run((context.env_exe, "-m", "pip", "install", "--upgrade", "wheel"))
            cmd = (
                context.env_exe,
                "-m",
                "pip",
                "install",
                "--upgrade",
                *self._packages,
            )
            # self._tasks.append(asyncio.create_subprocess_exec(*cmd))
            run(cmd)

    # TODO: dataclass PythonVenv(name, packages, enable)
    python_venvs = {
        "neovim": ("pynvim",),
    }

    print(f"{msg}\n")
    for name, packages in python_venvs.items():
        builder = Venv(packages=packages)
        builder.create(f"{env['HOME']}/py-envs/{name}")
        # asyncio.run(builder.install_packages())


# TODO: show progress bar with tqdm?
# for task in tqdm.as_completed(tasks, leave=False, ascii=' =', colour='green', ncols=139, desc='Updating repos...'):
def init(args):
    if platform == "darwin":
        # needed when 'ln' is actually 'gln'
        path = env["PATH"].split(":")
        path.insert(0, "/usr/local/opt/coreutils/libexec/gnubin")
        env["PATH"] = ":".join(path)

    print(
        Text("-").cyan,
        f"Cloning repositories in {Text(base.replace(env['HOME'], '~')).dir}...",
    )
    asyncio.run(git_clone(args.clone_dst, args.clone_protocol, args.verbose))

    print(Text("-").cyan, "Linking dot files")
    create_links(args.verbose)

    print(Text("-").cyan, "Configuring git")
    git_config(args.verbose)

    print(Text("-").cyan, "Generating tags")
    ctags(args.verbose)

    print(Text("-").cyan, "Creating fuzzy cd database")
    cd_db_create(args.verbose)

    # macOS
    if platform == "darwin":
        print(Text("-").cyan, "Installing Homebrew formulae...")
        formulae = (
            "cpanminus",
            "bash",
            "zsh",
            "shellcheck",
            "ed",
            "gnu-sed",
            "gawk",
            "jq",
            "vim",
            "htop",
            "hyperfine",
            "fd",
            "findutils",
            "coreutils",
            "moreutils",
            "grep",
            "ripgrep",
            "mariadb",
            "sqlite",
            "colordiff",
            "bat",
            "git",
            # 'ctags', # make sure this is universal ctags!
            "gnu-tar",
            "ipcalc",
            "iproute2mac",
            "openssh",
            "tcpdump",
            "telnet",
            "tmux",
            "weechat",
            "tree",
            "gcal",
            "nmap",
            "dos2unix",
            "wgetpaste",
            "whois",
        )

        auto_update = "HOMEBREW_NO_AUTO_UPDATE=1"

        # try a single install before continuing
        cmd = ["env", auto_update, "brew", "install", "--HEAD", "neovim"]
        res = run(cmd)
        if res.returncode != 0:
            exit(1)

        cmd = ["env", auto_update, "brew", "install", formulae]
        run(cmd)

        cmd = ["env", auto_update, "brew", "install", "parallel", "--force"]
        run(cmd)

        cmd = ["env", auto_update, "brew", "tap", "beeftornado/rmtree"]
        run(cmd)

        cmd = ["env", auto_update, "brew", "install", "beeftornado/rmtree/brew-rmtree"]
        run(cmd)


async def git_clone(dst: str | PathLike, protocol: str, verbose: bool = False) -> None:
    if version_info[0] == 3 and version_info[1] >= 11:
        async with asyncio.TaskGroup() as tg:  # pyright: ignore reportGeneralTypeIssues
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}", action="clone")
                tg.create_task(
                    repo.clone(
                        dst or f"{base}/{r.hub}",
                        protocol=protocol,
                        hub=r.hub,
                        verbose=verbose,
                    )
                )
    else:
        tasks = []
        for r in repos:
            repo = Repo(f"{base}/{r.hub}/{r.name}", action="clone")
            tasks.append(
                repo.clone(
                    dst or f"{base}/{r.hub}",
                    protocol=protocol,
                    hub=r.hub,
                    verbose=verbose,
                )
            )
        for task in asyncio.as_completed(tasks):
            await task


def create_links(verbose: bool = False) -> None:
    for r in repos:
        if r.make_links:
            repo = Repo(f"{base}/{r.hub}/{r.name}", r.links)
            p = Process(target=repo.create_links, args=(verbose,))
            p.start()
            p.join()


def remove_links(verbose: bool = False) -> None:
    script_path = Path(argv[0]).resolve(strict=True)

    for r in repos:
        if r.make_links:
            for link in r.links:
                p = Process(target=link.remove, args=(verbose,))
                p.start()
                p.join()

    if verbose:
        print()
    print(f"Restore links with:\n{script_path} -l".replace(env["HOME"], "~"))


def git_config(verbose: bool = False) -> None:
    cmd = ("bash", f"{base}/github/config/git.bash")

    if verbose:
        print(" ".join(cmd).replace(env["HOME"], "~"))

    run(cmd)


def ctags(verbose: bool = False) -> None:
    cmd = [
        "ctags",
        "-R",
        f"-f {env['HOME']}/repos/tags",
        # "--langmap=zsh:+.",  # files without extension. TODO: fix! not fully working, e.g. net/dig: variable 'out' not found. (zsh/autoload/*) vs . doesn't help
        "--exclude=.*~",  # *~ is excluded by default, cf. ctags --list-excludes
        "--exclude=.venv",
        "--exclude=*.adoc",
        "--exclude=*.md",
        "--exclude=*.rst",
        "--exclude=keymap",
        "--exclude=lazy-lock.json",  # lazy nvim
    ]

    cmd.extend(f"{base}/{repo.hub}/{repo.name}" for repo in repos if repo.name != "vim")

    Path(f"{env['XDG_CONFIG_HOME']}/zsh/after").mkdir(parents=True, exist_ok=True)
    cmd.append(f"{env['XDG_CONFIG_HOME']}/zsh/after")

    if Path(f"{env['XDG_CONFIG_HOME']}/zsh/.zshrc_after").is_file():
        cmd.append(f"{env['XDG_CONFIG_HOME']}/zsh/.zshrc_after")

    if verbose:
        pprint(cmd)
        print()
        print(
            " ".join(cmd)
            .replace(env["HOME"], "~")
            .replace(env["XDG_CONFIG_HOME"], "~/.config")
        )

    run(cmd)


def cd_db_create(verbose: bool = False) -> None:
    script = f"{base}/github/scripts/db-create"
    cmd = ("bash", script)

    if verbose:
        print(" ".join(cmd).replace(env["HOME"], "~"))
        print()
        run(("bat", "--language=bash", script))

    run(cmd)


async def git_status(verbose: bool = False) -> None:
    if version_info[0] == 3 and version_info[1] >= 11:
        async with asyncio.TaskGroup() as tg:  # pyright: ignore reportGeneralTypeIssues
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}")
                tg.create_task(repo.status(verbose))
    else:
        # TODO: perf test to ensure it's actually happening in parallel
        tasks = []
        for r in repos:
            repo = Repo(f"{base}/{r.hub}/{r.name}")
            tasks.append(repo.status(verbose))
        for task in asyncio.as_completed(tasks):
            await task


# TODO: add -v/-q as needed
async def git_pull() -> None:
    if version_info[0] == 3 and version_info[1] >= 11:
        async with asyncio.TaskGroup() as tg:  # pyright: ignore reportGeneralTypeIssues
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}")
                tg.create_task(repo.update())
    else:
        tasks = []
        for r in repos:
            repo = Repo(f"{base}/{r.hub}/{r.name}")
            tasks.append(repo.update())
        for task in asyncio.as_completed(tasks):
            await task


def main() -> None:
    if args.install_nvim_python_client:
        upgrade_venvs(msg="Upgrading pip modules (pynvim, ...)")

    if args.init:
        init(args)

    if args.clone:
        asyncio.run(git_clone(args.clone_dst, args.clone_protocol, args.verbose))

    if args.links:
        create_links(args.verbose)

    if args.delete_links:
        remove_links(args.verbose)

    if args.git_config:
        git_config(args.verbose)

    if args.tags:
        ctags(args.verbose)

    if args.cd_db_create:
        cd_db_create(args.verbose)

    if args.status:
        asyncio.run(git_status(args.verbose))

    if len(argv) == 1 or args.update:  # no args or --update
        asyncio.run(git_pull())

    if args.vim_plug_help:
        print(
            dedent(
                """
                curl -fLo /home/mitko/repos/github/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
                REPOS_BASE=/home/mitko/repos vim -c PlugInstall
                """
            ).strip()
        )

    if args.perl_cpan_help:
        print(
            dedent(
                """
                cpanm -l ~/perl5 local::lib # see .zshrc for explanations, needs cpanminus
                cpanm Term::ReadLine::Gnu
                """
            ).strip()
        )


if __name__ == "__main__":
    main()
