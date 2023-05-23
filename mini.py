#! /usr/bin/env python3

"""Copy stuff
"""

import argparse
from subprocess import run, PIPE


parser = argparse.ArgumentParser()
parser.add_argument("tool", type=str, default="bash", help="get config(s) for tool")
args = parser.parse_args()


class MiniConfig:

    """TODO"""

    def __init__(self, tool, location=".", comments="#"):
        self._tool = tool
        self._location = location
        self._comments = comments


bash = [
    MiniConfig("readline", location="config/dotfiles/.inputrc.mini"),
    MiniConfig("bashrc", location="bash/.bashrc.mini"),
    MiniConfig("editor", location="vim/.vimrc.mini"),
]

ksh = dict(
    profile="config/ksh/.profile.mini",
    rc="config/ksh/.kshrc.mini",
    editor="vim/.vimrc.mini",
)

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
