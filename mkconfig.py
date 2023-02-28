#! /usr/bin/env python3

"""Dotfiles setup
--------------

run this script with:
python3 <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.py) -h

TODO:
ssh -T git@github.com to accept IP
migrate `scripts/db-create` to python

INSTALL:
- fd-find (Linux),        ln -s /bin/fdfind ~/bin/fd
- batcat  (debian),       ln -s /bin/batcat ~/bin/bat
- wslu    (Windows wsl2), open browser pages
"""

try:
    from git.repo import Repo as GitRepo
    from git.exc import GitCommandError
    from styles.styles import Text
except ModuleNotFoundError:
    from textwrap import dedent
    exit(dedent("""
        Missing modules! Install with:

        mkdir ~/py-envs
        python3 -mvenv ~/py-envs/python-modules
        source ~/py-envs/python-modules/bin/activate
        pip install --upgrade pip
        pip install --upgrade gitpython

        mkdir ~/repos/gitlab
        git -C ~/repos/gitlab clone git@gitlab.com:kurkale6ka/styles.git
    """).strip())
from dataclasses import dataclass
from os import environ as env
from sys import argv, stderr, platform
from pathlib import Path
from subprocess import run
from multiprocessing import Process
from pprint import pprint
import asyncio
import argparse

# TODO: it should be ~/repos. Fix and use for 'base'.
# NB: can't be commented out. REPOS_BASE is used in other parts (e.g. zsh)
if not "REPOS_BASE" in env:
    print(
        Text("exporting REPOS_BASE to").red, Text("~/repos/github").fg(69), file=stderr
    )
    env["REPOS_BASE"] = env["HOME"] + "/repos/github"
    Path(env["REPOS_BASE"]).mkdir(parents=True, exist_ok=True)

base = f"{env['HOME']}/repos"
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
    def __init__(self, root, links=()):
        self._links = links
        self._root = root
        self._name = Path(self._root).name
        self._repo = GitRepo(self._root)

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
            print(Text("").cyan, f"cloned {self._name}")

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
    RepoData("styles", hub="gitlab"),
    RepoData("vim-chess", enabled=False),
    RepoData("vim-desertEX", enabled=False),
    RepoData("vim-pairs", enabled=False),
)

repos = (repo for repo in repos if repo.enabled)


# TODO: show progress bar with tqdm?
# for task in tqdm.as_completed(tasks, leave=False, ascii=' =', colour='green', ncols=139, desc='Updating repos...'):
def init():
    print(
        Text("→").cyan,
        f"Cloning repositories in {Text(base.replace(env['HOME'], '~')).fg(69)}...",
    )
    git_clone()  # TODO: return code before continuing

    print(Text("→").cyan, "Linking dot files")

    Path(f"{env['HOME']}/bin").mkdir(exist_ok=True)
    Path(f"{env['XDG_CONFIG_HOME']}/zsh").mkdir(exist_ok=True)
    Path(f"{env['XDG_CONFIG_HOME']}/bat").mkdir(exist_ok=True)
    create_links()

    print(Text("→").cyan, "Configuring git")
    git_config()

    print(Text("→").cyan, "Generating tags")
    ctags()

    print(Text("→").cyan, "Creating fuzzy cd database")
    cd_db_create()

    # macOS
    if platform == "darwin":
        print(Text("→").cyan, "Installing Homebrew formulae...")
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

        # needed when 'ln' is actually 'gln'
        path = env["PATH"].split(":")
        path.insert(0, "/usr/local/opt/coreutils/libexec/gnubin")
        env["PATH"] = ":".join(path)


def git_clone():
    async def main():
        async with asyncio.TaskGroup() as tg:
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}")
                tg.create_task(
                    repo.clone(
                        args.clone_dst or f"{base}/{r.hub}",
                        protocol=args.clone_protocol,
                        hub=r.hub,
                        verbose=args.verbose,
                    )
                )

    asyncio.run(main())


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
        "--langmap=zsh:+.",  # files without extension. TODO: fix! not fully working, e.g. net/dig: variable 'out' not found. (zsh/autoload/*) vs . doesn't help
        "--exclude=.*~",  # *~ excluded by default: ctags --list-excludes
        "--exclude=keymap",
        "--exclude=lazy-lock.json",  # lazy nvim
        f"{env['XDG_CONFIG_HOME']}/zsh/.zshrc_after",
        f"{env['XDG_CONFIG_HOME']}/zsh/after",
    ]
    cmd.extend(f"{base}/{repo.hub}/{repo.name}" for repo in repos if repo.name != "vim")

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


def git_status():
    async def main():
        async with asyncio.TaskGroup() as tg:
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}")
                tg.create_task(repo.status(args.verbose))

    asyncio.run(main())


# TODO: add -v
def git_pull():
    async def main():
        async with asyncio.TaskGroup() as tg:
            for r in repos:
                repo = Repo(f"{base}/{r.hub}/{r.name}")
                tg.create_task(repo.update())

    asyncio.run(main())


if __name__ == "__main__":
    if args.init:
        init()

    if args.clone:
        git_clone()

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
        git_status()

    if len(argv) == 1 or args.update:  # no args or --update
        git_pull()
