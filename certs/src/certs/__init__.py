import argparse
import asyncio
import itertools
from datetime import datetime
from enum import IntEnum, StrEnum
from pathlib import Path
from typing import Sequence

import aiofiles
import pandas as pd
from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.x509.base import Certificate
from cryptography.x509.extensions import ExtensionNotFound
from cryptography.x509.oid import ExtensionOID, NameOID
from tabulate import tabulate
from tqdm.asyncio import tqdm

from . import colors as fg

# TODO:
# - tests
# - man page + readthedocs sphinx
# - all Cert fields


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

    def _dns_names(self, extension) -> str:
        try:
            ext = self._cert.extensions.get_extension_for_oid(extension)
            return '\n'.join(ext.value.get_values_for_type(x509.DNSName))
        except ExtensionNotFound:
            return ''

    @property
    def subject(self) -> str:
        return self._values(self._cert.subject, NameOID.COMMON_NAME)

    @property
    def issuer(self) -> str:
        return self._values(self._cert.issuer, NameOID.COMMON_NAME)

    @property
    def before(self) -> datetime:
        return self._cert.not_valid_before_utc

    @property
    def after(self) -> datetime:
        return self._cert.not_valid_after_utc

    @property
    def san(self) -> str:
        return self._dns_names(ExtensionOID.SUBJECT_ALTERNATIVE_NAME)

    @property
    def isan(self) -> str:
        return self._dns_names(ExtensionOID.ISSUER_ALTERNATIVE_NAME)

    @property
    def iemail(self) -> str:
        return self._values(self._cert.issuer, NameOID.EMAIL_ADDRESS)

    @property
    def serial(self) -> str:
        return f'{self._cert.serial_number:X}'

    @property
    def fingerprint(self) -> str:
        return self._cert.fingerprint(hashes.SHA1()).hex().upper()

    # dir() can't be used as it sorts the result
    @property
    def properties(self) -> list:
        return [
            self.subject,
            self.issuer,
            self.before,
            self.after,
            None,  # days left: after - before
            self.san,
            self.isan,
            self.iemail,
            self.serial,
            self.fingerprint,
            self.inode,
        ]


class Expiry(IntEnum):
    EXPIRED = 0
    ALERT = 7  # one week
    WARNING = 14  # two weeks


async def a_read(file: Path) -> tuple[Path, str]:
    """Asynchronously read file contents

    Returns:
        (file, contents)
    """

    async with aiofiles.open(file, 'rb') as f:
        contents = await f.read()

    return (file, contents)


async def load_certs(inode: Path, debug: bool) -> list[Cert]:
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
                fg.info(debug, f'unable to load PEM file:{fg.res}', file.name)

    elif inode.is_file():
        with open(inode, 'rb') as f:
            pem = f.read()

        for c in x509.load_pem_x509_certificates(pem):
            try:
                certs.append(Cert(inode, c))
            except ValueError:
                fg.info(debug, f'unable to load PEM file:{fg.res}', inode.name)

    return certs


class Headers(StrEnum):
    SUBJECT = 'Subject CN'
    ISSUER = 'Issuer CN'
    BEFORE = 'From'
    AFTER = 'To'
    DAYS = 'Days Left'
    SAN = 'Subject Alternative Name'
    ISAN = 'Issuer Alternative Name'
    IEMAIL = 'Issuer Email'
    SERIAL = 'Serial Number'
    FINGERPRINT = 'SHA1 Fingerprint'
    FILE = 'File'


def validate_fields(fields: str) -> Sequence[int]:
    def _range(fields_range: str):
        start, end = map(int, fields_range.split('-'))
        return range(start - 1, end)

    if fields.translate(str.maketrans('', '', ',-')).isnumeric():
        return list(
            itertools.chain.from_iterable(
                _range(f) if '-' in f else [int(f) - 1] for f in fields.split(',')
            )
        )

    fg.warn(True, 'valid fields specification expected, e.g. 1,7-10 | 5,1-3,7-9 | ...')
    raise ValueError


def help_fields() -> str:
    return ', '.join(
        f'{i}: {v}' for (i, v) in enumerate([h.name.lower() for h in Headers], 1)
    )


def validate_sort(sort: str) -> str:
    cols = [h.name.lower() for h in Headers if h.name.lower().startswith(sort)]
    if cols:
        if len(cols) == 1:
            return cols[0]

    fg.warn(
        True, f'--sort: more than one match with "{sort}":{fg.res}', ', '.join(cols)
    )
    raise ValueError


