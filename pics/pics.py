#! /usr/bin/env python3

"""Organize files into a hierarchy of folders by reading their EXIF metadata

filename -> year
            └─ month
               └─ filename_[camera_model]

I mostly use this script to sort my Dropbox Camera Uploads.
This script also allows to view EXIF tags.
"""

from subprocess import run
from os import environ as env
from pathlib import Path
from pprint import pprint
from decorate import Text  # pyright: ignore reportMissingImports
import argparse

parser = argparse.ArgumentParser(
    usage="\npics [-s SOURCE] [-d DESTINATION] [-v] [-q]\npics -t [tag1,tag2] [files|dir ...] [-v] [-q]",
    description=__doc__,
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
parser.add_argument("-v", "--view", action="store_true", help="view exiftool command")
parser.add_argument(
    "-q",
    "--quiet",
    action="count",
    default=0,
    help="-q to suppress messages\n-qq to suppress messages/warnings",
)
tags = parser.add_argument_group("Tags")
tags.add_argument(
    "-t",
    "--tags",
    type=str,
    nargs="?",
    const="*keyword*,subject,title,*comment*,make,model,createdate,datetimeoriginal",
    help="Tags must be separated by comas (-tmake,model)\n-ta => all (tags)\n-td => alldates",
)
tags.add_argument(
    "files",
    type=str,
    nargs="*",
    default=["."],
    help="show files/dir (default current dir) tags",
)
args = parser.parse_args()


class Uploads:
    """Source foder containing files to be organized"""

    def __init__(self, src):
        self._src = src.rstrip("/")
        self._renames = ""

    def organize(
        self, dst, test: bool = False, view: bool = False, quiet: int = 0
    ) -> None:
        """Organize source files into years/months

        exiftool will do the renaming (ref. 'RENAMING EXAMPLES' in `man exiftool`)
        """

        # destination for organized files to be moved to (TODO: could be used with -qqq in show_renames())
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

        if view:
            pprint(cmd)
            print()

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


class Media:
    def __init__(self, files):
        self._files = files

    def info(self, tags=[], view: bool = False, quiet: int = 0) -> None:
        cmd = ["exiftool", "-a", "-G"]

        if tags == ["a"]:
            tags = ["all"]
        elif tags in (["d"], ["dates"]):
            tags = ["alldates"]
        else:
            # Edge case fix:
            # if -tX is used, we would be passing -X which won't be a tag (there aren't any single-char tags),
            # but it might be a valid exiftool option that will result unexpected behavior
            one_letter_tags = [tag for tag in tags if len(tag) == 1]
            if one_letter_tags:
                err_tags = ", ".join(f"-{tag}" for tag in one_letter_tags)
                exit("Invalid tag(s) found: " + Text(err_tags).red)
            elif len(tags) == 1:
                cmd.append("-S")  # shortest output format when checking a single tag

        tags = [f"-{tag}" for tag in tags]

        if quiet > 0:
            cmd.extend(["-q"] * quiet)

        if view:
            view_cmd = cmd[:]
            view_cmd.extend(tag.replace("*", "\\*") for tag in tags)
            view_cmd.extend(
                f"'{file}'" if " " in file else file for file in self._files
            )
            print(Text(" ".join(view_cmd)).yellow)

        cmd.extend(tags)
        cmd.extend(self._files)

        run(cmd)


def main():
    # Show tags
    if args.tags:
        media = Media(args.files)
        media.info(args.tags.split(","), args.view, args.quiet)
    # Organize
    else:
        uploads = Uploads(args.source)

        # Test run for a preview
        uploads.organize(args.destination, test=True, view=args.view, quiet=args.quiet)

        # Real run
        if uploads.has_renames():
            uploads.show_renames()
            answer = input("\nproceed (y/n)? ")
            if answer == "y":
                uploads.organize(args.destination, test=False, quiet=0)


if __name__ == "__main__":
    main()
