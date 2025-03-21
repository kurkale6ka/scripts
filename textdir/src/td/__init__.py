#! /usr/bin/env python3

"""Text dir baby"""

import argparse
from os import environ as env
from pathlib import Path
from subprocess import run
from typing import NamedTuple


class File(NamedTuple):
    path: Path
    contents: str


class Inode:
    _sep = '\n@@@ File @@@\n'

    def __init__(self, location):
        self._location: Path = location

    def to_text(self) -> str:
        fd = [
            'fd',
            '--strip-cwd-prefix',
            '-tf',
            '-p',
            '--ignore-file',  # needed since I want ignored files to be also ignored in non .git folders
            f'{env["XDG_CONFIG_HOME"]}/git/ignore',
        ]

        try:
            res = run(fd, capture_output=True, text=True)
        except FileNotFoundError:
            fd[0] = 'fdfind'
            res = run(fd, capture_output=True, text=True)

        files = []
        for path in res.stdout.splitlines():
            with open(path) as file:
                contents = file.read().rstrip()
            files.append(File(Path(path), contents))

        return f'{self._location.absolute().name}\n' + self._sep.join(
            f'{file.path}\n{file.contents}' for file in files
        )

    def from_text(self, handle: Path) -> None:
        with open(handle) as file:
            files = file.read().rstrip().split(self._sep)

        print('Parent:', files.pop(0))
        # Path(files.pop(0)).mkdir(exist_ok=True)

        for file in files:
            path, contents = file.split(maxsplit=1)
            print('Path:', path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-d', '--dir', type=Path, default=Path('.'), help='source directory'
    )
    parser.add_argument(
        '-f', '--from-text', type=Path, help='make dirs and files from text'
    )
    parser.add_argument(
        '-t',
        '--to-text',
        action='store_true',
        help='export dir as a single file of text',
    )
    args = parser.parse_args()

    if args.to_text:
        dir = Inode(args.dir)
        print(dir.to_text())
    else:
        file = Inode(args.from_text)
        file.from_text(args.from_text)


if __name__ == '__main__':
    main()
