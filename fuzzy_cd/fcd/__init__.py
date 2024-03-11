#! /usr/bin/env python3

"""
Fuzzy cd, using shell's history
"""

import argparse
import os
from os import environ as env
import re
from pathlib import Path, PurePath
from collections import Counter
import operator
from subprocess import run, PIPE
from tabulate import tabulate

File = str | os.PathLike


class CDPaths:
    def __init__(self, histfile: File) -> None:
        """Get 'cd' lines from the shell's history file

        Only interactive 'cd' usage is considered,
        'cd's within for loops or other commands are unchecked

        Set a list of paths
        Set history
        """
        with open(histfile) as file:
            paths = []
            history: list[dict] = []

            start = "(?:(?:builtin|command) +)?"
            dir_dash_re = re.compile(start + "cd +-\\d*")  # -num
            dir_dots_re = re.compile(start + "cd +[./]+")  # ../..
            cd_re = re.compile(start + "(cd .+)")

            for line in file:
                history.append({"value": line})

                entry = line.strip()

                # exclude:
                # cd -2, checking the regex 'should' be faster than checking if -num is a dir
                # cd ../..
                if dir_dash_re.fullmatch(entry) or dir_dots_re.fullmatch(entry):
                    continue

                match = cd_re.match(entry)
                if match:
                    cd = match.group(1)

                    # cd /path && echo 1 && echo 2
                    dir = cd.split("&&", 1)[0].split(None, 1)[1].rstrip()

                    # cd -- -hello--world
                    if dir.startswith("-- "):
                        dir = dir.split("--", 1)[1].lstrip()

                    # remove quote escaped or \ escaped white spaces
                    dir = dir.strip("'\"").replace("\\ ", " ")

                    # exclude:
                    # cd */.venv/*, .git, ...
                    if all(not d in PurePath(dir).parts for d in [".git", ".venv"]):
                        paths.append(dir)
                        # this entry is a 'cd ...' command, this will help with --cleanup
                        history[-1]["cdpath"] = dir

        self._paths: list[str] = paths
        self._history: list[dict] = history

    @property
    def history(self):
        return self._history

    @property
    def cds(self):
        return tabulate(
            [entry for entry in self._history if "cdpath" in entry],
            headers={"value": "History entry", "cdpath": "Extracted 'cd' path"},
            tablefmt="presto",
        )

    def get(self) -> list[tuple[str, int]]:
        """Returns a list of tuples: path, weight.

        paths are then ordered from the most visited down
        """
        paths: list[Path] = []

        for p in self._paths:
            path = Path(p).expanduser()
            if path.is_dir():
                if path.is_absolute():
                    paths.append(path)
                else:
                    # For relative paths, absolute() below resolves links,
                    # Path().cwd() does the same.
                    # Since I want to keep them, I use PWD!
                    paths.append(Path(env["PWD"]).joinpath(path))
            elif not path.is_absolute():
                h_path = Path.home().joinpath(path)
                if h_path.is_dir():
                    paths.append(h_path)

        return sorted(
            Counter(
                os.path.normpath(p.absolute()).replace(str(Path.home()), "~")
                for p in paths
                if p.resolve() != Path.home()
            ).items(),
            key=operator.itemgetter(1),
            reverse=True,
        )

    @property
    def stats(self) -> str:
        return tabulate(
            [(p, w) for (p, w) in self.get() if w > 1] + [("...", 1)],
            headers=["Location", "Weight"],
            colalign=("right", "left"),
        )


class CDPathsInvalid(CDPaths):
    def get(self) -> list[tuple[str, int]]:
        """Returns a list of tuples: ipath, occurences"""
        ipaths: list[str] = []

        for p in self._paths:
            path = Path(p).expanduser()
            if not path.is_dir() and path.is_absolute():
                ipaths.append(p)

        return sorted(Counter(ipaths).items(), key=operator.itemgetter(1), reverse=True)

    @property
    def stats(self) -> str:
        return tabulate(
            [(p, o) for (p, o) in self.get()],
            headers=["Invalid paths", "Occurences"],
            colalign=("right", "left"),
        )


def main() -> None:
    def validate_histfile(file: File) -> File:
        if Path(file).is_file():
            return file
        else:
            raise argparse.ArgumentTypeError(f"'{file}' does not exist")

    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--histfile",
        type=validate_histfile,
        help="shell's history file location",
        default=env.get("HISTFILE", env["XDG_DATA_HOME"] + "/zsh/history"),
    )
    parser.add_argument(
        "-s",
        "--stats",
        action="store_true",
        help="show locations with their weight (cd frequency)",
    )
    parser.add_argument(
        "-v",
        "--view-cds",
        action="store_true",
        help="view 'cd' entries in the history",
    )
    parser.add_argument(
        "-c", "--cleanup", action="store_true", help="clean invalid paths"
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
        print(CDPaths(args.histfile).stats)

    elif args.view_cds:
        print(CDPaths(args.histfile).cds)

    elif args.cleanup:
        cdpaths = CDPathsInvalid(args.histfile)

        ipaths = cdpaths.get()
        if ipaths:
            print(cdpaths.stats)
            try:
                if input("\nDelete from history (y/n)? ").lower() in ("y", "yes"):
                    lines: list[str] = []
                    invalid_paths = [ipath[0] for ipath in ipaths]

                    for entry in cdpaths.history:
                        if (
                            not "cdpath" in entry
                            or not entry["cdpath"] in invalid_paths
                        ):
                            lines.append(entry["value"])

                    if len(lines) == len(cdpaths.history) - len(invalid_paths):
                        with open(args.histfile, "w") as file:
                            file.writelines(lines)
                    else:
                        exit(f"error while writing {args.histfile}")
                else:
                    print("no")
            except KeyboardInterrupt:
                print()
                exit()
        else:
            print("nothing to cleanup")

    else:
        paths = "\n".join(path[0] for path in CDPaths(args.histfile).get())

        fzf = ["fzf", "-0", "-1", "--cycle", "--height", "60%"]
        if args.query:
            fzf.extend(("-q", args.query))

        proc = run(fzf, input=paths, stdout=PIPE, text=True)

        if proc.returncode == 0:
            dir = Path(proc.stdout.rstrip())

            # expanduser() is needed for cd -- "$dir" in the shell function to work
            print(dir.expanduser())

            # append to shell's history
            with open(args.histfile, "a") as file:
                dir = str(dir).replace(" ", "\\ ")
                if dir.startswith("-"):
                    file.write(f"cd -- {dir}\n")
                else:
                    file.write(f"cd {dir}\n")
        else:
            exit(proc.returncode)


if __name__ == "__main__":
    main()
