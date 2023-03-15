#! /usr/bin/env python3

"""Fuzzy File Explorer
"""

import argparse
from subprocess import Popen, PIPE

parser = argparse.ArgumentParser()
parser.add_argument(
    "-d", "--directory", type=str, nargs="?", help="change base directory"
)
parser.add_argument(
    "-g", "--grep", type=str, help="search for pattern in files content"
)
parser.add_argument(
    "pattern", type=str, nargs="?", help="search for pattern in files names"
)
args = parser.parse_args()

fzf = ["fzf", "-0", "-1", "--cycle", "--print-query", "--expect=alt-v"]
fd = ["fd", "--strip-cwd-prefix", "-tf", "-up", "-E.git", "-E'*~'"]

if args.pattern:
    fzf.extend(("-q", args.pattern))

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

print(results[-1])
