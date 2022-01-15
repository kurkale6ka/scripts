#! /usr/bin/env python3

"""Fuzzy search & open of websites loaded from a file"""

import argparse
import re
import sys
from os import execlp, environ as env
from subprocess import run, PIPE

sites = env['XDG_DATA_HOME'] + '/sites'
desc = f'fuzzy search & open of websites ({sites.replace(env["HOME"], "~")})'

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

   site = site.stdout.rstrip('\n')

match = re.match(r'https?://\S+', site) or \
      re.match(r'www\.\S+', site) or \
      re.search(r'\S+\.com\b', site)

if match:
   url = match.group()

   if not url.casefold().startswith('http'):
      url = "https://" + url

   print(site)
   if sys.platform == 'darwin':
      execlp('open', 'open', url)
   else:
      execlp('xdg-open', 'open', url)
else:
   error = f"No valid URL in: {site}" if site else 'No match'
   print(error, file=sys.stderr)
