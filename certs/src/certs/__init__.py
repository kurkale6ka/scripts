import argparse
import asyncio
from enum import StrEnum
from pathlib import Path

import aiofiles
import pandas as pd
from cryptography import x509
from cryptography.x509.base import Certificate
from cryptography.x509.oid import NameOID
from tabulate import tabulate
from tqdm.asyncio import tqdm

from . import colors as fg

# TODO:
# - man page + readthedocs sphinx
# - tests
# - all Cert fields + -f + -l/-a --long for more fields
# - debug with warn/abort
# - --sort with 1 letter
# - -e expyring soon


# TODO: inherit from Certificate?
#       here, it seems simpler to use composition
class Cert:
    """Define 'new' properties for Certificate

    Get values of existing properties and expose them with shorter names

    Attributes:
        inode: File or FOLDER/ to gather certificates from
    """

    def __init__(self, inode: Path, cert: Certificate):
        self._cert = cert
        self.inode = inode.name

    def _values(self, attr, oid: x509.ObjectIdentifier) -> str:
        """Get an usable value out of an attribute"""
        return '\n'.join(a.value for a in attr.get_attributes_for_oid(oid))

    @property
    def subject(self):
        return self._values(self._cert.subject, NameOID.COMMON_NAME)

    @property
    def issuer(self):
        return self._values(self._cert.issuer, NameOID.COMMON_NAME)

    @property
    def before(self):
        return self._cert.not_valid_before_utc

    @property
    def after(self):
        return self._cert.not_valid_after_utc

    # dir() can't be used as it sorts the result
    @property
    def properties(self):
        return [
            self.subject,
            self.issuer,
            self.before,
            self.after,
            None,  # days left: after - before
            self.inode,
        ]


async def a_read(file: Path) -> tuple[Path, str]:
    """Asynchronously read file contents

    Returns:
        (file, contents)
    """

    async with aiofiles.open(file, 'rb') as f:
        contents = await f.read()

    return (file, contents)


async def load_certs(inode: Path) -> list[Cert]:
    """Load certificates

    For a File, get all bundled certificates.
    For a FOLDER, get all certificates in that FOLDER.

    Args:
        inode: File or FOLDER/ on the file system

    Returns:
        certificates
    """

    certs = []

    if inode.is_dir():
        exts = ('.pem', '.crt', '.cer')

        async with asyncio.TaskGroup() as tg:
            tasks = tqdm(
                [
                    tg.create_task(a_read(file))
                    for file in inode.iterdir()
                    if file.suffix in exts
                ],
                bar_format='{l_bar}{bar:90}{r_bar}',
                leave=False,
            )

        for task in tasks:
            file, pem = task.result()
            try:
                certs.append(Cert(file, x509.load_pem_x509_certificate(pem)))
            except ValueError:
                fg.warn(f'Unable to load PEM file:{fg.res}', file.name)

    elif inode.is_file():
        with open(inode, 'rb') as f:
            pem = f.read()

        try:
            certs = [Cert(inode, c) for c in x509.load_pem_x509_certificates(pem)]
        except ValueError:
            fg.warn(f'Unable to load PEM file:{fg.res}', inode.name)

    return certs


class Headers(StrEnum):
    SUBJECT = 'Subject CN'
    ISSUER = 'Issuer CN'
    BEFORE = 'From'
    AFTER = 'To'
    DAYS = 'Days Left'
    FILE = 'File'


def main():
    parser = argparse.ArgumentParser(
        description="Get certificates's info. Handier than `openssl ...` in a loop."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        '-s',
        '--sort',
        type=str,
        choices=[h.name.lower() for h in Headers],
        nargs='?',
        const=Headers.SUBJECT.name.lower(),
        help='default: subject',
    )
    group.add_argument(
        '-c', '--chain', action='store_true', help='show bundled subject/issuer CNs'
    )
    parser.add_argument(
        'inode',
        metavar=('File|FOLDER'),
        type=Path,
        nargs='?',
        default='.',
        help='source to gather certificates from (default: .)',
    )
    args = parser.parse_args()

    # File|FOLDER
    args.inode.exists() or fg.abort('Valid File|FOLDER expected')

    certs = asyncio.run(load_certs(args.inode)) or exit()

    if args.chain:
        if args.inode.is_file():
            print(
                '\n\n'.join(
                    f'{Headers.SUBJECT}:  {cert.subject}\n {fg.dim}{Headers.ISSUER}:{fg.res}  {cert.issuer}'
                    for cert in certs
                )
            )
            exit()
        else:
            fg.abort(
                f"-c bad argument:{fg.res} {fg.dir}{args.inode.name}{fg.res} isn't a file"
            )

    # Create pandas' DataFrame
    df = pd.DataFrame([cert.properties for cert in certs], columns=list(Headers))
    df[Headers.DAYS] = (df[Headers.AFTER] - df[Headers.BEFORE]).dt.days

    # --sort
    if args.sort:
        sort = [h for h in Headers if h.name == args.sort.upper()][0]
    elif args.inode.is_file():
        sort = None  # without -s, keep original order of bundled certificates
    else:
        sort = Headers.SUBJECT

    if sort:
        if sort in (Headers.BEFORE, Headers.AFTER, Headers.DAYS):
            df.sort_values(by=sort, inplace=True)
        else:
            # ignore case: treat uppercase same as lowercase letters
            df.sort_values(by=sort, inplace=True, key=lambda col: col.str.lower())

    # Result
    if not df.empty:
        # Format nicely before output
        dt_fmt = '%d %b %Y %H:%S'  # dd mmm yyyy hh:ss

        def _dt_split(stamp: str) -> str:
            """Normal display for day/month/year, dimmed display for hour:seconds"""
            date, time = stamp.rsplit(None, 1)
            return f'{date}{fg.dim} {time}{fg.res}'

        def _days_color(days: int) -> str:
            if days < 0:
                color = fg.dim  # expired
            elif days <= 7:
                color = fg.red  # urgent: expyring very soon
            elif days <= 14:
                color = fg.yel  # warning: expyring soon
            else:
                color = fg.grn  # valid

            return color + str(days) + fg.res

        df[Headers.BEFORE] = (
            pd.to_datetime(df[Headers.BEFORE]).dt.strftime(dt_fmt).apply(_dt_split)
        )
        df[Headers.AFTER] = (
            pd.to_datetime(df[Headers.AFTER]).dt.strftime(dt_fmt).apply(_dt_split)
        )
        df[Headers.DAYS] = df[Headers.DAYS].apply(_days_color)
        df[Headers.FILE] = df[Headers.FILE].apply(lambda f: fg.cya + f + fg.res)

        # For a single certificate, display info vertically, else show a table
        if df.shape[0] == 1:
            df.columns = (f'{col}:' for col in df.columns)  # add a :

            certs = tabulate(
                df.transpose(),
                disable_numparse=True,
                colalign=('right', 'left'),
                tablefmt='plain',
            )
        else:
            certs = tabulate(
                df, headers=df.columns, disable_numparse=True, showindex=False
            )

        print(certs)


if __name__ == '__main__':
    main()
