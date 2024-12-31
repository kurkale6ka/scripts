import argparse
from enum import StrEnum
from pathlib import Path

import pandas as pd
from cryptography import x509
from cryptography.x509.base import Certificate
from cryptography.x509.oid import NameOID
from tabulate import tabulate


# TODO: inherit from Certificate?
class Cert:
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
        return [self.subject, self.issuer, self.before, self.after, self.inode]


def load_certs(inode: Path) -> list[Cert]:
    """Load certificates

    For a file, get all bundled certificates.
    For a folder/, get all certificates in that folder.

    Args:
        inode: file or folder/ on the file system

    Returns:
        certificates
    """

    if inode.is_dir():
        # TODO: use asyncio multiproc?
        exts = ('.pem', '.crt', '.cer')

        certs = []
        for file in inode.iterdir():
            if file.suffix in exts:
                with open(file, 'rb') as f:
                    pem = f.read()
                certs.append(Cert(file, x509.load_pem_x509_certificate(pem)))

    elif inode.is_file():
        with open(inode, 'rb') as f:
            pem = f.read()
        certs = [Cert(inode, c) for c in x509.load_pem_x509_certificates(pem)]

    return certs


def chain(certs: list[Cert]) -> str:
    return '\n\n'.join(
        f'{Headers.SUBJECT}: {cert.subject}\n {Headers.ISSUER}: {cert.issuer}'
        for cert in certs
    )


class Headers(StrEnum):
    SUBJECT = 'Subject CN'
    ISSUER = 'Issuer CN'
    BEFORE = 'From'
    AFTER = 'To'
    INODE = 'Location'


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        '-s', '--sort', type=str, choices=[h.name.lower() for h in Headers], help=''
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

    # Start
    if args.inode:
        certs = load_certs(args.inode)

        if args.chain:
            if args.inode.is_file():
                print(chain(certs))
                exit()
            else:
                exit(f"{args.inode.name} isn't a file")

        df = pd.DataFrame([cert.attributes for cert in certs], columns=list(Headers))

    if args.sort:
        sort = [h for h in Headers if h.name == args.sort.upper()]
        df = df.sort_values(by=sort[0])

    if not df.empty:
        # For a single certificate, display info vertically, else show a table
        if df.shape[0] == 1:
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
