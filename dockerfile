ARG GIT_TAG
ARG GIT_SHA
ARG GIT_BRANCH
ARG GIT_DATE
ARG BUILD_DATE

FROM haproxy:3.1.2

LABEL com.haproxy.git.tag="${GIT_TAG}"
LABEL com.haproxy.git.sha="${GIT_SHA}"
LABEL com.haproxy.git.branch="${GIT_BRANCH}"
LABEL com.haproxy.git.date="${GIT_DATE}"
LABEL com.haproxy.build.date="${BUILD_DATE}"

ENV HAPROXY_CONFIG='/etc/haproxy/haproxy.cfg'
ENV HAPROXY_PORTS='80,443'

USER root

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    certbot \
    cron \
    curl \
    inotify-tools\
    iptables \
    logrotate \
    rsyslog \
    sudo \
    systemctl \
    vim && \
  rm -rf /var/lib/apt/lists/* && \
  sudo usermod -a -G sudo haproxy && \
  echo "haproxy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/haproxy && \
  chmod 0440 /etc/sudoers.d/haproxy && \
  mkdir -p /var/lib/haproxy /etc/ssl && \
  chown haproxy:haproxy /var/lib/haproxy && \
  install -m 777 /dev/null /var/log/cron.log && \
  curl -OL git.io/ansi && chmod 755 ansi && sudo mv ansi /usr/bin/

### Copy files
COPY configs/haproxy.rsyslog.conf /etc/rsyslog.d/haproxy.conf
COPY configs/haproxy.logrotate.conf /etc/logrotate.d/haproxy
COPY scripts/regenerate.sh /
COPY scripts/bootstrap.sh /

### File modes
RUN \
  chmod 644 /etc/rsyslog.d/haproxy.conf && \
  chmod 644 /etc/logrotate.d/haproxy && \
  chmod +r /etc/ssl/private

USER haproxy
ENTRYPOINT ["bash", "-c", "/bootstrap.sh"]
