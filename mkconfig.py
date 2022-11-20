#! /usr/bin/env python3

'''Dot files setup'''

from git import Repo
from os import environ as env
from os.path import basename
from multiprocessing import Pool
from colorama import Fore as fg, Style as st

base = env['HOME']+'/github/'

repos = (
Repo(base+'bash'),
Repo(base+'config'),
Repo(base+'help'),
Repo(base+'scripts'),
Repo(base+'vim'),
Repo(base+'zsh')
)

def get_status(repo):
    # return '{}{:>7}{}: {}'.format(fg.CYAN, repo.name(), fg.RESET, repo.status('-sb'))
    if repo.is_dirty():
        return basename(repo.git.working_dir) + repo.git.status('-sb')

with Pool() as pool:
    for status in pool.imap(get_status, repos):
        print(status)
