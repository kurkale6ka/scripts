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


class CDPaths:
    def __init__(self, histfile):
        with open(histfile) as file:
            paths = []
            for line in file:
                if line.lstrip().startswith("cd "):
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
        paths = []
        for p in self._paths:
            if p.exists():
                paths.append(p)
            else:
                h_path = Path(env["HOME"]).joinpath(p)
                if h_path.exists():
                    paths.append(h_path)
                # too slow
                # else:
                #     for a in self._absolute_paths():
                #         a_path = Path(a).joinpath(p)
                #         if a_path.exists():
                #             paths.append(a_path)
                #             break
        return sorted(
            Counter(p.resolve().as_posix() for p in paths).items(),
            key=operator.itemgetter(1),
            reverse=True,
        )

    # def _absolute_paths(self):
    #     return [p for p in self._paths if p.is_absolute()]


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--histfile",
        type=str,
        help="",
        default=os.environ.get(
            "HISTFILE", os.environ["XDG_DATA_HOME"] + "/zsh/history"
        ),
    )
    args = parser.parse_args()

    cd_paths = CDPaths(args.histfile)

    # print(cd_paths.get())
    for p in cd_paths.get():
        print(p[0])
