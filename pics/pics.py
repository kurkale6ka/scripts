#! /usr/bin/env python3

"""Organize files into a hierarchy of folders by reading their EXIF metadata

filename -> year
            └─ month
               └─ filename_[camera-model]

I mostly use this script to sort my Dropbox Camera Uploads
"""

from subprocess import run
from os import environ as env
from pathlib import Path
from decorate import Text  # pyright: ignore reportMissingImports
import argparse

parser = argparse.ArgumentParser(
    description="Organize your files into years/months",
    formatter_class=argparse.RawTextHelpFormatter,
)
parser.add_argument(
    "-s",
    "--source",
    type=str,
    default=f"{env['HOME']}/Dropbox/Camera Uploads",
    help="source foder containing files to be organized",
)
parser.add_argument(
    "-d",
    "--destination",
    type=str,
    default=f"{env['HOME']}/Dropbox/pics",
    help="destination for organized files to be moved to",
)
parser.add_argument(
    "-q",
    "--quiet",
    action="count",
    default=0,
    help="-q to suppress messages\n-qq to suppress messages/warnings",
)
args = parser.parse_args()


class Uploads:
    """TODO"""

    def __init__(self, src):
        self._src = src.rstrip("/")
        self._renames = ""

    def organize(self, dst, test: bool = False, quiet: int = 0) -> None:
        """Organize source files into years/months

        exiftool will do the renaming (ref. 'RENAMING EXAMPLES' in `man exiftool`)
        """

        self._dst = dst.rstrip("/")

        silence = []
        if quiet > 0:
            silence.extend(["-q"] * quiet)

        name = "testname" if test else "filename"

        cmd = [
            "exiftool",
            *silence,
            "-if",  # it's wrong if both dates are present but are different
            "not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)",
            "-d",  # date format
            f"{self._dst}/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
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

    # TODO: -qqq to hide src/dst!?
    def show_renames(self) -> None:
        print(Text("Organize camera shots into timestamped folders").green)
        print("----------------------------------------------")

        for line in self._renames.split("\n"):
            if " --> " in line:
                file, tree = line.split(" --> ")
                file, tree = file.strip("'"), tree.strip("'")

                fparent = str(Path(file).parent).replace(env["HOME"], "~")
                tparent = str(Path(tree).parents[2]).replace(env["HOME"], "~")

                # year/month/
                tdate = "/".join(Path(tree).parent.parts[-2:]) + "/"

                print(
                    fparent + "/" + Text(Path(file).name).cyan,
                    Text("-->").dim,
                    tparent + "/" + Text(tdate).dir + Text(Path(tree).name).cyan,
                )
            else:
                print(line)


def main():
    uploads = Uploads(args.source)

    # Test run for a preview
    uploads.organize(args.destination, test=True, quiet=args.quiet)

    # Real run
    if uploads.has_renames():
        uploads.show_renames()
        answer = input("\nproceed (y/n)? ")
        if answer == "y":
            uploads.organize(args.destination, test=False, quiet=0)


if __name__ == "__main__":
    main()
