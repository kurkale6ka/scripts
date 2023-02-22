#! /usr/bin/env python3

"""Dot files setup"""

from git import Repo
from git.exc import NoSuchPathError
from os import environ as env
from os.path import basename
from subprocess import run
from multiprocessing import Process
import asyncio
from styles.styles import Text
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--init", action="store_true", help="Initial setup: WIP...")
parser.add_argument("-l", "--links", action="store_true", help="Make links")
parser.add_argument("-s", "--status", action="store_true", help="git status")
parser.add_argument("-p", "--pull", action="store_true", help="git pull")
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
        print(f"Error while fetching {basename(repo.git.working_dir)}, code: {code}")


async def get_status(repo):
    # TODO: include stash info
    await fetch(repo)
    if (
        repo.is_dirty(untracked_files=True)
        or repo.active_branch.name not in ("main", "master")
        or repo.git.rev_list("--count", "HEAD...HEAD@{u}") != "0"
    ):
        print(
            f'{Text(basename(repo.git.working_dir)).cyan}: {repo.git(c="color.status=always").status("-sb")}'
        )


def pull(repo):
    print(
        f'{Text(basename(repo.git.working_dir)).cyan}: {repo.git(c="color.ui=always").pull()}'
    )


async def main():
    await asyncio.gather(*(get_status(repo) for repo in repos))


class Link:
    # args is a string, e.g '-rT' => makes a relative link to a directory
    def __init__(self, src, dst, args=None):
        self.src, self.dst, self.args = src, dst, args


class MyRepo:
    bin = env["HOME"] + "/bin"

    def __init__(self, root, links=()):
        self._links = links
        self._root = root

    # TODO: move to class Link
    def _link(self, src, dst, args):
        cmd = ["ln", "-sf"]
        if args:
            cmd.append(args)  # extra ln args
        cmd.append(self._root.rstrip("/") + "/" + src)
        cmd.append(dst)
        p = Process(target=run, args=(cmd,))
        p.start()
        p.join()

    def create_links(self):
        for link in self._links:
            self._link(link.src, link.dst, link.args)


links = {
    # TODO: fix nvim, vim links
    "nvim": (Link("nvim", f"{env['XDG_CONFIG_HOME']}/nvim", "-T"),),
    "vim": (
        Link("vim", f"{env['HOME']}/.vim", "-rT"),
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
        Link("backup.pl", f"{MyRepo.bin}/b"),
        Link("ex.pl", f"{MyRepo.bin}/ex"),
        Link("calc.pl", f"{MyRepo.bin}/="),
        Link("cert.pl", f"{MyRepo.bin}/cert"),
        Link("mkconfig.pl", f"{MyRepo.bin}/mkconfig"),
        Link("mini.pl", f"{MyRepo.bin}/mini"),
        Link("pics.pl", f"{MyRepo.bin}/pics"),
        Link("pc.pl", f"{MyRepo.bin}/pc"),
        Link("rseverywhere.pl", f"{MyRepo.bin}/rseverywhere"),
        Link("vpn.pl", f"{MyRepo.bin}/vpn"),
        Link("www.py", f"{MyRepo.bin}/www"),
        Link("colors_term.bash", f"{MyRepo.bin}"),
        Link("colors_tmux.bash", f"{MyRepo.bin}"),
    ),
    "config": (
        Link("tmux/lay.pl", f"{MyRepo.bin}/lay"),
        Link("tmux/Nodes.pm", f"{MyRepo.bin}/nodes"),
        Link("dotfiles/.gitignore", f"{env['HOME']}", "-r"),
        Link("dotfiles/.irbrc", f"{env['HOME']}", "-r"),
        Link("dotfiles/.Xresources", f"{env['HOME']}", "-r"),
        Link("ctags/.ctags", f"{env['HOME']}", "-r"),
        Link("tmux/.tmux.conf", f"{env['HOME']}", "-r"),
    ),
}

# TODO: process in parallel
if args.links:
    nvim = MyRepo(base + "nvim", links["nvim"])
    nvim.create_links()
    vim = MyRepo(base + "vim", links["vim"])
    vim.create_links()
    zsh = MyRepo(base + "zsh", links["zsh"])
    zsh.create_links()
    bash = MyRepo(base + "bash", links["bash"])
    bash.create_links()
    scripts = MyRepo(base + "scripts", links["scripts"])
    scripts.create_links()
    config = MyRepo(base + "config", links["config"])
    config.create_links()

if args.status:
    asyncio.run(main())
