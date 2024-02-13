#! /usr/bin/env python3

"""
Fuzzy cd
"""

import argparse
import os
from os import environ as env
import re
from pathlib import Path
from collections import Counter
import operator
from subprocess import run, PIPE


class CDPaths:
    def __init__(self, histfile):
        # TODO: typing
        """Get 'cd' lines from the shell's history file"""
        with open(histfile) as file:
            paths = []
            for line in file:
                if line.strip().startswith("cd "):
                    # cd /path && echo hi
                    dir = line.split("&&")[0].split(None, 1)[1]

                    # cd -- -hello
                    if "-- " in dir:
                        dir = dir.split("--")[1]

                    # checking the regex should be faster than checking for Path existence
                    if not re.fullmatch("-\\d*", dir):
                        if all(not d in Path(dir).parts for d in [".git", ".venv"]):
                            paths.append(Path(dir.strip().replace("~", env["HOME"])))
        self._paths = paths

    def get(self):
        """Returns a list of tuples: path - weight"""
        paths = []
        for p in self._paths:
            if p.exists():
                paths.append(p)
            else:
                h_path = Path(env["HOME"]).joinpath(p)
                if h_path.exists():
                    paths.append(h_path)
        return sorted(
            Counter(
                os.path.normpath(p.absolute().as_posix()).replace(env["HOME"], "~")
                for p in paths
            ).items(),
            key=operator.itemgetter(1),
            reverse=True,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--histfile",
        type=str,  # TODO: ensure this is a valid path
        help="shell's history file location",
        default=os.environ.get(
            "HISTFILE", os.environ["XDG_DATA_HOME"] + "/zsh/history"
        ),
    )
    parser.add_argument("query", type=str, nargs="?", help="fzf query")
    args = parser.parse_args()

    paths = "\n".join(p[0] for p in CDPaths(args.histfile).get())

    fzf = ["fzf", "-0", "-1", "--cycle", "--height", "60%"]
    if args.query:
        fzf.extend(("-q", args.query))

    proc = run(fzf, input=paths, stdout=PIPE, text=True)

    if proc.returncode == 0:
        print(proc.stdout.rstrip().replace("~", env["HOME"]))
    else:
        exit(proc.returncode)
