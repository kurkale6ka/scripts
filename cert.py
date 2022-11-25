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

with open(args.certificate, 'rb') as f:
    cert = x509.load_pem_x509_certificate(f.read())

print('{:>7}: {}'.format('subject', cert.subject.rfc4514_string()))
print('{:>7}: {}'.format('issuer', cert.issuer.rfc4514_string()))
print('{:>7}: {}'.format('from', cert.not_valid_before.strftime('%d %b %Y %R')))
print('{:>7}: {}'.format('to', cert.not_valid_after.strftime('%d %b %Y %R')))

if args.subject:
    print(cert.subject)
