#! ~/py-envs/utils/bin/python

# TODO: exclude -t <-> ...
# format for print
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
        with open(certificate, 'rb') as f:
            self._cert = x509.load_pem_x509_certificate(f.read())

    @property
    def subject(self):
        return Field('subject', self._cert.subject.rfc4514_string())

    @property
    def issuer(self):
        return Field('issuer', self._cert.issuer.rfc4514_string())

    @property
    def start(self):
        return Field('from', self._cert.not_valid_before.strftime('%d %b %Y %R'))

    @property
    def end(self):
        return Field('to', self._cert.not_valid_after.strftime('%d %b %Y %R'))

    def __str__(self):
        _fields = (self.subject, self.issuer, self.start, self.end)
        width = max(len(f.label) for f in _fields)
        return ''.join('{:>{}}: {}'.format(f.label, width, f.value) + '\n' for f in _fields)

if __name__  == "__main__":

    cert = MyCertificate(args.certificate)
    fields = []

    if args.subject:
        fields.append(cert.subject)

    if args.issuer:
        fields.append(cert.issuer)

    if args.dates:
        fields.extend((cert.start, cert.end))

    if not fields:
        print(cert)

    for field in fields:
        print(field.label+':', field.value)
