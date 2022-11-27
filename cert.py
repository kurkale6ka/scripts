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

    def __str__(self):
        return '{}: {}'.format(self._label, self._value)

class MyCertificate:

    def __init__(self, certificate):
        self._fields = []
        with open(certificate, 'rb') as f:
            self._cert = x509.load_pem_x509_certificate(f.read())

    def get_field(self, field):
        if field == 'subject':
            field = Field(field, self._cert.subject.rfc4514_string())
        elif field == 'issuer':
            field = Field(field, self._cert.issuer.rfc4514_string())
        elif field == 'start':
            field = Field(field, self._cert.not_valid_before.strftime('%d %b %Y %R'))
        elif field == 'end':
            field = Field(field, self._cert.not_valid_after.strftime('%d %b %Y %R'))
        self._fields.append(field)
        return field

    @property
    def fields(self):
        width = max((len(f.label) for f in self._fields), default=1)
        return '\n'.join('{:>{}}: {}'.format(f.label, width, f.value) for f in self._fields)

    def __str__(self):
        for f in 'subject', 'issuer', 'start', 'end':
            self.get_field(f)
        return self.fields

if __name__  == "__main__":

    cert = MyCertificate(args.certificate)

    if args.subject:
        cert.get_field('subject')

    if args.issuer:
        cert.get_field('issuer')

    if args.dates:
        cert.get_field('start')
        cert.get_field('end')

    if cert.fields:
        print(cert.fields)
    else:
        print(cert)
