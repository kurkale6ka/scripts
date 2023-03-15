#! /usr/bin/env python3

"""Fuzzy File Explorer
"""

import argparse
from subprocess import run, Popen, PIPE

parser = argparse.ArgumentParser()
parser.add_argument(
    "-d", "--directory", type=str, nargs="?", help="change base directory"
)
parser.add_argument(
    "-g", "--grep", type=str, help="list files with matches"
)
parser.add_argument(
    "query", type=str, nargs="?", help="fzf query"
)
args = parser.parse_args()

fzf = ["fzf", "-0", "-1", "--cycle", "--print-query", "--expect=alt-v"]
fd = ["fd", "--strip-cwd-prefix", "-tf", "-up", "-E.git", "-E'*~'"]

if args.query:
    fzf.extend(("-q", args.query))

if args.directory:
    fd.extend(("--base-directory", args.directory))

if args.grep:
    rg = ("rg", "-S", "--hidden", "-l", args.grep)
    fzf.extend(('--preview', f"rg -FS --color=always '{args.grep}' {{}}"))
    p1 = Popen(rg, stdout=PIPE, text=True)
    p2 = Popen(fzf, stdin=p1.stdout, stdout=PIPE, text=True)
    p1.stdout.close()  # pyright: ignore reportOptionalMemberAccess
    out = p2.communicate()[0]

# p1 = Popen(fd, stdout=PIPE, text=True)
# p2 = Popen(fzf, stdin=p1.stdout, stdout=PIPE, text=True)
# p1.stdout.close()  # pyright: ignore reportOptionalMemberAccess
# out = p2.communicate()[0]

# --print-query, --expect, item
results = out.split()

run(('bat', results[-1]))
