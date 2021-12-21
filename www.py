#! /usr/bin/env python3

"""Fuzzy search & open of websites loaded from a file"""

import argparse
from subprocess import run
from os import environ as env

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--sites", type=str, help="file with your bookmarked sites")
parser.add_argument("pattern", nargs="?", type=str, help="site filter criteria")
args = parser.parse_args()

sites = env['XDG_DATA_HOME'] + '/sites'
fzf = ['fzf', '-0', '-1', '--cycle', '--height', '60%']

with open(sites) as file:
   if args.pattern:
      site = run(fzf + ['-q', args.pattern], stdin=file)
   else:
      site = run(fzf, stdin=file)

print(site)
