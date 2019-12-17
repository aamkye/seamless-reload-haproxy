#!/usr/bin/env bash

export PS4='+ $0:$LINENO '

set -uex
source ./functions.sh --source-only

# --cap-add NET_ADMIN || iptables
sudo iptables --list

sudo service rsyslog start
sudo service cron start

safe_run
while inotifywait -r -e create,delete,modify,attrib,close_write,move /etc/hosts /etc/ssl/private "${HAPROXY_CONFIG}"; do
  safe_run
done
