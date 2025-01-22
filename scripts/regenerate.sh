#!/usr/bin/env bash

export PS4='+ $0:$LINENO '

IFS=,
set -uex

if [[ ! $# -eq 3 ]] ; then
    echo "USAGE: \n${0} <email> <domain1>[,<domain2>] [internal-ip] \n${0} test@acme.com test.acme.com,test2.acme.com 7999"
    exit 0
fi

### Get DOMAIN
EMAIL=${1:-test@acme.com}
DOMAINS=${2:-test.acme.com}
PORT=${3:-7999}

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
  cat /etc/letsencrypt/live/"${DOMAIN}"/fullchain.pem \
    /etc/letsencrypt/live/"${DOMAIN}"/privkey.pem \
    | tee /etc/ssl/private/"${DOMAIN}"full.pem

  cat /etc/letsencrypt/live/"${DOMAIN}"/cert.pem \
    /etc/letsencrypt/live/"${DOMAIN}"/privkey.pem \
    | tee /etc/ssl/private/"${DOMAIN}".pem
done
