#! /usr/bin/env python3

"""Export a directory to a single text document"""

# TODO:
# - usage with redir
# - classes google code style
# - pytests
import argparse
from os import environ as env
from pathlib import Path
from subprocess import run
from typing import NamedTuple


class File(NamedTuple):
    path: Path
    contents: str


class Folder:
    def __init__(self, path: Path):
        self._path = path

    def to_files(self, sep: str) -> str:
        fd = [
            'fd',
            f'--ignore-file={env["XDG_CONFIG_HOME"]}/git/ignore',
            '-tf',
            '-a',
            '.',
            str(self._path),
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
                    try:
                        contents = file.read().rstrip()
                    except UnicodeDecodeError:
                        # TODO: stderr + colors
                        print('Problem:', path)
                    else:
                        # skip empty files
                        if contents:
                            files.append(
                                File(
                                    Path(path).relative_to(self._path.resolve().parent),
                                    contents,
                                )
                            )
        else:
            exit(proc.stderr.rstrip())

        return sep.join(f'{file.path}\n{file.contents}' for file in files)


class Files:
    def __init__(self, src: Path):
        self._src = src

    def to_folder(self, sep: str) -> None:
        with open(self._src) as file:
            files = file.read().rstrip().split(sep)

        for file in files:
            path, contents = file.split(maxsplit=1)

            Path(path).parent.mkdir(parents=True, exist_ok=True)
            with open(Path(path), 'w') as file:
                file.write(contents)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '-e',
        '--export',
        action='store_true',
        help='export directory as a single stream',
    )
    parser.add_argument(
        '-i',
        '--import-source',
        metavar='SOURCE',
        type=Path,
        help='import directory from source file',
    )
    parser.add_argument(
        'dir', nargs='?', type=Path, default=Path('.'), help='source directory'
    )
    args = parser.parse_args()

    # Main
    sep = '\n----------------------- File -----------------------\n'

    if args.export:
        print(Folder(args.dir).to_files(sep))
    else:
        Files(args.import_source).to_folder(sep)


if __name__ == '__main__':
    main()
