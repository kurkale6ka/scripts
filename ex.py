#! /usr/bin/env python3

"""Fuzzy File Explorer
"""

import argparse
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


class Documents:
    def __init__(self, src: str | PathLike = ".", viewer="cat"):
        self._src = src
        self._viewer = viewer

    # TODO: pass kwargs options
    def search(self, command: Search, filter: Filter):
        with cd(self._src):
            p1 = Popen(command.cmd, stdout=PIPE, text=True)
            p2 = Popen(filter.cmd, stdin=p1.stdout, stdout=PIPE, text=True)
            p1.stdout.close()  # pyright: ignore reportOptionalMemberAccess
            self._results = p2.communicate()[0].rstrip()  # get stdout

            if self._results:
                self._open(command)
            else:
                exit(1)

    def _open(self, cmd):
        results = self._results.split(  # fzf -> [--print-query, --expect, document]
            "\n"
        )
        query, pressed_keys, document = results

        if self._viewer == "editor" or pressed_keys:
            self._viewer = env.get("EDITOR", "vi")

        view_cmd = [self._viewer, self._viewer, document]
        if cmd.is_grep and "vi" in self._viewer:
            view_cmd.extend(("-c", f"0/{cmd.pattern}", "-c", "noh|norm zz<cr>"))

        execlp(*view_cmd)


if __name__ == "__main__":
    viewer = "bat"
    source_dir = "."
    command = Search()
    filter = Filter()

    if args.query:
        filter.query = args.query

    if args.view_in_editor:
        viewer = "editor"

    if args.source_dir:
        source_dir = args.source_dir

    if args.grep:
        filter = Filter(pattern=args.grep)
        command = Search(pattern=args.grep)

    docs = Documents(src=source_dir, viewer=viewer)
    docs.search(command, filter)
