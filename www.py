#! /usr/bin/env python3

"""Fuzzy search & open of websites loaded from a file"""

import re
import argparse
from sys import stderr as STDERR
from subprocess import run, PIPE
from os import execlp, environ as env

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

   site = site.stdout

match = re.match(r'https?://\S+', site) or \
      re.match(r'www\.\S+', site) or \
      re.search(r'\S+\.com\b', site)

if match:
   url = match.group()

   if not re.match('http', url, re.IGNORECASE):
      url = "https://" + url

   execlp('open', 'open', url)
else:
   error = f"No valid URL in: {site}" if site else 'No match'
   print(error, file=STDERR)
