#! /usr/bin/env python3

"""
Fuzzy cd
"""

import os
from pathlib import Path

HOME = os.environ["HOME"]


class CDPaths:
    def get(self):
        with open(
            os.environ.get("HISTFILE", os.environ["XDG_DATA_HOME"] + "/zsh/history"),
            'r',
            encoding="utf-8",
        ) as file:
            paths = []
            for line in file:
                cmd = line.strip()
                if cmd.startswith("cd "):
                    dir = cmd.split(None, 1)[1].replace("~", HOME)
                    if Path(dir).exists():
                        paths.append(dir.replace(HOME, "~"))
            return paths


if __name__ == "__main__":
    cd_paths = CDPaths()
    print(cd_paths.get())
