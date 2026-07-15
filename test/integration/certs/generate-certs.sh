#!/usr/bin/env bash
# Generates a test CA, a MySQL server certificate (SAN: mysql, localhost) and
# a client certificate for mTLS. All files land next to this script and are
# gitignored. Certs must be world-readable: the mysql container runs as uid
# 999 and binwatch as root inside its own container.
set -euo pipefail

cd "$(dirname "$0")"

DAYS=3650

if [[ -f ca.pem && -f server-cert.pem && -f client-cert.pem ]]; then
  echo "certificates already generated, remove *.pem to regenerate"
  exit 0
fi

# CA
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -nodes -days "$DAYS" -key ca-key.pem \
  -subj "/CN=binwatch-integration-ca" -out ca.pem

# Server (SAN includes the compose service name so hostname verification works)
openssl req -newkey rsa:2048 -nodes -keyout server-key.pem \
  -subj "/CN=mysql" -out server-req.pem
openssl x509 -req -in server-req.pem -days "$DAYS" \
  -CA ca.pem -CAkey ca-key.pem -set_serial 01 \
  -extfile <(printf "subjectAltName=DNS:mysql,DNS:localhost,IP:127.0.0.1") \
  -out server-cert.pem

# Client (mTLS)
openssl req -newkey rsa:2048 -nodes -keyout client-key.pem \
  -subj "/CN=binwatch-client" -out client-req.pem
openssl x509 -req -in client-req.pem -days "$DAYS" \
  -CA ca.pem -CAkey ca-key.pem -set_serial 02 \
  -out client-cert.pem

rm -f server-req.pem client-req.pem
chmod 644 ./*.pem

echo "certificates generated:"
openssl verify -CAfile ca.pem server-cert.pem client-cert.pem