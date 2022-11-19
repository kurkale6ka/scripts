#! /usr/bin/env python3

'''Dot files setup'''

from os import environ as env
from os.path import basename
from multiprocessing import Pool
from subprocess import run
from colorama import Fore as fg, Style as st

class Repo:
    base = env['HOME']+'/github/'

    def __init__(self, path):
        self.path = path

    def name(self):
        return basename(self.path)

    def status(self):
        cmd = ('git', '-C', self.path, '-c', 'color.status=always', 'status', '-sb')
        st = run(cmd, capture_output=True, text=True)
        return st.stdout.rstrip()

repos = (
Repo(Repo.base+'bash'),
Repo(Repo.base+'config'),
Repo(Repo.base+'help'),
Repo(Repo.base+'scripts'),
Repo(Repo.base+'vim'),
Repo(Repo.base+'zsh')
)

def get_status(repo):
    return '{}{:>7}{}: {}'.format(fg.CYAN, repo.name(), fg.RESET, repo.status())

with Pool() as pool:
    for status in pool.imap(get_status, repos):
        print(status)
