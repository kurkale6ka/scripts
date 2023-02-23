#! /usr/bin/env python3

"""Dot files setup"""

from git import Repo
from git.exc import NoSuchPathError
from os import environ as env
from pathlib import Path
from subprocess import run
from multiprocessing import Process
import asyncio
from styles.styles import Text
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--init", action="store_true", help="Initial setup: WIP...")
parser.add_argument("-l", "--links", action="store_true", help="Make links")
parser.add_argument("-L", "--delete-links", action="store_true", help="Remove links")
parser.add_argument("-s", "--status", action="store_true", help="git status")
parser.add_argument("-p", "--pull", action="store_true", help="git pull")
parser.add_argument("-v", "--verbose", action="store_true")
args = parser.parse_args()

base = env["HOME"] + "/repos/github/"
repos = []


# TODO: move to the class
def set_repo(path):
    try:
        repos.append(Repo(base + path))
    except NoSuchPathError:
        pass


# TODO: move to the class
set_repo("bash")
set_repo("config")
set_repo("help")
set_repo("scripts")
set_repo("vim")
set_repo("vim/plugged/vim-blockinsert")
set_repo("vim/plugged/vim-chess")
set_repo("vim/plugged/vim-desertEX")
set_repo("vim/plugged/vim-pairs")
set_repo("vim/plugged/vim-swap")
set_repo("nvim")
# set_repo('vim-chess')
# set_repo('vim-desertEX')
# set_repo('vim-pairs')
set_repo("zsh")


async def fetch(repo):
    proc = await asyncio.create_subprocess_exec(
        "git", "-C", repo.git.working_dir, "fetch", "--prune", "-q"
    )
    code = await proc.wait()
    if code != 0:
        print(f"Error while fetching {Path(repo.git.working_dir).name}, code: {code}")


async def get_status(repo):
    # TODO: include stash info
    await fetch(repo)
    if (
        repo.is_dirty(untracked_files=True)
        or repo.active_branch.name not in ("main", "master")
        or repo.git.rev_list("--count", "HEAD...HEAD@{u}") != "0"
    ):
        print(
            f'{Text(Path(repo.git.working_dir).name).cyan}: {repo.git(c="color.status=always").status("-sb")}'
        )


def pull(repo):
    print(
        f'{Text(Path(repo.git.working_dir).name).cyan}: {repo.git(c="color.ui=always").pull()}'
    )


async def main():
    await asyncio.gather(*(get_status(repo) for repo in repos))


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

    def create_links(self, verbose=False):
        for link in self._links:
            if link.src:
                # prepend the repo root
                link.src = self._root + "/" + link.src
            else:
                link.src = self._root
            link.create(verbose)


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
        Link("mkconfig.pl", f"{Link.bin}/mkconfig"),
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

if __name__ == "__main__":
    if args.links:
        for name, links in repo_links.items():
            repo = MyRepo(base + name, links)
            p = Process(target=repo.create_links, args=(args.verbose,))
            p.start()
            p.join()

    if args.delete_links:
        for links in repo_links.values():
            for link in links:
                p = Process(target=link.remove, args=(args.verbose,))
                p.start()
                p.join()

    if args.status:
        asyncio.run(main())
