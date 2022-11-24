#! ~/py-envs/utils/bin/python

'''Show Certificate/CSR info
create CSR
'''

import OpenSSL.crypto as crypto

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("certificate", type=str, help="certificate file|URL")
args = parser.parse_args()

with open(args.certificate) as f:
    cert = crypto.load_certificate(crypto.FILETYPE_PEM, f.read())

print(cert.get_subject())
print(cert.get_issuer())
print(cert.get_notBefore())
print(cert.get_notAfter())
