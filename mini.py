#! /usr/bin/env python3

"""Copy mini configs for pasting on remote systems

- inputrc
- Bash/Korn rcs
- vimrc
"""

from argparse import ArgumentParser, RawTextHelpFormatter
from dataclasses import dataclass
from os import PathLike
from pathlib import Path
from subprocess import run, PIPE


parser = ArgumentParser(description=__doc__, formatter_class=RawTextHelpFormatter)
parser.add_argument("-a", "--all", action="store_true", help="choose from all configs")
parser.add_argument(
    "tool", type=str, default="bash", nargs="?", help="get config(s) for tool"
)
args = parser.parse_args()


@dataclass
class MiniConfig:
    name: str
    info: str = ""
    path: PathLike = Path(".")
    comments: str = "#"


inputrc = MiniConfig(
    "inputrc", info="readline", path=Path("config/dotfiles/.inputrc.mini")
)
bashrc = MiniConfig("bashrc", path=Path("bash/.bashrc.mini"))
vimrc = MiniConfig("vimrc", path=Path("vim/.vimrc.mini"))
profile = MiniConfig(
    "profile", info="ksh profile", path=Path("config/ksh/.profile.mini")
)
kshrc = MiniConfig("kshrc", path=Path("config/ksh/.kshrc.mini"))

mini_configs = {
    inputrc.name: inputrc,
    bashrc.name: bashrc,
    vimrc.name: vimrc,
    profile.name: profile,
    kshrc.name: kshrc,
}

if __name__ == "__main__":
    filter = ("fzf", "-q", args.tool, "-0", "-1", "--cycle")
    if args.all:
        filter = ("fzf", "--cycle")

    if not args.all and args.tool in ("bash", "ksh"):  # TODO: use regex?
        if args.tool == "bash":
            print(mini_configs[inputrc.name].path)
            print(mini_configs[bashrc.name].path)
            print(mini_configs[vimrc.name].path)
        else:
            print(mini_configs[profile.name].path)
            print(mini_configs[kshrc.name].path)
            print(mini_configs[vimrc.name].path)
    else:
        configs = "\n".join(
            f"{cfg.name}: {cfg.info}" if cfg.info else cfg.name
            for cfg in mini_configs.values()
        )
        config = run(filter, input=configs, stdout=PIPE, text=True)
        if config.returncode == 130:
            exit("canceled")
        else:
            config = config.stdout.rstrip()
            config = config.split(":")[0]
        print(mini_configs[config].path)
