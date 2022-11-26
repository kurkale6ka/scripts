#! ~/py-envs/utils/bin/python

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
    def __init__(self, label, value):
        self._label = label
        self._value = value

    @property
    def label(self):
        return self._label

    @property
    def value(self):
        return self._value

class MyCertificate:

    def __init__(self, certificate):
        self._fields = []
        with open(certificate, 'rb') as f:
            self._cert = x509.load_pem_x509_certificate(f.read())

    def subject(self):
        self._fields.append(Field('subject', self._cert.subject.rfc4514_string()))

    def issuer(self):
        self._fields.append(Field('issuer', self._cert.issuer.rfc4514_string()))

    def start(self):
        self._fields.append(Field('from', self._cert.not_valid_before.strftime('%d %b %Y %R')))

    def end(self):
        self._fields.append(Field('to', self._cert.not_valid_after.strftime('%d %b %Y %R')))

    @property
    def fields(self):
        return self._fields

    def __str__():
        # print all fields
        pass

cert = MyCertificate(args.certificate)

if args.subject:
    cert.subject

for field in cert.fields:
    print(field.label+':', field.value)
