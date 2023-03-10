#! /usr/bin/env python3

"""Dotfiles setup
--------------

run this script with:
python3 <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.py) -h

TODO:
ssh -T git@github.com to accept IP
migrate `scripts/db-create` to python
use annotations?
catch interrupt signal?

INSTALL:
- fd-find (Linux),        ln -s /bin/fdfind ~/bin/fd
- batcat  (debian),       ln -s /bin/batcat ~/bin/bat
- wslu    (Windows wsl2), open browser pages
"""

from dataclasses import dataclass
from os import environ as env
from sys import argv, stderr, platform, version_info, path as pythonpath
from pathlib import Path
from subprocess import run
from multiprocessing import Process
from signal import signal, SIGINT
from pprint import pprint
import asyncio
import argparse

if Path(f"{env['HOME']}/py-envs/python-modules/lib").is_dir():
    # Add gitpython's venv to sys.path
    version = Path(env["HOME"] + "/py-envs/python-modules/lib").iterdir()
    pythonpath.append(
        f"{env['HOME']}/py-envs/python-modules/lib/{next(version).name}/site-packages"
    )


def interrupt_handler(sig, frame):
    print("\nBye")
    exit()


signal(SIGINT, interrupt_handler)


def upgrade_venvs(msg="Installing pip modules...", clear=False):
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
        "python-modules": ("gitpython", "tqdm"),
        "neovim": ("pynvim",),
        "neovim-modules": (  # LSP linters/formatters/...
            # "ansible-lint", # is this provided by the LSP now?
            "black",
        ),
        # awsume comes with boto3, aws cli INSTALL is separate, in /usr/local/
        "aws-modules": ("awsume",),
        # "az-modules": ('az',),
    }

    print(f"{msg}\n")
    for name, packages in python_venvs.items():
        builder = Venv(packages=packages)
        builder.create(f"{env['HOME']}/py-envs/{name}")
        # asyncio.run(builder.install_packages())


try:
    from git.repo import Repo as GitRepo
    from git.exc import GitCommandError, NoSuchPathError, InvalidGitRepositoryError
    from styles.styles import Text
except ModuleNotFoundError as err:
    print(err, file=stderr)

    from textwrap import dedent

    if "git" in str(err):
        answer = "n"
        if Path(f"{env['HOME']}/py-envs").is_dir():
            answer = input("Do you want to reinstall pip modules? (y/n) ")
        if answer == "y":
            upgrade_venvs(clear=True)
    if "styles" in str(err):
        Path(f"{env['HOME']}/repos").mkdir(parents=True, exist_ok=True)
        print(
            dedent(
                """
                Install the `styles` module with:
                git -C ~/repos/gitlab clone git@gitlab.com:kurkale6ka/styles.git
                """
            ).rstrip(),
            file=stderr,
        )

    exit(
        dedent(
            """
            export PYTHONPATH=~/repos/gitlab
            and re-run!
            """
        ).rstrip()
    )

# NB: can't be commented out. REPOS_BASE is used in other parts (e.g. zsh)
if not "REPOS_BASE" in env:
    print(Text("exporting REPOS_BASE to").red, Text("~/repos").fg(69), file=stderr)
    env["REPOS_BASE"] = env["HOME"] + "/repos"
    Path(env["REPOS_BASE"]).mkdir(exist_ok=True)

base = env["REPOS_BASE"]
user = "kurkale6ka"

# XDG Variables
if not "XDG_CONFIG_HOME" in env:
    print(Text("setting XDG Variables to their default values").red, file=stderr)
    env["XDG_CONFIG_HOME"] = f"{env['HOME']}/.config"
    env["XDG_DATA_HOME"] = f"{env['HOME']}/.local/share"
    Path(env["XDG_CONFIG_HOME"]).mkdir(parents=True, exist_ok=True)
    Path(env["XDG_DATA_HOME"]).mkdir(parents=True, exist_ok=True)

