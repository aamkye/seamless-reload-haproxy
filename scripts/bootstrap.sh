#!/usr/bin/env bash

export PS4='+ $(date --iso-8601=s) $0:$LINENO '

set -uex

export TERM="xterm-256color"

HAPROXY_VALID_MSG=${HAPROXY_VALID_MSG:-"Looks good - reload completed."}
HAPROXY_INVALID_MSG=${HAPROXY_INVALID_MSG:-"Invalid HAProxy configuration - check the logs, leaving old config.."}

ENABLE_SYN_DROP="sudo iptables -I INPUT -p tcp -m multiport --dport ${HAPROXY_PORTS} --syn -j DROP"
DISABLE_SYN_DROP="sudo iptables -D INPUT -p tcp -m multiport --dport ${HAPROXY_PORTS} --syn -j DROP"

HAPROXY_CONFIG=${HAPROXY_CONFIG:-"/etc/haproxy/haproxy.cfg"}
HAPROXY_PORTS=${HAPROXY_PORTS:-"80,443"}

HAPROXY_PID_FILE="/var/run/haproxy.pid"
HAPROXY_CMD="sudo /usr/local/sbin/haproxy -f ${HAPROXY_CONFIG} -p ${HAPROXY_PID_FILE}"
HAPROXY_CHECK_CONFIG_CMD="/usr/local/sbin/haproxy -c -- ${HAPROXY_CONFIG}"


SLACK_URL=${SLACK_URL:-}

function safe_run {
  if [[ ! -f "${HAPROXY_CONFIG}" ]]; then
    echo "No config.." >&2
    exit 1
  fi

  ${HAPROXY_CHECK_CONFIG_CMD} && RC=0 || RC=1
  if [[ ${RC} -ne 0 ]]; then
    notify
  else
    ${ENABLE_SYN_DROP}
    sleep 0.2
    if [[ -f "${HAPROXY_PID_FILE}" ]]; then
      ${HAPROXY_CMD} -sf $(cat ${HAPROXY_PID_FILE})
    else
      ${HAPROXY_CMD}
    fi
    ${DISABLE_SYN_DROP}
    notify
  fi
}

function notify {
  if [[ ${RC} -ne 0 ]]; then
    echo -e "\n--- $(ansi --red -- $(date --iso-8601=s): ${HAPROXY_INVALID_MSG}) ---\n" >&2
    SLACK_MESSAGE="${HAPROXY_INVALID_MSG}"
    SLACK_COLOR="danger"
  else
    echo -e "\n--- $(ansi --green -- $(date --iso-8601=s): ${HAPROXY_VALID_MSG}) ---\n"
    SLACK_MESSAGE="${HAPROXY_VALID_MSG}"
    SLACK_COLOR="good"
  fi

  if [[ ! -z ${SLACK_URL} ]]; then
    curl \
      --insecure \
      -X POST \
      -H 'Content-type: application/json' \
      --data "{ \
        \"username\": \"HAProxy ($(hostname))\",
        \"icon_url\": \"https://d1q6f0aelx0por.cloudfront.net/product-logos/74753c28-31a5-46fa-88c1-5336bdb2e989-haproxy.png\",
        \"attachments\": [{ \
          \"text\": \"${SLACK_MESSAGE}\", \
          \"color\": \"${SLACK_COLOR}\", \
        }] \
      }" \
      "${SLACK_URL}" | true
  fi
}

# --cap-add CAP_AUDIT_WRITE || sudo
# --cap-add NET_ADMIN || iptables
function main {
  sudo iptables --list

  sudo systemctl restart rsyslog
  sudo systemctl restart cron

  safe_run
  while inotifywait -q -e create,delete,modify,attrib,close_write,move /etc/hosts /etc/ssl/private "${HAPROXY_CONFIG}"; do
    safe_run
  done
}

main
