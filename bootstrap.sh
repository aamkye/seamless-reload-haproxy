#!/usr/bin/env bash

export PS4='+ $0:$LINENO '

set -uex
source /functions.sh --source-only

# --cap-add CAP_AUDIT_WRITE || sudo
# --cap-add NET_ADMIN || iptables
sudo iptables --list

sudo systemctl restart rsyslog
sudo systemctl restart cron

safe_run
while inotifywait -e create,delete,modify,attrib,close_write,move /etc/hosts /etc/ssl/private "${HAPROXY_CONFIG}"; do
  safe_run
done
