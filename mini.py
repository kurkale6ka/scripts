#! /usr/bin/env python3

"""Copy stuff
"""

import argparse
from dataclasses import dataclass
from os import PathLike
from pathlib import Path
from subprocess import run, PIPE


parser = argparse.ArgumentParser()
parser.add_argument("tool", type=str, default="bash", help="get config(s) for tool")
args = parser.parse_args()


@dataclass
class MiniConfig:
    name: str
    location: PathLike = Path(".")
    comments: str = "#"


configs = {
    "readline": MiniConfig("inputrc", location=Path("config/dotfiles/.inputrc.mini")),
    "bash": MiniConfig("bashrc", location=Path("bash/.bashrc.mini")),
    "editor": MiniConfig("vimrc", location=Path("vim/.vimrc.mini")),
    "ksh_profile": MiniConfig("profile", location=Path("config/ksh/.profile.mini")),
    "ksh": MiniConfig("kshrc", location=Path("config/ksh/.kshrc.mini")),
}

bash = [
    configs["readline"],
    configs["bash"],
    configs["editor"],
]

ksh = [
    configs["ksh_profile"],
    configs["ksh"],
    configs["editor"],
]

if __name__ == "__main__":
    if args.tool in ("bash", "ksh"):
        # config = args.tool
        pass
    else:
        filter = ("fzf", "-q", args.tool, "-0", "-1", "--cycle")
        config = run(filter, input="\n".join(configs.keys()), stdout=PIPE, text=True)
        if config.returncode == 130:
            exit("canceled")
        else:
            config = config.stdout.rstrip()
        print(config)
