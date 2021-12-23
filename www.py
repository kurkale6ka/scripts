#! /usr/bin/env python3

"""Fuzzy search & open of websites loaded from a file"""

import re
import argparse
from subprocess import run, PIPE
from os import execlp as exec, environ as env

sites = env['XDG_DATA_HOME'] + '/sites'
desc = 'fuzzy search & open of websites ({})'.format(sites.replace(env['HOME'], '~'))

# Arguments
parser = argparse.ArgumentParser(prog='www', description=desc)
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

pattern  = re.compile(r'https?://\S+')
pattern1 = re.compile(r'www\.\S+')
pattern2 = re.compile(r'\S+\.com\b')

url = pattern.findall(site.stdout) or \
      pattern1.findall(site.stdout) or \
      pattern2.findall(site.stdout)

url = url[0]

if not re.match(r'\Ahttp', url, re.IGNORECASE):
   url = "https://" + url

exec('open', 'open', url)
