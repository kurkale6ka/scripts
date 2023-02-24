#! /usr/bin/env python3

"""Dot files setup"""

from git.repo import Repo
from git.exc import NoSuchPathError, GitCommandError
from os import environ as env
from sys import argv
from pathlib import Path
from subprocess import run
from multiprocessing import Process
from pprint import pprint
import asyncio
import argparse

# from tqdm.asyncio import tqdm
from styles.styles import Text

base = env["HOME"] + "/repos/github/"

# TODO: snippet start perf / end perf ???
# TODO: prog, desc, ...
parser = argparse.ArgumentParser()
links_grp = parser.add_mutually_exclusive_group()
git_grp = parser.add_mutually_exclusive_group()
parser.add_argument("-i", "--init", action="store_true", help="Initial setup: WIP...")
parser.add_argument("-g", "--git-config", action="store_true", help="git config")
parser.add_argument("-t", "--tags", action="store_true", help="Generate tags")
parser.add_argument("-v", "--verbose", action="store_true")
links_grp.add_argument("-l", "--links", action="store_true", help="Make links")
links_grp.add_argument("-L", "--delete-links", action="store_true", help="Remove links")
git_grp.add_argument("-s", "--status", action="store_true", help="git status")
git_grp.add_argument("-u", "--update", action="store_true", help="Update repositories")
args = parser.parse_args()


class Link:
    bin = env["HOME"] + "/bin"

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


class MyRepo:
    def __init__(self, root, links=()):
        self._links = links
        self._root = root
        try:
            self._repo = Repo(self._root)  # git repo wrapper
        except NoSuchPathError:
            pass

    def create_links(self, verbose=False):
        for link in self._links:
            if link.src:
                # prepend the repo root
                link.src = self._root + "/" + link.src
            else:
                link.src = self._root
            link.create(verbose)

    async def fetch(self):
        proc = await asyncio.create_subprocess_exec(
            "git", "-C", self._repo.git.working_dir, "fetch", "--prune", "-q"
        )
        code = await proc.wait()
        if code != 0:
            print(
                f"Error while fetching {Path(self._repo.git.working_dir).name}, code: {code}"
            )

    async def status(self):
        # TODO: include stash info
        await self.fetch()
        if (
            self._repo.is_dirty(untracked_files=True)
            or self._repo.active_branch.name not in ("main", "master")
            or self._repo.git.rev_list("--count", "HEAD...HEAD@{u}") != "0"
        ):
            print(
                Text(Path(self._repo.git.working_dir).name).cyan + ":",
                self._repo.git(c="color.status=always").status("-sb"),
            )

    async def update(self):
        try:
            print(
                Text(Path(self._repo.git.working_dir).name).cyan + ":",
                self._repo.git(c="color.ui=always").pull("--prune"),
            )
        except GitCommandError as err:
            print(
                Text(Path(self._repo.git.working_dir).name).cyan + ":",
                Text(err.stderr.lstrip().replace("\n", "\n\t")).red,
            )


