#!/usr/bin/env bash

export PS4='+ $0:$LINENO '

IFS=,
set -uex

if [[ ! $# -eq 3 ]] ; then
    echo "USAGE: $0 test@acme.com 8080 test.acme.com,test2.acme.com"
    exit 0
fi

### Get DOMAIN
EMAIL=${1:-test@acme.com}
PORT=${2:-8080}
DOMAINS=${3:-test.acme.com}

for DOMAIN in ${DOMAINS}; do
  ### Open ports
  certbot certonly \
    --standalone \
    -d "${DOMAIN}" \
    --non-interactive \
    --agree-tos \
    --email "${EMAIL}" \
    --http-01-port=${PORT}

  ### Final PEM creation
  cat /etc/letsencrypt/live/"${DOMAIN}"/cert.pem \
    /etc/letsencrypt/live/"${DOMAIN}"/privkey.pem \
    | tee /etc/ssl/private/"${DOMAIN}".pem
done
