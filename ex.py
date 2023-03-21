#! /usr/bin/env python3

"""Fuzzy File Explorer
"""

import argparse
from dataclasses import dataclass
from pathlib import Path
from os import environ as env, execlp, chdir, PathLike
from subprocess import Popen, PIPE
import webbrowser as browser
from shutil import which

# TODO:
# --exact?
# --grep --only
# recursive grep...

parser = argparse.ArgumentParser()
parser.add_argument(
    "-s",
    "--source-dir",
    type=str,
    default=".",
    nargs="?",
    help="define source directory",
)
parser.add_argument(
    "--header",
    action=argparse.BooleanOptionalAction,
    default=True,
    help="show file path",
)
parser.add_argument(
    "--hidden",
    action=argparse.BooleanOptionalAction,
    default=True,
    help="show dotfiles",
)
grp_view = parser.add_mutually_exclusive_group()
grp_view.add_argument(
    "-b", "--view-in-browser", action="store_true", help="view in browser"
)
grp_view.add_argument(
    "-v",
    "--view-in-editor",
    action="store_true",
    help="view in $EDITOR, use alt-v from within fzf",
)
parser.add_argument("-g", "--grep", type=str, help="list files with matches")
parser.add_argument("query", type=str, nargs="?", help="fzf query")
args = parser.parse_args()


# TODO: @contextmanager
class cd:
    """Context manager for changing the current working directory"""

    def __init__(self, newPath):
        self.newPath = Path(newPath).expanduser()

    def __enter__(self):
        self.savedPath = Path.cwd()
        chdir(self.newPath)

    def __exit__(self, etype, value, traceback):  # pyright: ignore reportUnusedVariable
        chdir(self.savedPath)


class Command:
    def __init__(self, cmd: list[str] = []):
        self._cmd = cmd

    @property
    def cmd(self) -> list[str]:
        return self._cmd

    @cmd.setter
    def cmd(self, value: list[str]):
        self._cmd = value


class Search(Command):
    # TODO: both should find the same amount files, but this is not the case when tested in ~
    fd = [
        "fd",
        "--strip-cwd-prefix",
        "-tf",
        "-p",
        "--ignore-file",  # needed since I want ignored files to be also ignored in non .git folders
        f"{env['XDG_CONFIG_HOME']}/git/ignore",
    ]
    rg = [  # TODO: --binary? test with .pdfs
        "rg",
        "-S",
        "-l",
        "--ignore-file",
        f"{env['XDG_CONFIG_HOME']}/git/ignore",
    ]

    def __init__(self, hidden=True, pattern=None):
        if hidden:
            Search.fd.append("--hidden")
            Search.rg.append("--hidden")
        self._pattern = pattern
        if self._pattern:
            Search.rg.append(self._pattern)
            super().__init__(cmd=Search.rg)
        else:
            super().__init__(cmd=Search.fd)

    @property
    def pattern(self):
        return self._pattern

    @property
    def is_grep(self) -> bool:
        return True if self._pattern else False


class Filter(Command):
    fzf = ["fzf", "-0", "-1", "--cycle", "--print-query", "--expect=alt-v"]

    def __init__(self, query=None, pattern=None):
        self._query = query
        if self._query:
            Filter.fzf.extend(("-q", self._query))
        if pattern:
            # TODO: show whole file with lines highlighted?
            Filter.fzf.extend(("--preview", f"rg -FS --color=always '{pattern}' {{}}"))
        else:
            Filter.fzf.extend(("--preview", f"bat --color always {{}}"))
        super().__init__(cmd=Filter.fzf)

    @property
    def query(self):
        return self._query


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


class Viewer(Command):
    def __init__(self, prog: str = "cat", header: bool = True):
        self._prog = prog
        self._header = header

    # TODO: be able to: viewer = 'editor' which would assign to prog
    @property
    def prog(self):
        return self._prog

    @prog.setter
    def prog(self, value: str):
        self._prog = value

    @property
    def header(self):
        return self._header

    @header.setter
    def header(self, value: bool):
        self._header = value

    def show(self):
        execlp(*self._cmd)

    def __eq__(self, other: str) -> bool:
        return self._prog == other


class Documents:
    def __init__(self, src: str | PathLike = ".", viewer=Viewer()):
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
                    self.search(
                        Search(pattern=data.filter_query),
                        Filter(pattern=data.filter_query),
                    )
            else:
                exit(1)

    def _open(self, data):
        if self._viewer == "editor" or data.pressed_keys:
            editor = env.get("EDITOR", "vi")
            self._viewer.cmd = [editor, editor, data.document]

            # open with nvim (send to running instance)?
            if data.search_cmd.is_grep and "vim" in editor:
                self._viewer.cmd = [
                    editor,
                    editor,
                    "-c",
                    f"0/{data.search_cmd.pattern}",
                    "-c",
                    "noh|norm zz<cr>",
                    data.document,
                ]
            self._viewer.show()

        extension = Path(data.document).suffix

        # Personal help files
        if Path(f"{env['REPOS_BASE']}/github/help/{data.document}").is_file():
            if self._viewer == "browser" and extension in (".adoc", ".md", ".rst"):
                browser.open(
                    f"https://github.com/kurkale6ka/help/blob/master/{data.document}"
                )
                exit()

            if Path(data.document).name == "printf.pl":
                execlp("perl", "perl", data.document)

        if self._viewer == "cat":
            if self._viewer.header:
                print("File:", Path(data.document).resolve())

            if which("bat") is not None and extension not in (".txt", ".text"):
                self._viewer.cmd = ["bat", "bat", data.document]
            else:
                self._viewer.cmd = ["cat", "cat", data.document]

        self._viewer.show()


if __name__ == "__main__":
    viewer = Viewer(header=args.header)

    if args.view_in_browser:
        viewer.prog = "browser"

    if args.view_in_editor:
        viewer.prog = "editor"

    search_params = dict(hidden=args.hidden)
    filter_params = dict()

    if args.grep:
        search_params["pattern"] = args.grep
        filter_params["pattern"] = args.grep

    if args.query:
        filter_params["query"] = args.query

    docs = Documents(src=args.source_dir, viewer=viewer)
    docs.search(Search(**search_params), Filter(**filter_params))
