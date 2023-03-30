#! /usr/bin/env python3

"""Organize files into a hierarchy of folders by reading their EXIF metadata

filename -> year
            └─ month
               └─ filename_[camera-model]

I mostly use this script to sort my Dropbox Camera Uploads
"""

from subprocess import run
from os import environ as env, rmdir
from pathlib import Path
from decorate import Text  # pyright: ignore reportMissingImports
import argparse

parser = argparse.ArgumentParser(description="Organize your files into years/months")
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

    def organize(self, test: bool = False, verbose: int = 0) -> None:
        """Organize source files into years/months

        exiftool will do the renaming (ref. 'RENAMING EXAMPLES' in `man exiftool`)
        """

        quiet = ["-q", "-q"]  # messages, warnings
        if verbose == 1:
            quiet.pop()
        if verbose == 2:
            quiet.clear()

        name = "testname" if test else "filename"

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
            elif result.stdout.rstrip():
                self._renames = result.stdout.rstrip()

    def has_renames(self) -> bool:
        return bool(self._renames)

    # file -> tree
    def _get_rename_paths(self, relative=False) -> list[str]:
        paths = []
        for line in self._renames.split("\n"):
            if " --> " in line:
                file, tree = line.split(" --> ")
                file, tree = file.strip("'"), tree.strip("'")

                if relative:
                    tree = tree.replace(f"{self._src}/", "")  # remove /path/to/source

                paths.append((file, tree))
        return paths

    # TODO: store as data? serialize in order to import to lib?
    def _get_rename(self, kind: str) -> set[str]:
        if kind == "years":
            return set(
                str(Path(tree).parents[1]) for _, tree in self._get_rename_paths()
            )
        else:
            return set(
                str(Path(tree).parents[0]) for _, tree in self._get_rename_paths()
            )

    def show_renames(self) -> None:
        print(Text("Organize camera shots into timestamped folders").green)
        print("----------------------------------------------")

        for file, tree in self._get_rename_paths(relative=True):
            # TODO: add raw print option?
            print(
                Path(file).name,
                Text("-->").dim,
                Text(f"{Path(tree).parent}/").dir + Path(tree).name,
            )

    def move(self, dst):
        """Move new trees"""

        print(f"\nmoving pictures to {dst.replace(env['HOME'], '~')}...\n")

        def build_cmd(preview: bool = False) -> list[str]:
            return [
                "rsync",
                "--remove-source-files",
                "--partial",
                "-ain" if preview else "-a",
                *self._get_rename("years"),
                dst,
            ]

        print("changeset:")
        sync = run(build_cmd(preview=True))  # preview: list images being moved
        if sync.returncode == 0:
            # TODO: restart an old move
            # $ pics 2017 2023 -> this would only run move()?
            # or regex match years?
            # or do some jsondump/load?
            answer = input("proceed (y/n)? ")
            if answer == "y":
                print()
                sync = run(build_cmd())  # move images
                if sync.returncode == 0:
                    # delete source years + months after a successful transfer
                    print("cleanup")
                    for month in self._get_rename("months"):
                        rmdir(month)
                    for year in self._get_rename("years"):
                        rmdir(year)


def main():
    uploads = Uploads(args.source)

    # Test run for a preview
    uploads.organize(test=True, verbose=args.verbose)

    # Real run
    if uploads.has_renames():
        uploads.show_renames()
        if not args.dry_run:
            uploads.organize(test=False, verbose=0)
            uploads.move(args.destination)


if __name__ == "__main__":
    main()
