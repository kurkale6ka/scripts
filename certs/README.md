Extract info from certificates. Handier than `openssl ...` in a loop.

# Install

```bash
uv tool install -e .

# man page
mkdir -p "$XDG_DATA_HOME"/man/man1
ln -s /path/to/certs/repo/certs.1 "$XDG_DATA_HOME"/man/man1
```

# OpenSSL commands for reference

```bash
openssl x509 -noout -subject -issuer -dates -in ...

# chain
openssl crl2pkcs7 -nocrl -certfile ... | openssl pkcs7 -noout -print_certs
```
