#! /usr/bin/env python3

"""
Fuzzy cd, using shell's history
"""

import argparse
import os
from os import environ as env
import re
from pathlib import Path
from collections import Counter
import operator
from subprocess import run, PIPE
from tabulate import tabulate


class CDPaths:
    def __init__(self, histfile):
        # TODO: typing
        """Get 'cd' lines from the shell's history file"""
        with histfile as file:
            paths = []
            for line in file:
                cmd = line.strip()
                if re.match("(?:(?:builtin|command) +)?cd ", cmd):
                    cmd = cmd.replace("builtin", "", 1).replace("command", "", 1)

                    # cd /path && echo hi
                    dir = cmd.split("&&")[0].split(None, 1)[1]

                    # cd -- -hello
                    if "-- " in dir:
                        dir = dir.split("--")[1]

                    # checking the regex should be faster than checking for Path existence
                    if re.fullmatch("-\\d*", dir) or re.fullmatch("[./]+", dir):
                        continue
                    else:
                        if all(not d in Path(dir).parts for d in [".git", ".venv"]):
                            paths.append(Path(dir.strip().replace("~", env["HOME"])))
        self._paths = paths

    def get(self):
        """Returns a list of tuples: path - weight
        Paths are then ordered from the most visited down
        """
        paths = []
        for p in self._paths:
            if p.is_dir():
                # if CWD includes a symlink, I'd like to keep it
                # without this, absolute() below won't show links
                paths.append(Path(env["PWD"]).joinpath(p))
            else:
                h_path = Path(env["HOME"]).joinpath(p)
                if h_path.is_dir():
                    paths.append(h_path)
        return sorted(
            Counter(
                os.path.normpath(p.absolute().as_posix()).replace(env["HOME"], "~")
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
        default=os.environ.get(
            "HISTFILE", os.environ["XDG_DATA_HOME"] + "/zsh/history"
        ),
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
            print(proc.stdout.rstrip().replace("~", env["HOME"]))
        else:
            exit(proc.returncode)


if __name__ == "__main__":
    main()