def main():
    parser = argparse.ArgumentParser(
        usage='%(prog)s [-d] [-f FIELDS] [-a] [-c|-s] [-e] [File|FOLDER]',
        description='Extract info from certificates. Handier than `openssl ...` in a loop.',
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        '-d', '--debug', action='store_true', help='output all warnings'
    )
    parser.add_argument(
        '-f',
        '--fields',
        type=validate_fields,
        help=f'e.g. 5,1-3,7-9 (5th, 1st to 3rd, 7th to 9th)\n{help_fields()}',
    )
    parser.add_argument('-a', '--all', action='store_true', help='include all fields')

    e_group = parser.add_mutually_exclusive_group()
    e_group.add_argument(
        '-c', '--chain', action='store_true', help='show bundled Subject/Issuer CNs'
    )
    e_group.add_argument(
        '-s',
        '--sort',
        type=validate_sort,
        choices=[h.name.lower() for h in Headers],
        nargs='?',
        const=Headers.SUBJECT.name.lower(),
        help='default: subject',
    )

    parser.add_argument(
        '-e',
        '--expiring-soon',
        action='store_true',
        help=f'limit to certificates nearing expiry\n{fg.ita}yellow:{fg.res} expiry in 2 weeks\n{fg.ita}red:{fg.res} expiry in a week',
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
    if args.inode.exists():
        certs = (
            # load certificates
            asyncio.run(load_certs(args.inode, args.debug)) or exit()
        )
    else:
        fg.abort('Valid File|FOLDER expected')

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

    # this needs to come before --sort,
    # in order not to sort by fields we decide to omit with -f
    if args.fields:
        if not all(0 <= f < len(df.columns) for f in args.fields):
            fg.abort(f'field limits:{fg.res} 1 <= ... <= {len(df.columns)}')
        df = df.iloc[:, args.fields]
    elif not args.all:
        df = df.loc[
            :,
            [
                Headers.SUBJECT,
                Headers.ISSUER,
                Headers.BEFORE,
                Headers.AFTER,
                Headers.DAYS,
                Headers.FILE,
            ],
        ]

    # --expiring-soon
    if args.expiring_soon:
        try:
            df = df[
                (Expiry.EXPIRED <= df[Headers.DAYS])
                & (df[Headers.DAYS] <= Expiry.WARNING)
            ]
        except KeyError:
            fg.abort('"days" field missing')

    # Without --sort, if it's a file:
    #     keep original order of bundled certificates, else:

    # --sort
    if args.sort or not args.inode.is_file():
        if args.sort:
            sort = [h for h in Headers if h.name == args.sort.upper()][0]
        else:
            sort = Headers.SUBJECT

        try:
            if sort in (Headers.BEFORE, Headers.AFTER, Headers.DAYS):
                df.sort_values(by=sort, inplace=True)
            elif sort in (Headers.SERIAL, Headers.FINGERPRINT):
                df.sort_values(
                    by=sort, inplace=True, key=lambda col: col.apply(int, base=16)
                )
            else:
                # ignore case: treat uppercase same as lowercase letters
                df.sort_values(by=sort, inplace=True, key=lambda col: col.str.lower())
        except KeyError:
            fg.info(args.debug, f'sort field missing:{fg.res} {sort.name.lower()}')

    # Result
    if not df.empty:
        # Format nicely before output
        dt_fmt = '%d %b %Y %H:%S'  # dd mmm yyyy hh:ss

        def _dt_split(stamp: str) -> str:
            """Normal display for day/month/year, dimmed display for hour:seconds"""
            date, time = stamp.rsplit(None, 1)
            return f'{date}{fg.dim} {time}{fg.res}'

        def _days_color(days: int) -> str:
            if days < Expiry.EXPIRED:
                color = fg.dim
            elif days <= Expiry.ALERT:
                color = fg.red
            elif days <= Expiry.WARNING:
                color = fg.yel
            else:  # valid
                color = fg.grn

            return color + str(days) + fg.res

        def _format_date(date):
            if date in df.columns:
                df[date] = pd.to_datetime(df[date]).dt.strftime(dt_fmt).apply(_dt_split)

        _format_date(Headers.BEFORE)
        _format_date(Headers.AFTER)

        if Headers.DAYS in df.columns:
            df[Headers.DAYS] = df[Headers.DAYS].apply(_days_color)

        if Headers.FILE in df.columns:
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
                df,
                headers=df.columns,
                disable_numparse=True,
                showindex=False,
                tablefmt='grid'
                if any(h in df.columns for h in (Headers.SAN, Headers.ISAN))
                else 'simple',
            )

        print(certs)


if __name__ == '__main__':
    main()
