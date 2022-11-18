#! /usr/bin/env python3

''''''

from os import environ as env
from os.path import basename
from multiprocessing import Pool
from subprocess import run

base = env['HOME']+'/github/'

class Repo(object):
    def __init__(self, path):
        self.path = path

    def name(self):
        return basename(self.path)

    def status(self):
        cmd = ('git', '-C', self.path, '-c', 'color.status=always', 'status', '-sb')
        st = run(cmd, capture_output=True, text=True)
        return st.stdout.rstrip()

repos = (
Repo(base+'bash'),
Repo(base+'config'),
Repo(base+'help'),
Repo(base+'scripts'),
Repo(base+'vim'),
Repo(base+'zsh')
)

def status(repo):
    return repo.name() + ' ' + repo.status()

with Pool() as pool:
    for status in pool.imap(status, repos):
        print(status)
