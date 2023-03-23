#! /usr/bin/env python3

"""Manage your web bookmarks from the command line"""

from argparse import ArgumentParser, RawTextHelpFormatter
import webbrowser as browser
from re import search
from os import environ as env, execlp
from subprocess import run, PIPE

parser = ArgumentParser(
    prog="www", description=__doc__, formatter_class=RawTextHelpFormatter
)
group = parser.add_mutually_exclusive_group()
group.add_argument(
    "-a", "--add", type=str, help="add bookmark (use quotes to preserve spaces)"
)
group.add_argument(
    "-e", "--edit", action="store_true", help="edit bookmarks with your editor"
)
group.add_argument(
    "filter",
    nargs="?",
    type=str,
    default=None,
    help="filter bookmarks using fzf:\nhttps://github.com/junegunn/fzf#search-syntax",
)
args = parser.parse_args()


class Bookmarks:
    """Manage your bookmarks"""

    database = env["XDG_DATA_HOME"] + "/sites"

    @classmethod
    def add(cls, bookmark: str) -> None:
        """Add a bookmark"""
        with open(cls.database, "a") as db:
            db.write(bookmark + "\n")

    @classmethod
    def edit(cls) -> None:
        """Edit a bookmark in your editor"""
        execlp(env["EDITOR"], env["EDITOR"], cls.database)

    @classmethod
    def read(cls, filter_query: str | None = None) -> None:
        """Read a bookmark"""

        fzf = ["fzf", "-0", "-1", "--cycle", "--height", "60%"]
        if filter_query:
            fzf.extend(("-q", args.filter))

        # Open the bookmarks
        try:
            with open(cls.database) as db:
                site = run(fzf, stdin=db, stdout=PIPE, text=True)
                site = site.stdout.rstrip()
        except FileNotFoundError as err:
            exit("Add your bookmarks to: " + err.filename.replace(env["HOME"], "~"))

        # Match a URL
        match = (
            search(r"https?://\S+", site)
            or search(r"www\.\S+", site)
            or search(r"\S+\.com\b", site)
        )

        # Browse URL
        if match:
            url = match.group()
            if not url.casefold().startswith("http"):
                url = "https://" + url
            browser.open(url)
        else:
            error = f"No valid URL in: {site}" if site else "No match"
            exit(error)


if __name__ == "__main__":
    bookmarks = Bookmarks()

    if args.add:
        bookmarks.add(args.add)
    elif args.edit:
        bookmarks.edit()
    else:
        bookmarks.read(args.filter)