# TODO: --dry-run?
parser = argparse.ArgumentParser(prog="mkconfig", description="Dotfiles setup")
grp_cln = parser.add_argument_group("Clone repositories")
grp_ln = parser.add_mutually_exclusive_group()
grp_git = parser.add_mutually_exclusive_group()
parser.add_argument(
    "-U",
    "--ugrade-venv-packages",
    action="store_true",
    help="Upgrade python `venv`s and their packages",
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
parser.add_argument("-g", "--git-config", action="store_true", help="git config")
parser.add_argument(
    "-t",
    "--tags",
    action="store_true",
    help="Generate ~/repos/tags (needs universal ctags)",
)
parser.add_argument("-v", "--verbose", action="store_true")
grp_ln.add_argument("-l", "--links", action="store_true", help="Make links")
grp_ln.add_argument("-L", "--delete-links", action="store_true", help="Remove links")
grp_git.add_argument("-s", "--status", action="store_true", help="git status")
grp_git.add_argument("-u", "--update", action="store_true", help="Update repositories")
args = parser.parse_args()


class Link:
    # args is a string, e.g '-rT' => makes a relative link to a directory
    def __init__(self, src, dst, args=None):
        self._src, self._dst, self._args = src, dst, args

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

    def __post_init__(self):
        Path(f"{base}/{self.hub}").mkdir(parents=True, exist_ok=True)


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
    ),
    RepoData(
        "scripts",
        links=(
            Link("helpers.py", f"{env['HOME']}/.pyrc", "-r"),
            Link("backup.pl", f"{env['HOME']}/bin/b"),
            Link("ex.pl", f"{env['HOME']}/bin/ex"),
            Link("calc.pl", f"{env['HOME']}/bin/="),
            Link("cert.pl", f"{env['HOME']}/bin/cert"),
            Link("mkconfig.py", f"{env['HOME']}/bin/mkconfig"),
            Link("mini.pl", f"{env['HOME']}/bin/mini"),
            Link("pics.pl", f"{env['HOME']}/bin/pics"),
            Link("pc.pl", f"{env['HOME']}/bin/pc"),
            Link("rseverywhere.pl", f"{env['HOME']}/bin/rseverywhere"),
            Link("vpn.pl", f"{env['HOME']}/bin/vpn"),
            Link("www.py", f"{env['HOME']}/bin/www"),
            Link("colors_term.bash", f"{env['HOME']}/bin"),
            Link("colors_tmux.bash", f"{env['HOME']}/bin"),
        ),
    ),
    RepoData(
        "config",
        links=(
            Link("tmux/lay.pl", f"{env['HOME']}/bin/lay"),
            Link("tmux/Nodes.pm", f"{env['HOME']}/bin/nodes"),
            Link("dotfiles/.gitignore", f"{env['HOME']}", "-r"),
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

repos = (repo for repo in repos if repo.enabled)


# TODO: show progress bar with tqdm?
# for task in tqdm.as_completed(tasks, leave=False, ascii=' =', colour='green', ncols=139, desc='Updating repos...'):
def init():
    if platform == "darwin":
        # needed when 'ln' is actually 'gln'
        path = env["PATH"].split(":")
        path.insert(0, "/usr/local/opt/coreutils/libexec/gnubin")
        env["PATH"] = ":".join(path)

    print(
        Text("-").cyan,
        f"Cloning repositories in {Text(base.replace(env['HOME'], '~')).fg(69)}...",
    )
    asyncio.run(git_clone())  # TODO: wrap in a try except in case it fails

    print(Text("-").cyan, "Linking dot files")

    Path(f"{env['HOME']}/bin").mkdir(exist_ok=True)
    Path(f"{env['XDG_CONFIG_HOME']}/zsh").mkdir(exist_ok=True)
    Path(f"{env['XDG_DATA_HOME']}/zsh").mkdir(
        exist_ok=True
    )  # for zsh history. TODO: group mkdirs
    Path(f"{env['XDG_CONFIG_HOME']}/bat").mkdir(exist_ok=True)
    create_links()

    print(Text("-").cyan, "Configuring git")
    git_config()

    print(Text("-").cyan, "Generating tags")
    ctags()

    print(Text("-").cyan, "Creating fuzzy cd database")
    cd_db_create()

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


async def git_clone():
    if version_info[0] == 3 and version_info[1] >= 11:
        async with asyncio.TaskGroup() as tg:
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}", action="clone")
                tg.create_task(
                    repo.clone(
                        args.clone_dst or f"{base}/{r.hub}",
                        protocol=args.clone_protocol,
                        hub=r.hub,
                        verbose=args.verbose,
                    )
                )
    else:
        tasks = []
        for r in repos:
            repo = Repo(f"{base}/{r.hub}/{r.name}", action="clone")
            tasks.append(
                repo.clone(
                    args.clone_dst or f"{base}/{r.hub}",
                    protocol=args.clone_protocol,
                    hub=r.hub,
                    verbose=args.verbose,
                )
            )
        for task in asyncio.as_completed(tasks):
            await task


def create_links():
    for r in repos:
        repo = Repo(f"{base}/{r.hub}/{r.name}", r.links)
        p = Process(target=repo.create_links, args=(args.verbose,))
        p.start()
        p.join()


def remove_links():
    for repo in repos:
        for link in repo.links:
            p = Process(target=link.remove, args=(args.verbose,))
            p.start()
            p.join()


def git_config():
    cmd = ("bash", f"{base}/github/config/git.bash")

    if args.verbose:
        print(" ".join(cmd).replace(env["HOME"], "~"))

    run(cmd)


def ctags():
    cmd = [
        "ctags",
        "-R",
        f"-f {env['HOME']}/repos/tags",
        # "--langmap=zsh:+.",  # files without extension. TODO: fix! not fully working, e.g. net/dig: variable 'out' not found. (zsh/autoload/*) vs . doesn't help
        "--exclude=.*~",  # *~ excluded by default: ctags --list-excludes
        "--exclude=keymap",
        "--exclude=lazy-lock.json",  # lazy nvim
    ]

    cmd.extend(f"{base}/{repo.hub}/{repo.name}" for repo in repos if repo.name != "vim")

    Path(f"{env['XDG_CONFIG_HOME']}/zsh/after").mkdir(parents=True, exist_ok=True)
    cmd.append(f"{env['XDG_CONFIG_HOME']}/zsh/after")

    if Path(f"{env['XDG_CONFIG_HOME']}/zsh/.zshrc_after").is_file():
        cmd.append(f"{env['XDG_CONFIG_HOME']}/zsh/.zshrc_after")

    if args.verbose:
        pprint(cmd)
        print()
        print(
            " ".join(cmd)
            .replace(env["HOME"], "~")
            .replace(env["XDG_CONFIG_HOME"], "~/.config")
        )

    run(cmd)


def cd_db_create():
    script = f"{base}/github/scripts/db-create"
    cmd = ("bash", script)

    if args.verbose:
        print(" ".join(cmd).replace(env["HOME"], "~"))
        print()
        run(("bat", "--language=bash", script))

    run(cmd)


async def git_status():
    if version_info[0] == 3 and version_info[1] >= 11:
        async with asyncio.TaskGroup() as tg:
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}")
                tg.create_task(repo.status(args.verbose))
    else:
        tasks = []
        for r in repos:
            repo = Repo(f"{base}/{r.hub}/{r.name}")
            tasks.append(repo.status(args.verbose))
        for task in asyncio.as_completed(tasks):
            await task


# TODO: add -v/-q as needed
async def git_pull():
    if version_info[0] == 3 and version_info[1] >= 11:
        async with asyncio.TaskGroup() as tg:
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


if __name__ == "__main__":
    if args.ugrade_venv_packages:
        upgrade_venvs(msg="Upgrading pip modules...")

    if args.init:
        init()

    if args.clone:
        asyncio.run(git_clone())

    if args.links:
        create_links()

    if args.delete_links:
        remove_links()

    if args.git_config:
        git_config()

    if args.tags:
        ctags()

    if args.cd_db_create:
        cd_db_create()

    if args.status:
        asyncio.run(git_status())

    if len(argv) == 1 or args.update:  # no args or --update
        asyncio.run(git_pull())
