FROM haproxy:2.0.10
ENV HAPROXY_CONFIG='/etc/haproxy/haproxy.cfg'

RUN apt update && \
  apt install -y sudo apt-transport-https && \
  groupadd -g 1000 -r haproxy && \
  useradd -m -r -g haproxy -u 1000 haproxy && \
  echo "haproxy ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/haproxy && \
  chmod 0440 /etc/sudoers.d/haproxy && \
  apt install -y \
    iptables \
    inotify-tools \
    rsyslog \
    certbot \
    curl \
    vim \
    bash-completion && \
  mkdir -p /var/lib/haproxy /etc/ssl && \
  chown haproxy:haproxy /var/lib/haproxy

### CRON
RUN apt install -y cron && \
  install -m 777 /dev/null /var/log/cron.log

### Copy files
COPY haproxy.rsyslog.conf /etc/rsyslog.d/haproxy.conf
COPY haproxy.logrotate.conf /etc/logrotate.d/haproxy
COPY bootstrap.sh /

### File modes
RUN chmod 644 /etc/rsyslog.d/haproxy.conf && \
    chmod 644 /etc/logrotate.d/haproxy

USER haproxy
ENTRYPOINT ["bash", "-c", "/bootstrap.sh"]
