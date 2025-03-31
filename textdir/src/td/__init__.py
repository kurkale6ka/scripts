#! /usr/bin/env python3

"""Export a directory to files in a single text document"""

import argparse
from os import environ as env
from pathlib import Path
from subprocess import run
from typing import NamedTuple


class File(NamedTuple):
    path: Path
    contents: str


class Files:
    def __init__(self, src: Path):
        self._src = src

    def to_folder(self, sep: str) -> None:
        with open(self._src) as file:
            parent, rest = file.read().rstrip().split(maxsplit=1)
            files = rest.split(sep)
            # Path(parent).mkdir(exist_ok=True)

        for file in files:
            # TODO: deal with empty files
            path, contents = file.split(maxsplit=1)
            print('Path:', path)


class Folder:
    def __init__(self, path: Path):
        self._path = path

    def to_files(self, sep: str) -> str:
        fd = [
            'fd',
            '--strip-cwd-prefix',
            '-tf',
            '-p',
            f'--ignore-file={env["XDG_CONFIG_HOME"]}/git/ignore',
        ]

        # run fd or fdfind
        try:
            proc = run(fd, capture_output=True, text=True)
        except FileNotFoundError:
            fd[0] = 'fdfind'
            proc = run(fd, capture_output=True, text=True)

        if proc.returncode == 0:
            files: list[File] = []
            for path in proc.stdout.splitlines():
                with open(path) as file:
                    contents = file.read().rstrip()

                # skip empty files
                if contents:
                    files.append(File(Path(path), contents))
        else:
            exit(proc.stderr.rstrip())

        return f'{self._path.absolute().name}\n' + sep.join(
            f'{file.path}\n{file.contents}' for file in files
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '-d', '--dir', type=Path, default=Path('.'), help='source directory'
    )
    parser.add_argument('-s', '--source', type=Path, help='recreate folder from files')
    parser.add_argument(
        '-t',
        '--to-files',
        action='store_true',
        help='export directory to files in a single text document',
    )
    args = parser.parse_args()

    # Main
    sep = '\n----------------------- File -----------------------\n'

    if args.to_files:
        dir = Folder(args.dir)
        print(dir.to_files(sep))
    else:
        files = Files(args.source)
        files.to_folder(sep)


if __name__ == '__main__':
    main()
