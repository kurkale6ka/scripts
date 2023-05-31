#! /usr/bin/env python3

"""Copy mini configs for pasting on remote systems

- bash: inputrc/bashrc/vimrc
-  ksh: profile/kshrc/vimrc
"""

from argparse import ArgumentParser, RawTextHelpFormatter
from dataclasses import dataclass
from os import PathLike
from pathlib import Path
from subprocess import run, PIPE
from os import environ as env
import platform

parser = ArgumentParser(description=__doc__, formatter_class=RawTextHelpFormatter)
parser.add_argument("-a", "--all", action="store_true", help="choose from all configs")
parser.add_argument(
    "config",
    type=str,
    default="bash",
    nargs="?",
    help="get config(s), fuzzy pattern allowed\ndefault: bash (inputrc/bashrc/vimrc)\nspecial: ksh (profile/kshrc/vimrc)",
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

    def get(self):
        with open(self.path) as config:
            out = f"cat >> ~/.{self.name} << '{self.name.upper()}'\n"
            out += f"{self.comments} {'-' * 78}\n"
            out += config.read()
            out += self.name.upper()
        return out


inputrc = MiniConfig(
    "inputrc", info="readline", path=Path("config/dotfiles/.inputrc.mini")
)
bashrc = MiniConfig("bashrc", path=Path("bash/.bashrc.mini"))
vimrc = MiniConfig("vimrc", path=Path("vim/.vimrc.mini"), comments='"')
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
    if "microsoft-standard" in platform.release():  # WSL2
        cb_tool = "clip.exe"
    elif platform.system() == "Linux":
        cb_tool = "xclip"
    else:
        cb_tool = "pbcopy"  # Darwin

    filter = ("fzf", "-q", args.config, "-0", "-1", "--cycle")
    if args.all:
        filter = ("fzf", "--cycle")

    if not args.all and args.config in ("bash", "ksh"):  # TODO: use regex?
        if args.config == "bash":
            mini_config = inputrc.get() + "\n\n" + bashrc.get() + "\n\n" + vimrc.get()
        else:
            mini_config = profile.get() + "\n\n" + kshrc.get() + "\n\n" + vimrc.get()
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

        mini_config = mini_configs[config].get()

    run(cb_tool, input=mini_config, text=True)
