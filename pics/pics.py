#! /usr/bin/env python3

"""Organize images into a hierarchy of folders by reading their EXIF metadata

year/month/name_with_model
└─ month
"""

from subprocess import run
from os import environ as env
from pathlib import Path
from decorate import Text  # pyright: ignore reportMissingImports
import argparse

parser = argparse.ArgumentParser()
parser.add_argument(
    "-s", "--source", type=str, default=f"{env['HOME']}/Dropbox/Camera Uploads", help=""
)
parser.add_argument(
    "-d", "--destination", type=str, default=f"{env['HOME']}/Dropbox/pics", help=""
)
parser.add_argument("-n", "--dry-run", action="store_true", default=False, help="")
parser.add_argument("-v", "--verbose", action="count", default=0, help="")
args = parser.parse_args()


class Uploads:
    """TODO"""

    def __init__(self, src):
        self._src = src.rstrip("/")
        self._renames = ""

    def organize(self, test: bool = False, verbose: int = 0):
        """TODO"""

        quiet = ["-q", "-q"]  # messages, warnings
        if verbose == 1:
            quiet.pop()
        if verbose == 2:
            quiet.clear()

        name = "testname" if test else "filename"

        # ref. 'RENAMING EXAMPLES' in `man exiftool`
        cmd = [
            "exiftool",
            *quiet,
            "-if",  # dates match or a single one only set
            "not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)",
            "-d",  # date format
            f"{self._src}/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
            # the last valid -filename<$createdate supersedes the others
            f"-{name}<$datetimeoriginal.%le",
            f"-{name}<$datetimeoriginal ${{make;}}.%le",
            f"-{name}<$createdate.%le",
            f"-{name}<$createdate ${{make;}}.%le",
            self._src,
        ]

        try:
            result = run(cmd, capture_output=True, text=True)
        except FileNotFoundError:
            exit("exiftool missing")
        else:
            if result.returncode != 0:
                exit(Text(result.stderr.rstrip()).red)
            elif test:
                self._renames = result.stdout.rstrip()

    def has_renames(self) -> bool:
        return bool(self._renames)

    # file -> tree
    def get_rename_paths(self):
        paths = []
        for line in self._renames.split("\n"):
            if " --> " in line:
                file, tree = line.split(" --> ")
                file, tree = file.strip("'"), tree.strip("'")

                tree = tree.replace(f"{self._src}/", "")
                paths.append((file, tree))
        return paths

    # years
    def get_tree_roots(self):
        return set(Path(tree).parents[-2] for _, tree in self.get_rename_paths())

    def show_renames(self) -> None:
        print(Text("Organize camera shots into timestamped folders").green)
        print("----------------------------------------------")

        for file, tree in self.get_rename_paths():
            # TODO: raw - print(line)
            print(
                Path(file).name,
                Text("-->").dim,
                Text(f"{Path(tree).parent}/").dir + Path(tree).name,
            )

    def sync(self, dst):
        print(f"\nSyncing to {dst}...")
        months = (
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        )
        for root in self.get_tree_roots():
            print(root)


def main():
    uploads = Uploads(args.source)

    # Test run for a preview
    uploads.organize(test=True, verbose=args.verbose)

    # Real run
    if uploads.has_renames():
        uploads.show_renames()
        if not args.dry_run:
            uploads.organize(test=False, verbose=0)
            uploads.sync(args.destination)


if __name__ == "__main__":
    main()
