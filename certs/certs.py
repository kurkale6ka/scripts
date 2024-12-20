import argparse
from enum import StrEnum
from pathlib import Path

import pandas as pd
from cryptography import x509


class Cert:
    def __init__(self, file):
        with open(file, "rb") as f:
            pem = f.read()

        self._cert = x509.load_pem_x509_certificate(pem)

    @property
    def subject(self):
        return self._cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME)

    @property
    def issuer(self):
        return self._cert.issuer

    @property
    def attributes(self):
        return [self.subject, self.issuer]


class Headers(StrEnum):
    CN = "Subject CN"
    ISSUER = "Issuer CN"


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "folder", type=Path, help="show certificates on the file system"
    )
    args = parser.parse_args()

    exts = (".pem", ".crt", ".cer")
    certs = [Cert(file) for file in args.folder.iterdir() if file.suffix in exts]

    df = pd.DataFrame([cert.attributes for cert in certs], columns=list(Headers))

    print(df)


if __name__ == "__main__":
    main()
