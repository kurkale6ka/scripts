#! /usr/bin/env python3

"""Fuzzy File Explorer
"""

import argparse
from dataclasses import dataclass
import os
from os import environ as env, execlp, PathLike
from subprocess import Popen, PIPE

parser = argparse.ArgumentParser()
parser.add_argument(
    "-s", "--source-dir", type=str, nargs="?", help="change base directory"
)
parser.add_argument("-g", "--grep", type=str, help="list files with matches")
parser.add_argument(
    "-v",
    "--view-in-editor",
    action="store_true",
    help="view in $EDITOR, use alt-v from within fzf",
)
parser.add_argument("query", type=str, nargs="?", help="fzf query")
args = parser.parse_args()


class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):  # pyright: ignore reportUnusedVariable
        os.chdir(self.savedPath)


class Command:
    def __init__(self, cmd: list[str] = []):
        self._cmd = cmd

    @property
    def cmd(self) -> list[str]:
        return self._cmd

    @cmd.setter
    def cmd(self, value: list[str]):
        self._cmd = value


class Filter(Command):
    fzf = ["fzf", "-0", "-1", "--cycle", "--print-query", "--expect=alt-v"]

    def __init__(self, cmd=fzf, query=None, pattern=None):
        if pattern:
            # TODO: show whole file with lines highlighted?
            cmd.extend(("--preview", f"rg -FS --color=always '{pattern}' {{}}"))
        super().__init__(cmd)

        self._query = query
        self._pattern = pattern  # FIX: is it needed?

    @property
    def query(self):
        return self._query

    @query.setter
    def query(self, value: str):
        Filter.fzf.extend(("-q", value))


class Search(Command):
    fd = ["fd", "--strip-cwd-prefix", "-tf", "-up", "-E.git", "-E'*~'"]
    rg = ["rg", "-S", "--hidden", "-l"]

    def __init__(self, pattern=None):
        if not pattern:
            super().__init__(Search.fd)
        else:
            Search.rg.append(pattern)
            super().__init__(Search.rg)
        self._pattern = pattern

    @property
    def pattern(self):
        return self._pattern

    @pattern.setter
    def pattern(self, value: str):
        self._pattern = value

    @property
    def is_grep(self) -> bool:
        return True if self._pattern else False


@dataclass
class FilterResults:
    search_cmd: Search
    filter_query: str | None = None
    pressed_keys: str | None = None
    document: str | None | PathLike = None

    def __post_init__(self):
        if self.filter_query == "":
            self.filter_query = None
        if self.pressed_keys == "":
            self.pressed_keys = None
        if self.document == "":
            self.document = None


class Documents:
    def __init__(self, src: str | PathLike = ".", viewer="bat"):
        self._src = src
        self._viewer = viewer

    def search(self, command: Search, filter: Filter):
        with cd(self._src):
            p1 = Popen(command.cmd, stdout=PIPE, text=True)
            p2 = Popen(filter.cmd, stdin=p1.stdout, stdout=PIPE, text=True)
            p1.stdout.close()  # pyright: ignore reportOptionalMemberAccess
            results = p2.communicate()[0].rstrip()  # get stdout

            # fzf returns this string:
            #     --print-query\n
            #     --expect\n
            #     document
            results = results.split("\n")
            data = FilterResults(command, *results)

            if data.document:
                self._open(data)
            elif data.filter_query:
                # trim any fzf extended search mode characters
                data.filter_query = data.filter_query.lstrip("^'")
                data.filter_query = data.filter_query.rstrip("$")
                data.filter_query = data.filter_query.replace("\\", "")

                if not command.is_grep:
                    print("trying grep..")  # TODO: if verbose
                    self.search(
                        Search(pattern=data.filter_query),
                        Filter(pattern=data.filter_query),
                    )
            else:
                exit(1)

    def _open(self, data):
        view_cmd = [self._viewer, self._viewer, data.document]

        if self._viewer == "editor" or data.pressed_keys:
            self._viewer = env.get("EDITOR", "vi")

        # open with nvim (send to running instance)?
        if data.search_cmd.is_grep and "vi" in self._viewer:
            view_cmd.extend(
                ("-c", f"0/{data.search_cmd.pattern}", "-c", "noh|norm zz<cr>")
            )

        # Try the default viewer 1st: bat
        try:
            execlp(*view_cmd)
        except FileNotFoundError as err:
            if "bat" in str(err):
                view_cmd[0] = "cat"  # TODO: replace a slice
                view_cmd[1] = "cat"
                execlp(*view_cmd)
            raise


if __name__ == "__main__":
    # Documents(src, viewer)
    parameters = dict(src=".")

    if args.source_dir:
        parameters["src"] = args.source_dir

    if args.view_in_editor:
        parameters["viewer"] = "editor"

    command = Search()
    filter = Filter()

    if args.grep:
        command = Search(pattern=args.grep)
        filter = Filter(pattern=args.grep)

    if args.query:
        filter.query = args.query

    docs = Documents(**parameters)
    docs.search(command, filter)
