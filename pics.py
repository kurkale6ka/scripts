#! /usr/bin/env python3

"""Organize images into a hierarchy of folders by reading their EXIF metadata

year/month/name_with_model
└─ month
"""

from subprocess import run
from os import environ as env
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
        self._src = src

    def organize(self, test: bool = False, verbose: int = 0):
        """TODO"""

        quiet = ["-q", "-q"]
        if verbose == 1:
            quiet.pop()
        if verbose == 2:
            quiet.clear()

        name = "testname" if test else "filename"

        # test run
        cmd = [
            "exiftool",
            *quiet,
            "-if",
            "not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)",
            "-d",
            f"{self._src}/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
            f"-{name}<$datetimeoriginal.%le",
            f"-{name}<$datetimeoriginal ${{make;}}.%le",
            f"-{name}<$createdate.%le",
            f"-{name}<$createdate ${{make;}}.%le",
            self._src,
        ]

        try:
            # die RED.'Test sorting of camera shots failed'.RESET, "\n";
            result = run(cmd)
            # TODO: test if stdout
            print(result)
        except FileNotFoundError:
            exit("exiftool missing")

    def sync(self):
        pass


if __name__ == "__main__":
    uploads = Uploads(args.source)

    # test run for a preview
    uploads.organize(test=True, verbose=args.verbose)

    # real run
    if not args.dry_run:
        uploads.organize(test=False, verbose=0)
