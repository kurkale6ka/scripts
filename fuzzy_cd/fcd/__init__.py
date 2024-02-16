#! /usr/bin/env python3

"""
Fuzzy cd, using shell's history
"""

import argparse
import os
from os import environ as env
import re
from pathlib import Path, PurePath
from collections import Counter
import operator
from subprocess import run, PIPE
from tabulate import tabulate

# TODO: check 'c' records a cd in history
# typing


class CDPaths:
    def __init__(self, histfile):
        """Get 'cd' lines from the shell's history file.
        Only interactive 'cd' usage is considered,
        'cd's within for loops or other commands are unchecked
        """
        with histfile as file:
            paths = []

            cd_re = re.compile("(?:(?:builtin|command) +)?(cd .+)")
            dir_dash_re = re.compile("-\\d*")  # -num
            dir_dots_re = re.compile("[./]+")  # ../..

            for line in file:
                match = cd_re.match(line.strip())
                if match:
                    cd = match.group(1)

                    # cd /path && echo 1 && echo 2
                    dir = cd.split("&&", 1)[0].split(None, 1)[1].rstrip()

                    # cd -- -hello--world
                    if dir.startswith("-- "):
                        dir = dir.split("--", 1)[1].lstrip()

                    # remove quote escaped or \ escaped white spaces
                    dir = dir.strip("'\"").replace("\\ ", " ")

                    # exclude:
                    # cd -2, checking the regex 'should' be faster than checking if -num is a dir
                    # cd ../..
                    # cd */.venv/*, .git, ...
                    if dir_dash_re.fullmatch(dir) or dir_dots_re.fullmatch(dir):
                        continue
                    else:
                        if all(not d in PurePath(dir).parts for d in [".git", ".venv"]):
                            paths.append(dir)
        self._paths = paths

    def get(self):
        """Returns a list of tuples: path, weight
        Paths are then ordered from the most visited down
        """
        paths = []
        for p in self._paths:
            path = Path(p).expanduser()
            if path.is_dir():
                # For relative paths, absolute() below resolves links,
                # Path().cwd() does the same.
                # Since I want to keep them, I use PWD!
                paths.append(Path(env["PWD"]).joinpath(path))
            else:
                h_path = Path.home().joinpath(path)
                if h_path.is_dir():
                    paths.append(h_path)
        return sorted(
            Counter(
                os.path.normpath(p.absolute()).replace(str(Path.home()), "~")
                for p in paths
                if p.resolve() != Path.home()
            ).items(),
            key=operator.itemgetter(1),
            reverse=True,
        )


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--histfile",
        type=argparse.FileType("r"),
        help="shell's history file location",
        default=env.get("HISTFILE", env["XDG_DATA_HOME"] + "/zsh/history"),
    )
    parser.add_argument(
        "-s",
        "--stats",
        action="store_true",
        help="show locations with their weight (cd frequency)",
    )
    parser.add_argument(
        "query",
        type=str,
        nargs="?",
        help="fzf query\nsearch syntax: https://github.com/junegunn/fzf#search-syntax",
    )
    args = parser.parse_args()

    # Start
    if args.stats:
        print(
            tabulate(
                [(p, w) for (p, w) in CDPaths(args.histfile).get() if w > 1]
                + [("...", 1)],
                headers=["location", "weight"],
                colalign=("right", "left"),
            )
        )
    else:
        paths = "\n".join(p[0] for p in CDPaths(args.histfile).get())

        fzf = ["fzf", "-0", "-1", "--cycle", "--height", "60%"]
        if args.query:
            fzf.extend(("-q", args.query))

        proc = run(fzf, input=paths, stdout=PIPE, text=True)

        if proc.returncode == 0:
            print(Path(proc.stdout.rstrip()).expanduser())
        else:
            exit(proc.returncode)


if __name__ == "__main__":
    main()
