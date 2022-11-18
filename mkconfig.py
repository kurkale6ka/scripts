#! /usr/bin/env python3

''''''

from os import environ as env
from multiprocessing import Pool
from subprocess import run

base = env['HOME']+'/github/'

class Repo(object):

    """"""

    def __init__(self, path):
        """"""
        self.path = path

    def status(self):

        st = ('git', '-C', self.path, '-c', 'color.status=always', 'status', '-sb')
        run(st)

        # tag_cmd = ('git', '-C', self.path, 'describe', '--tags', 'origin/main')
        # tag = run(tag_cmd, capture_output=True, text=True)
        # self.current = tag.stdout.rstrip().split('-')[0]

repos = (
Repo(base+'bash'),
Repo(base+'config'),
Repo(base+'help'),
Repo(base+'scripts'),
Repo(base+'vim'),
Repo(base+'zsh')
)

# def status(repo):
#     repo.status()
#     return repo

from time import perf_counter
start = perf_counter()

with Pool() as pool:
    for repo in repos:
        pool.apply_async(repo.status())

end = perf_counter()
print('Time elapsed:', end - start)
