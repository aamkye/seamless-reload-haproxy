# [WIP] Seamless reload HAProxy (SRH)

[![Build Method](https://img.shields.io/docker/cloud/automated/lodufqa/haproxy)](https://travis-ci.org/amadeuszkryze/seamless-reload-haproxy)
[![Build Status](https://img.shields.io/docker/cloud/build/lodufqa/haproxy)](https://travis-ci.org/amadeuszkryze/seamless-reload-haproxy)
[![GitHub Open Issues](https://img.shields.io/github/issues/amadeuszkryze/seamless-reload-haproxy)](https://github.com/amadeuszkryze/seamless-reload-haproxy/issues)
[![Release](https://img.shields.io/github/v/release/amadeuszkryze/seamless-reload-haproxy?include_prereleases)](https://github.com/amadeuszkryze/seamless-reload-haproxy/releases)

[![Docker build](http://dockeri.co/image/lodufqa/haproxy)](https://hub.docker.com/repository/docker/lodufqa/haproxy)

## Highly inspired by:
* https://github.com/million12/docker-haproxy
* https://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html

## Tags
Please specify tag when deploying for specific version.
Example:

`lodufqa/haproxy:2.0.10`

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

### Ansible usage

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
