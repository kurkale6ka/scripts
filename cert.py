#! ~/py-envs/utils/bin/python

# TODO: exclude -t <-> ...
# add colors

'''Show Certificate/CSR info
create CSR
'''

from cryptography import x509
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

class MyCertificate:

    def __init__(self, certificate):
        self._fields = []
        with open(certificate, 'rb') as f:
            self._cert = x509.load_pem_x509_certificate(f.read())

    @property
    def subject(self):
        field = Field('subject', self._cert.subject.rfc4514_string())
        self._fields.append(field)
        return field

    @property
    def issuer(self):
        field = Field('issuer', self._cert.issuer.rfc4514_string())
        self._fields.append(field)
        return field

    @property
    def start(self):
        field = Field('from', self._cert.not_valid_before.strftime('%d %b %Y %R'))
        self._fields.append(field)
        return field

    @property
    def end(self):
        field = Field('to', self._cert.not_valid_after.strftime('%d %b %Y %R'))
        self._fields.append(field)
        return field

    @property
    def fields(self):
        width = max(len(f.label) for f in self._fields)
        return ''.join('{:>{}}: {}'.format(f.label, width, f.value) + '\n' for f in self._fields)

    def __str__(self):
        self._fields = (self.subject, self.issuer, self.start, self.end)
        return self.fields

if __name__  == "__main__":

    cert = MyCertificate(args.certificate)

    if args.subject:
        cert.subject

    if args.issuer:
        cert.issuer

    if args.dates:
        cert.start
        cert.end

    print(cert)
    # print(cert.fields)
