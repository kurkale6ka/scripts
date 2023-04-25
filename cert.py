#! ~/py-envs/utils/bin/python

# TODO: exclude -t <-> ...
# add colors

"""Show Certificate/CSR info
create CSR
"""


class colors:
    grey = "\033[38;5;242m"


from cryptography import x509
from cryptography.hazmat.primitives import hashes
from colorama import Fore as fg
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("certificate", type=str, help="certificate file|URL")
parser.add_argument("-f", "--fingerprint", action="store_true", help="")
parser.add_argument("-s", "--subject", action="store_true", help="")
parser.add_argument("-i", "--issuer", action="store_true", help="")
parser.add_argument("-d", "--dates", action="store_true", help="")
parser.add_argument("-t", "--text", action="store_true", help="")
args = parser.parse_args()


class Field:
    def __init__(self, label, value, cmd=None):
        self._label = label
        self._value = value
        self._cmd = cmd

    @property
    def label(self):
        return self._label

    @property
    def value(self):
        return self._value

    @property
    def cmd(self):
        return self._cmd

    def __str__(self):
        return "{}: {}".format(self._label, self._value)


class MyCertificate:
    def __init__(self, certificate):
        self._fields = []
        with open(certificate, "rb") as f:
            self._cert = x509.load_pem_x509_certificate(f.read())

    def add_field(self, name):
        field = None

        if name == "fingerprint":
            field = Field("fingerprint", self._cert.fingerprint(hashes.SHA256()))
        elif name == "subject":
            field = Field("subject", self._cert.subject.rfc4514_string())
        elif name == "issuer":
            field = Field("issuer", self._cert.issuer.rfc4514_string())
        elif name == "start":
            field = Field("from", self._cert.not_valid_before.strftime("%d %b %Y %R"))
        elif name == "end":
            field = Field("to", self._cert.not_valid_after.strftime("%d %b %Y %R"))

        if field:
            self._fields.append(field)

    @property
    def fields(self):
        width = max(
            (len(colors.grey + f.label + fg.RESET) for f in self._fields), default=1
        )
        return "\n".join(
            "{:>{}}: {}".format(colors.grey + f.label + fg.RESET, width, f.value)
            for f in self._fields
        )

    def __str__(self):
        for f in "subject", "issuer", "start", "end":
            self.add_field(f)
        return self.fields


if __name__ == "__main__":
    cert = MyCertificate(certificate=args.certificate)

    if args.fingerprint:
        cert.add_field("fingerprint")
    if args.subject:
        cert.add_field("subject")
    if args.issuer:
        cert.add_field("issuer")
    if args.dates:
        cert.add_field("start")
        cert.add_field("end")

    if cert.fields:
        print(cert.fields)
    else:
        print(cert)
