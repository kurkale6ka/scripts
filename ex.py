#! /usr/bin/env python3

"""Fuzzy File Explorer
"""

import argparse
import os
from os import environ as env, PathLike
from subprocess import run, Popen, PIPE

parser = argparse.ArgumentParser()
parser.add_argument(
    "-s", "--source-dir", type=str, nargs="?", help="change base directory"
)
parser.add_argument("-g", "--grep", type=str, help="list files with matches")
parser.add_argument("query", type=str, nargs="?", help="fzf query")
args = parser.parse_args()

fd = ["fd", "--strip-cwd-prefix", "-tf", "-up", "-E.git", "-E'*~'"]
fzf = ["fzf", "-0", "-1", "--cycle", "--print-query", "--expect=alt-v"]


class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = os.path.expanduser(newPath)

    def __enter__(self):
        self.savedPath = os.getcwd()
        os.chdir(self.newPath)

    def __exit__(self, etype, value, traceback):  # pyright: ignore reportUnusedVariable
        os.chdir(self.savedPath)


class HelpDocuments:
    def __init__(self, src: str | PathLike):
        self._src = src

    # TODO: pass kwargs options
    def search(self, cmd, filter):
        with cd(self._src):
            p1 = Popen(cmd, stdout=PIPE, text=True)
            p2 = Popen(filter, stdin=p1.stdout, stdout=PIPE, text=True)
            p1.stdout.close()  # pyright: ignore reportOptionalMemberAccess
            self._results = p2.communicate()[0].rstrip()  # get stdout

            if self._results:
                self._open()
            else:
                exit(1)

    def _open(self, edit=False):
        results = self._results.split(
            "\n"
        )  # fzf -> [--print-query, --expect, document]
        query, pressed_keys, document = results

        if edit or pressed_keys:
            # TODO: exec
            run((env["EDITOR"], document))

        run(("bat", document))


if __name__ == "__main__":
    docs = HelpDocuments(".")

    if args.query:
        fzf.extend(("-q", args.query))

    if args.source_dir:
        docs = HelpDocuments(args.source_dir)

    if not args.grep:
        docs.search(fd, fzf)
    else:
        rg = ("rg", "-S", "--hidden", "-l", args.grep)
        # TODO: show whole file with lines highlighted?
        fzf.extend(("--preview", f"rg -FS --color=always '{args.grep}' {{}}"))

        docs.search(rg, fzf)
