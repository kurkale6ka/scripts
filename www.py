#! /usr/bin/env python3

"""Fuzzy search & open of websites loaded from a file"""

import re
import argparse
from subprocess import run, Popen, PIPE
from os import execlp as exec, environ as env

sites = env['XDG_DATA_HOME'] + '/sites'

# Arguments
parser = argparse.ArgumentParser('www', description=f'fuzzy search & open of websites ({sites})')
parser.add_argument("-s", "--sites", type=str, help="file with your bookmarked sites")
parser.add_argument("pattern", nargs="?", type=str, help="site filter criteria")
args = parser.parse_args()

# Site selection
fzf = ['fzf', '-0', '-1', '--cycle', '--height', '60%']

with open(sites) as file:
   if args.pattern:
      site = run(fzf + ['-q', args.pattern], stdin=file, stdout=PIPE, text=True)
   else:
      site = run(fzf, stdin=file, stdout=PIPE, text=True)

pattern = re.compile('https?://\S+') # or
# re.compile('www\.\S+') or
# re.compile('\S+\.com\b')

url = pattern.findall(site.stdout) [0]

exec('open', 'open', url)
