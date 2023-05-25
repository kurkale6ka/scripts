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
from os import environ as env


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

    # prepend base
    def __post_init__(self):
        self.path = Path(f"{env['REPOS_BASE']}/github/{self.path}")


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
            # cat config
            with open(inputrc.path) as f_inputrc, open(bashrc.path) as f_bashrc, open(
                vimrc.path
            ) as f_vimrc:
                print("cat >> ~/.inputrc << 'INPUTRC'")
                print(inputrc.comments, "-" * 78)
                print(f_inputrc.read().rstrip())
                print("INPUTRC")
        else:
            print(profile.path)
            print(kshrc.path)
            print(vimrc.path)
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

        # cat config
        with open(mini_configs[config].path) as conf:
            print(conf.read().rstrip())
