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
parser.add_argument("-n", "--dry-run", action="store_true", default=False, help="")
parser.add_argument("-v", "--verbose", action="count", default=0, help="")
args = parser.parse_args()


class Uploads:
    """TODO"""

    def __init__(self, src):
        self._src = src.rstrip("/")

    def organize(self, test: bool = False, verbose: int = 0):
        """TODO"""

        quiet = ["-q", "-q"]  # messages, warnings
        if verbose == 1:
            quiet.pop()
        if verbose == 2:
            quiet.clear()

        name = "testname" if test else "filename"

        # ref. 'RENAMING EXAMPLES' in 'man exiftool'
        cmd = [
            "exiftool",
            *quiet,
            "-if",
            "not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)",
            "-d",  # date format
            f"{self._src}/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
            f"-{name}<$datetimeoriginal.%le",
            f"-{name}<$datetimeoriginal ${{make;}}.%le",
            f"-{name}<$createdate.%le",
            f"-{name}<$createdate ${{make;}}.%le",
            self._src,
        ]

        try:
            # die RED.'Test sorting of camera shots failed'.RESET, "\n";
            result = run(cmd, capture_output=True, text=True)
        except FileNotFoundError:
            exit("exiftool missing")

        return result.stdout.rstrip()

    def show(self, output):
        # there seems to be no output with 'filename' (ie. when test=False), regardless of -q
        print(Text("Organize camera shots into timestamped folders").green)
        print("----------------------------------------------")

        for line in output.split("\n"):
            # TODO: raw - print(line)
            img, organized_img = line.split(" --> ")
            img, organized_img = img.strip("'"), organized_img.strip("'")

            organized_img = organized_img.replace(f"{self._src}/", "")

            print(
                Path(img).name,
                Text("-->").dim,
                Text(f"{Path(organized_img).parent}/").dir + Path(organized_img).name,
            )

    def sync(self):
        pass


def main():
    uploads = Uploads(args.source)

    # test run for a preview
    output = uploads.organize(test=True, verbose=args.verbose)

    # real run
    if output:
        uploads.show(output)
        if not args.dry_run:
            uploads.organize(test=False, verbose=0)
            # TODO: test for errors before syncing
            uploads.sync()


if __name__ == "__main__":
    main()
