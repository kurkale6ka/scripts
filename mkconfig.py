#! /usr/bin/env python3

'''Dot files setup'''

from git import Repo
from os import environ as env
from os.path import basename
from multiprocessing import Pool
from colorama import Fore as fg, Style as st
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--init", action="store_true", help="Initial setup")
parser.add_argument("-s", "--status", action="store_true", help="git status")
parser.add_argument("-p", "--pull", action="store_true", help="git pull")
args = parser.parse_args()

base = env['HOME']+'/github/'

repos = (
Repo(base+'bash'),
Repo(base+'config'),
Repo(base+'help'),
Repo(base+'scripts'),
Repo(base+'vim'),
Repo(base+'vim/plugged/vim-blockinsert'),
Repo(base+'vim/plugged/vim-chess'),
Repo(base+'vim/plugged/vim-desertEX'),
Repo(base+'vim/plugged/vim-pairs'),
Repo(base+'vim/plugged/vim-swap'),
Repo(base+'zsh'),
)

def get_status(repo):
    repo.git.fetch('--prune', '-q')
    if repo.is_dirty(untracked_files=True) or \
       repo.active_branch.name not in ('main', 'master') or \
       repo.git.rev_list('--count', 'HEAD...HEAD@{u}') != '0':
        print(f'{fg.CYAN}{basename(repo.git.working_dir)}{fg.RESET}: {repo.git(c="color.status=always").status("-sb")}')

def pull(repo):
    print(f'{fg.CYAN}{basename(repo.git.working_dir)}{fg.RESET}: {repo.git(c="color.ui=always").pull()}')

with Pool() as pool:
    if args.status:
        for _ in pool.imap(get_status, repos): pass
    if args.pull:
        for _ in pool.imap(pull, repos): pass
