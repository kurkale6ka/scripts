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
parser.add_argument("--verbose", action="store_true", help="show more detail")
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

    def __init__(self, cmd=fzf, verbose=False, query=None, pattern=None):
        if pattern:
            # TODO: show whole file with lines highlighted?
            cmd.extend(("--preview", f"rg -FS --color=always '{pattern}' {{}}"))
        super().__init__(cmd)
        self._verbose = verbose
        self._query = query

    @property
    def query(self):
        return self._query

    @query.setter
    def query(self, value: str):
        Filter.fzf.extend(("-q", value))

    @property
    def verbose(self):
        return self._verbose


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
    filter_verbose: bool = False
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
            data = FilterResults(command, filter.verbose, *results)

            if data.document:
                self._open(data)
            elif data.filter_query:
                # trim any fzf extended search mode characters
                data.filter_query = data.filter_query.lstrip("^'")
                data.filter_query = data.filter_query.rstrip("$")
                data.filter_query = data.filter_query.replace("\\", "")

                if not command.is_grep:
                    if filter.verbose:
                        print("trying grep..")
                    self.search(
                        Search(pattern=data.filter_query),
                        Filter(pattern=data.filter_query),
                    )
            else:
                exit(1)

    def _open(self, data):
        if self._viewer == "editor" or data.pressed_keys:
            editor = env.get("EDITOR", "vi")
            view_cmd = [editor, editor, data.document]

            # open with nvim (send to running instance)?
            if data.search_cmd.is_grep and "vim" in editor:
                view_cmd = [
                    editor,
                    editor,
                    "-c",
                    f"0/{data.search_cmd.pattern}",
                    "-c",
                    "noh|norm zz<cr>",
                    data.document,
                ]

        elif "bat" in self._viewer and data.filter_verbose:
            view_cmd = [self._viewer, self._viewer, "--style", "header", data.document]
        else:
            view_cmd = [self._viewer, self._viewer, data.document]

        # Try the default viewer 1st: bat
        try:
            execlp(*view_cmd)
        except FileNotFoundError:
            if "bat" in self._viewer:
                view_cmd[0:2] = ["cat", "cat"]
                execlp(*view_cmd)
            raise


if __name__ == "__main__":
    # Documents(src, viewer)
    doc_params = {"src": "."}

    if args.source_dir:
        doc_params["src"] = args.source_dir

    if args.view_in_editor:
        doc_params["viewer"] = "editor"

    search_params = {}
    filter_params = {}

    if args.grep:
        search_params["pattern"] = args.grep
        filter_params["pattern"] = args.grep

    if args.verbose:
        filter_params["verbose"] = args.verbose

    if args.query:
        filter_params["query"] = args.query

    docs = Documents(**doc_params)
    docs.search(Search(**search_params), Filter(**filter_params))
