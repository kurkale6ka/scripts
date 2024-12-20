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
    def __init__(self, cert: Certificate):
        self._cert = cert

    def _values(self, attr, oid: x509.ObjectIdentifier):
        return "\n".join(a.value for a in attr.get_attributes_for_oid(oid))

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
        return [self.subject, self.issuer, self.before, self.after]


def load_certs(file, all: bool = False) -> Certificate | list[Certificate]:
    with open(file, "rb") as f:
        pem = f.read()

    if all:
        return x509.load_pem_x509_certificates(pem)
    else:
        return x509.load_pem_x509_certificate(pem)


class Headers(StrEnum):
    SUBJECT = "Subject CN"
    ISSUER = "Issuer CN"
    BEFORE = "From"
    AFTER = "To"


def main():

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    parser.add_argument(
        "-s", "--sort", type=str, choices=[h.name.lower() for h in Headers], help=""
    )
    group.add_argument("-c", "--chain", type=Path, help="")
    group.add_argument(
        "folder",
        metavar=("FILE|FOLDER"),
        type=Path,
        nargs="?",
        help="show certificates on the file system",
    )
    args = parser.parse_args()

    # Start
    if args.chain:
        certs = [Cert(cert) for cert in load_certs(args.chain, all=True)]
        df = pd.DataFrame(
            [[cert.subject, cert.issuer] for cert in certs],
            columns=[Headers.SUBJECT, Headers.ISSUER],
        )

    elif args.folder:
        if args.folder.is_dir():
            # TODO: use asyncio multiproc?
            exts = (".pem", ".crt", ".cer")
            certs = [
                Cert(load_certs(file))
                for file in args.folder.iterdir()
                if file.suffix in exts
            ]
        elif args.folder.is_file():
            certs = [Cert(load_certs(args.folder))]

        df = pd.DataFrame([cert.attributes for cert in certs], columns=list(Headers))

    if args.sort:
        sort = [h for h in Headers if h.name == args.sort.upper()]
        df = df.sort_values(by=sort[0])

    if df.shape[0] == 1:
        certs = tabulate(
            df.transpose(),
            disable_numparse=True,
            colalign=("right", "left"),
            tablefmt="plain",
        )
    else:
        certs = tabulate(df, headers=df.columns, disable_numparse=True, showindex=False)

    print(certs)


if __name__ == "__main__":
    main()
