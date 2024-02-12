#! /usr/bin/env python3

"""
Fuzzy cd
"""

import argparse
import os
from os import environ as env
from pathlib import Path


class CDPaths:
    def __init__(self, histfile):
        with open(histfile) as file:
            paths = []
            for line in file:
                cmd = line.strip()
                if cmd.startswith("cd "):
                    dir = cmd.split(None, 1)[1]
                    if all(not d in Path(dir).parts for d in [".git", ".venv"]):
                        paths.append(dir.replace("~", env["HOME"]))
        self._paths = paths

    def _mkdir(self):
        paths = []
        for p in self._paths:
            if Path(p).exists():
                paths.append(Path(p).resolve())
            elif Path(env["HOME"] + "/" + p).exists():
                paths.append(Path(env["HOME"] + "/" + p).exists())
            else:
                new_path = set(
                    Path(a + "/" + p)
                    for a in self._absolute_paths()
                    if Path(a + "/" + p).exists()
                )
                if new_path:
                    paths.append(new_path.pop())
        return paths

    def _absolute_paths(self):
        return [p for p in self._paths if Path(p).exists() and Path(p).is_absolute()]

    def get(self):
        return self._mkdir()


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

    print(cd_paths.get())
