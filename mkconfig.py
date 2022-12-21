#! /usr/bin/env python3

'''Dot files setup'''

from git import Repo
from git.exc import NoSuchPathError
from os import environ as env
from os.path import basename
import asyncio
from colorama import Fore as fg, Style as st
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--init", action="store_true", help="Initial setup: WIP...")
parser.add_argument("-s", "--status", action="store_true", help="git status")
parser.add_argument("-p", "--pull", action="store_true", help="git pull")
args = parser.parse_args()

base = env['HOME']+'/github/'

repos = []
def set_repo(path):
    try:
        repos.append(Repo(base + path))
    except NoSuchPathError:
        pass

set_repo('bash')
set_repo('config')
set_repo('help')
set_repo('scripts')
set_repo('editor')
set_repo('editor/vim/plugged/vim-blockinsert')
set_repo('editor/vim/plugged/vim-chess')
set_repo('editor/vim/plugged/vim-desertEX')
set_repo('editor/vim/plugged/vim-pairs')
set_repo('editor/vim/plugged/vim-swap')
set_repo('zsh')

async def fetch(repo):
    proc = await asyncio.create_subprocess_exec('git', '-C', repo.git.working_dir, 'fetch', '--prune', '-q')
    code = await proc.wait()
    if code != 0:
        print(f'Error while fetching {basename(repo.git.working_dir)}, code: {code}')

async def get_status(repo):
    # TODO: include stash info
    await fetch(repo)
    if repo.is_dirty(untracked_files=True) or \
       repo.active_branch.name not in ('main', 'master') or \
       repo.git.rev_list('--count', 'HEAD...HEAD@{u}') != '0':
        print(f'{fg.CYAN}{basename(repo.git.working_dir)}{fg.RESET}: {repo.git(c="color.status=always").status("-sb")}')

def pull(repo):
    print(f'{fg.CYAN}{basename(repo.git.working_dir)}{fg.RESET}: {repo.git(c="color.ui=always").pull()}')

async def main():
    await asyncio.gather(*(get_status(repo) for repo in repos))

if args.status:
    asyncio.run(main())
