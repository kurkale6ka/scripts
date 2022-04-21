#! /usr/bin/env python3

"""Fuzzy search & open of websites loaded from a file"""

import argparse
import re
import sys
import webbrowser as browser
from os import environ as env
from subprocess import run, PIPE

sites = env['XDG_DATA_HOME'] + '/sites'
desc = f'fuzzy search & open of websites ({sites.replace(env["HOME"], "~")})'

# Arguments
parser = argparse.ArgumentParser(prog='www', description=desc)
parser.add_argument("-s", "--sites", type=str, help="file with your bookmarked sites")
parser.add_argument("pattern", nargs="?", type=str, help="site filter criteria")
args = parser.parse_args()

# Site selection
fzf = ['fzf', '-0', '-1', '--cycle', '--height', '60%'] # can't be a tuple because of -q
if args.pattern:
   fzf.extend(('-q', args.pattern))

with open(sites) as file:
   site = run(fzf, stdin=file, stdout=PIPE, text=True)
   site = site.stdout.rstrip()

match = re.search(r'https?://\S+', site) or \
        re.search(r'www\.\S+',     site) or \
        re.search(r'\S+\.com\b',   site)

if match:
   url = match.group()

   if not url.casefold().startswith('http'):
      url = "https://" + url

   print(url)
   browser.open(url)
else:
   error = f"No valid URL in: {site}" if site else 'No match'
   print(error, file=sys.stderr)
