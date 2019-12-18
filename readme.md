# Seamless reload for HAProxy

[![Build Method](https://img.shields.io/docker/cloud/automated/lodufqa/haproxy)](https://hub.docker.com/repository/docker/lodufqa/haproxy/builds)
[![Build Status](https://img.shields.io/docker/cloud/build/lodufqa/haproxy)](https://hub.docker.com/repository/docker/lodufqa/haproxy/builds)
[![GitHub Open Issues](https://img.shields.io/github/issues/amadeuszkryze/seamless-reload-haproxy)](https://github.com/amadeuszkryze/seamless-reload-haproxy/issues)
[![Release](https://img.shields.io/github/v/release/amadeuszkryze/seamless-reload-haproxy?include_prereleases)](https://github.com/amadeuszkryze/seamless-reload-haproxy/releases)

[![Docker build](http://dockeri.co/image/lodufqa/haproxy)](https://hub.docker.com/repository/docker/lodufqa/haproxy)

## Highly inspired by:
* https://github.com/million12/docker-haproxy
* https://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html

## Tags
Please specify tag when deploying for specific version.
Example:

* `lodufqa/haproxy:latest`
* `lodufqa/haproxy:2.0.10`

## Features:

  * Support for all features from HAProxy.
  * Based on official haproxy image.
  * Logging traffic and admin requsts to files.
  * Log rotation via logrotate to optimize space usage.
  * This container comes with inotify to monitor changes in HAProxy container and reloads HAProxy daemon.
  * Auto reload when: config, ssl certs or /etc/hosts changes.
  * The reload is done in a way that no connection is lost.
  * Ability to notify about reload success/fail over slack apihook.
  * Ability to be still operational if uploaded config is invalid.

## ENV variables

|Variable|Default Settings|Notes|
|:--|:--|:--|
|`HAPROXY_CONFIG`|`/etc/haproxy/haproxy.cfg`|If you mount your config to different location, simply edit it.|
|`HAPROXY_PORTS`|`80,443`|Comma separated ports|
|`HAPROXY_VALID_MSG`|Looks good - reload completed.|-|
|`HAPROXY_INVALID_MSG`|Invalid HAProxy configuration - check the logs, leaving old config..|-|
|`SLACK_URL`|empty|If provided reload status are populated to slack|

## Usage

### Basic

```bash
docker run -it --rm \
  -p 0.0.0.0:80:80 \
  -p 0.0.0.0:443:443 \
  --cap-add=NET_ADMIN \
  -v /haproxy_config:/haproxy_config \
  -v /haproxy_certs:/etc/ssl/private \
  lodufqa/haproxy:2.0.10
```

### Ansible

```
# Requires latest ansible devel
- name: "Install deps"
  become: True
  package:
    name: "{{ item }}"
    state: present
  with_items:
    - python-setuptools
    - python-docker

- name: "Get info of HAProxy container"
  docker_container_info:
    name: haproxy
  register: haproxy_container

- name: "Pull HAProxy"
  docker_image:
    name: lodufqa/haproxy
    force_source: yes
    source: pull
    state: present
    tag: "{{ haproxy_image_version | default('2.0.10') }}"

- name: "Docker run haproxy"
  when: haproxy_setup | default(false) | bool == True or (not haproxy_container.exists or haproxy_container.container.State.Status != 'running')
  become: True
  docker_container:
    container_default_behavior: compatibility
    image: "lodufqa/haproxy:{{ haproxy_image_version | default('2.0.10') }}"
    hostname: "{{ ansible_inventory }}"
    name: haproxy
    state: started
    restart_policy: unless-stopped
    ports:
      - 0.0.0.0:80:80 #HTTP
      - 0.0.0.0:443:443 #HTTPS
      - 0.0.0.0:1194:1194 #OPENVPN
      - 0.0.0.0:7999:7999 #ACME
      - 0.0.0.0:8000:8000 #HAProxyStats
      - 0.0.0.0:8003:8003 #HAProxy Exporter
      - 0.0.0.0:8080:8080 #Something else
    recreate: true
    volumes:
      - /haproxy_config:/haproxy_config
      - /haproxy_certs:/etc/ssl/private
    capabilities:
      - NET_ADMIN
    env:
      HAPROXY_CONFIG: /haproxy_config/haproxy.cfg
      HAPROXY_PORTS: 80,443,1194,7999,8000,8080 #This is important.
      SLACK_URL: https://slackurl.com/whaterevisyourslackurlbutkeepitsecret
```

### Sample config
```
global
    ### Process management and security
    log 127.0.0.1:514 local0 info
    daemon
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    pidfile /var/run/haproxy.pid

    ### SSL https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.5&config=modern
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets

    ssl-default-server-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets

    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    ### Performance tuning
    maxconn 50000
    maxsslconn 50000
    maxconnrate 5000
    maxsslrate 5000
    maxsessrate 4000

    spread-checks 33
    max-spread-checks 10
    tune.chksize 32768
    tune.ssl.lifetime 300
    tune.ssl.default-dh-param 2048

defaults
    log global
    mode http
    option dontlognull
    option httplog
    option abortonclose
    option http-keep-alive
    option forwardfor
    option redispatch
    option allbackups
    option http-use-htx
    retries 3

    timeout connect 60s
    timeout client 60s
    timeout server 120s
    timeout queue 120s
    timeout http-request 60s
    timeout http-keep-alive 60s

    errorfile 400 /etc/haproxy/errors-custom/400.http
    errorfile 403 /etc/haproxy/errors-custom/403.http
    errorfile 405 /etc/haproxy/errors-custom/403.http
    errorfile 408 /etc/haproxy/errors-custom/408.http
    errorfile 500 /etc/haproxy/errors-custom/500.http
    errorfile 502 /etc/haproxy/errors-custom/502.http
    errorfile 503 /etc/haproxy/errors-custom/503.http
    errorfile 504 /etc/haproxy/errors-custom/504.http

frontend MAIN_FRONTNED
    ### BINDS
    bind *:80 alpn h2,http/1.1 tfo
    bind *:443 ssl crt acme.test.com.pem alpn h2,http/1.1 tfo

    ### BLOCKED IPS
    acl BLOCKED_IP src 1.2.3.4
    http-request deny if BLOCKED_IP

    ### ACME letsencrypt
    acl ACME_ACL path_beg -i /.well-known/acme-challenge/

    ### Restricted ACL
    acl RESTRICTED_IP_ACL src 10.0.0.0/8

    ### X-Forwarded-* headers
    http-request add-header X-Forwarded-Host %[req.hdr(host)]
    http-request add-header X-Forwarded-Server %[req.hdr(host)]
    http-request add-header X-Forwarded-Dst-Port %[dst_port]
    http-request add-header X-Forwarded-Src-Port %[src_port]
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request add-header X-Custom-SSL-Version %sslv if { ssl_fc }
    http-request add-header X-Custom-SSL-Cipher %sslc if { ssl_fc }

    ### HTTPS redirect if HTTP
    redirect scheme https code 301 if !{ ssl_fc }

    use_backend XXX

backend XXX
    ...

backend ACME
    server local localhost:7999

frontend STATS
    bind *:8404
    http-request use-service prometheus-exporter if { path /metrics }
    stats enable
    stats uri /stats
    stats refresh 10s

```
