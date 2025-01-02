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


# TODO: inherit from Certificate?
class Cert:
    """Certificate wrapper

    Attributes:
        inode: File or FOLDER/ to gather certificates from
    """

    def __init__(self, inode: Path, cert: Certificate):
        self._cert = cert
        self.inode = inode.name

    def _values(self, attr, oid: x509.ObjectIdentifier):
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

    @property
    def attributes(self):
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

    if inode.is_dir():
        exts = ('.pem', '.crt', '.cer')

        async with asyncio.TaskGroup() as tg:
            tasks = [
                tg.create_task(a_read(file))
                for file in inode.iterdir()
                if file.suffix in exts
            ]

        certs = []
        for task in tasks:
            file, pem = task.result()
            try:
                certs.append(Cert(file, x509.load_pem_x509_certificate(pem)))
            except ValueError:
                print('Unable to load PEM file:', file)

    elif inode.is_file():
        with open(inode, 'rb') as f:
            pem = f.read()
        try:
            certs = [Cert(inode, c) for c in x509.load_pem_x509_certificates(pem)]
        except ValueError:
            print('Unable to load PEM file:', inode)

    return certs


class Headers(StrEnum):
    SUBJECT = 'Subject CN'
    ISSUER = 'Issuer CN'
    BEFORE = 'From'
    AFTER = 'To'
    DAYS = 'Days Left'
    FILE = 'Location'


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        '-s',
        '--sort',
        type=str,
        choices=[h.name.lower() for h in Headers],
        help='default: subject',
    )
    group.add_argument('-c', '--chain', action='store_true', help='chain...')
    parser.add_argument(
        'inode',
        metavar=('File|FOLDER'),
        type=Path,
        nargs='?',
        default='.',
        help='show certificates on the file system',
    )
    args = parser.parse_args()

    # File|FOLDER
    certs = asyncio.run(load_certs(args.inode)) or exit()

    if args.chain:
        if args.inode.is_file():
            print(
                '\n\n'.join(
                    f'{Headers.SUBJECT}:  {cert.subject}\n {Headers.ISSUER}:  {cert.issuer}'
                    for cert in certs
                )
            )
            exit()
        else:
            exit(f"{args.inode.name} isn't a file")

    # Create pandas' DataFrame
    df = pd.DataFrame([cert.attributes for cert in certs], columns=list(Headers))
    df[Headers.DAYS] = (df[Headers.AFTER] - df[Headers.BEFORE]).dt.days

    # --sort
    if args.sort:
        sort = [h for h in Headers if h.name == args.sort.upper()][0]
    else:
        sort = Headers.SUBJECT

    if sort not in (Headers.BEFORE, Headers.AFTER, Headers.DAYS):
        # ignore case: treat uppercase same as lowercase letters
        df.sort_values(by=sort, inplace=True, key=lambda col: col.str.lower())
    else:
        df.sort_values(by=sort, inplace=True)

    # Result
    if not df.empty:
        # dates formatting
        dt_fmt = '%-d %b %Y %H:%S'
        df[Headers.BEFORE] = pd.to_datetime(df[Headers.BEFORE]).dt.strftime(dt_fmt)
        df[Headers.AFTER] = pd.to_datetime(df[Headers.AFTER]).dt.strftime(dt_fmt)

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
