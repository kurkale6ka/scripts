#! ~/py-envs/utils/bin/python

'''Show Certificate/CSR info
create CSR
'''

import OpenSSL.crypto as crypto
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("certificate", type=str, help="certificate file|URL")
args = parser.parse_args()

class Certificate:

    def __init__(self, certificate):
       with open(certificate) as f:
           self._cert = crypto.load_certificate(crypto.FILETYPE_PEM, f.read())

    @property
    def subject(self):
        return self._cert.get_subject()

    @property
    def issuer(self):
        return self._cert.get_issuer()

    @property
    def start(self):
        return self._cert.get_notBefore()

    @property
    def end(self):
        return self._cert.get_notAfter()

cert = Certificate(args.certificate)

print(cert.subject)
print(cert.issuer)
print(cert.start)
print(cert.end)
