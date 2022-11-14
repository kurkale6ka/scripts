#! /usr/bin/env python3

"""Manage your web bookmarks from the command line"""

import argparse
import webbrowser as browser
from re import search
from os import environ as env, execlp
from subprocess import run, PIPE

sites = env['XDG_DATA_HOME'] + '/sites'
desc = 'Manage your web bookmarks from the command line'

# Arguments
parser = argparse.ArgumentParser(prog='www', description=desc)
parser.add_argument("pattern", nargs="?", type=str, help="filter bookmarks using a fzf pattern\nhttps://github.com/junegunn/fzf#search-syntax")
parser.add_argument("-a", "--add", type=str, help="add bookmark (use quotes to preserve spaces)")
parser.add_argument("-e", "--edit", action="store_true", help="edit bookmarks")
args = parser.parse_args()

# Site selection
fzf = ['fzf', '-0', '-1', '--cycle', '--height', '60%'] # can't be a tuple because of -q
if args.pattern:
    fzf.extend(('-q', args.pattern))

# Write a bookmark
if args.add:
    with open(sites, 'a') as file:
        file.write(args.add + '\n')
        exit()

if args.edit:
    execlp('nvim', 'nvim', sites)

# Read a bookmark
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
