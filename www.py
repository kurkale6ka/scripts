#! /usr/bin/env python3

"""Fuzzy search/launch of websites bookmarked in a file"""

import argparse
import webbrowser as browser
from re import search
from os import environ as env
from subprocess import run, PIPE

sites = env['XDG_DATA_HOME'] + '/sites'
desc = f'Fuzzy search/launch of websites bookmarked in a file ({sites.replace(env["HOME"], "~")})'

# Arguments
parser = argparse.ArgumentParser(prog='www', description=desc)
parser.add_argument("pattern", nargs="?", type=str, help="site filter criteria")
args = parser.parse_args()

# Site selection
fzf = ['fzf', '-0', '-1', '--cycle', '--height', '60%'] # can't be a tuple because of -q
if args.pattern:
    fzf.extend(('-q', args.pattern))

try:
    with open(sites) as file:
        site = run(fzf, stdin=file, stdout=PIPE, text=True)
        site = site.stdout.rstrip()
except FileNotFoundError as err:
    exit('Add your bookmarks to: ' + err.filename.replace(env["HOME"], "~"))

match = search(r'https?://\S+', site) or \
        search(r'www\.\S+',     site) or \
        search(r'\S+\.com\b',   site)

if match:
    url = match.group()

    if not url.casefold().startswith('http'):
        url = "https://" + url

    print(url)
    browser.open(url)
else:
    error = f"No valid URL in: {site}" if site else 'No match'
    exit(error)
