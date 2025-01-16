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
  # groupadd -g 1000 -r haproxy && \
  # useradd -m -r -g haproxy -u 1000 haproxy && \
  sudo usermod -a -G sudo haproxy && \
  echo "haproxy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/haproxy && \
  chmod 0440 /etc/sudoers.d/haproxy && \
  mkdir -p /var/lib/haproxy /etc/ssl && \
  chown haproxy:haproxy /var/lib/haproxy && \
  install -m 777 /dev/null /var/log/cron.log

### Copy files
COPY haproxy.rsyslog.conf /etc/rsyslog.d/haproxy.conf
COPY haproxy.logrotate.conf /etc/logrotate.d/haproxy
COPY regenerate.sh /
COPY simple_regenerate.sh /
COPY functions.sh /
COPY bootstrap.sh /

### File modes
RUN \
  chmod 644 /etc/rsyslog.d/haproxy.conf \
  && chmod 644 /etc/logrotate.d/haproxy

USER haproxy
ENTRYPOINT ["bash", "-c", "/bootstrap.sh"]