repo_links = {
    "nvim": (Link(None, f"{env['XDG_CONFIG_HOME']}/nvim", "-T"),),
    "vim": (
        Link(None, f"{env['HOME']}/.vim", "-rT"),
        Link(".vimrc", f"{env['HOME']}", "-r"),
        Link(".gvimrc", f"{env['HOME']}", "-r"),
    ),
    "zsh": (
        Link(".zshenv", f"{env['HOME']}", "-r"),
        Link(".zprofile", f"{env['XDG_CONFIG_HOME']}/zsh"),
        Link(".zshrc", f"{env['XDG_CONFIG_HOME']}/zsh"),
        Link("autoload", f"{env['XDG_CONFIG_HOME']}/zsh"),
    ),
    "bash": (
        Link(".bash_profile", f"{env['HOME']}", "-r"),
        Link(".bashrc", f"{env['HOME']}", "-r"),
        Link(".bash_logout", f"{env['HOME']}", "-r"),
    ),
    "scripts": (
        Link("helpers.py", f"{env['HOME']}/.pyrc", "-r"),
        Link("backup.pl", f"{Link.bin}/b"),
        Link("ex.pl", f"{Link.bin}/ex"),
        Link("calc.pl", f"{Link.bin}/="),
        Link("cert.pl", f"{Link.bin}/cert"),
        Link("mkconfig.py", f"{Link.bin}/mkconfig"),
        Link("mini.pl", f"{Link.bin}/mini"),
        Link("pics.pl", f"{Link.bin}/pics"),
        Link("pc.pl", f"{Link.bin}/pc"),
        Link("rseverywhere.pl", f"{Link.bin}/rseverywhere"),
        Link("vpn.pl", f"{Link.bin}/vpn"),
        Link("www.py", f"{Link.bin}/www"),
        Link("colors_term.bash", f"{Link.bin}"),
        Link("colors_tmux.bash", f"{Link.bin}"),
    ),
    "config": (
        Link("tmux/lay.pl", f"{Link.bin}/lay"),
        Link("tmux/Nodes.pm", f"{Link.bin}/nodes"),
        Link("dotfiles/.gitignore", f"{env['HOME']}", "-r"),
        Link("dotfiles/.irbrc", f"{env['HOME']}", "-r"),
        Link("dotfiles/.Xresources", f"{env['HOME']}", "-r"),
        Link("ctags/.ctags", f"{env['HOME']}", "-r"),
        Link("tmux/.tmux.conf", f"{env['HOME']}", "-r"),
    ),
}


def create_links():
    for name, links in repo_links.items():
        repo = MyRepo(base + name, links)
        p = Process(target=repo.create_links, args=(args.verbose,))
        p.start()
        p.join()


def remove_links():
    for links in repo_links.values():
        for link in links:
            p = Process(target=link.remove, args=(args.verbose,))
            p.start()
            p.join()


def git_config():
    cmd = ("bash", f"{base}config/git.bash")

    if args.verbose:
        print(" ".join(cmd).replace(env["HOME"], "~"))

    run(cmd)


def git_status():
    async def main():
        async with asyncio.TaskGroup() as tg:
            # TODO:
            # set_repo("vim/plugged/vim-blockinsert")
            # set_repo("vim/plugged/vim-chess")
            # set_repo("vim/plugged/vim-desertEX")
            # set_repo("vim/plugged/vim-pairs")
            # set_repo("vim/plugged/vim-swap")
            # set_repo('vim-chess')
            # set_repo('vim-desertEX')
            # set_repo('vim-pairs')
            for name in repo_links.keys():
                repo = MyRepo(base + name, ())
                tg.create_task(repo.status())

    asyncio.run(main())


def git_pull():
    async def main():
        async with asyncio.TaskGroup() as tg:
            # TODO:
            # with tqdm(total=len(repo_links)) as pbar:
            # pbar.leave(True)
            # pbar.set_description('Updating repos...')
            # (leave=False, ascii=' =', colour='green', ncols=139, desc='Updating repos...'):
            for name in repo_links.keys():
                repo = MyRepo(base + name, ())
                tg.create_task(repo.update())
                # pbar.update(1)

    asyncio.run(main())


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
    cmd.extend(base + name for name in repo_links.keys() if name != "vim")

    if args.verbose:
        pprint(cmd)
        print()
        print(
            " ".join(cmd)
            .replace(env["HOME"], "~")
            .replace(env["XDG_CONFIG_HOME"], "~/.config")
        )

    run(cmd)


if __name__ == "__main__":
    if args.links:
        create_links()

    if args.delete_links:
        remove_links()

    if args.git_config:
        git_config()

    if args.status:
        git_status()

    if len(argv) == 1 or args.update:  # no args or --update
        git_pull()

    if args.tags:
        ctags()
