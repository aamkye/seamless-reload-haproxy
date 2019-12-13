# [WIP] Seamless reload HAProxy (SRH)

[![Build Status](https://travis-ci.org/amadeuszkryze/seamless-reload-haproxy.svg?branch=master)](https://travis-ci.org/amadeuszkryze/seamless-reload-haproxy)
[![GitHub Open Issues](https://img.shields.io/github/issues/amadeuszkryze/seamless-reload-haproxy.svg)](https://github.com/amadeuszkryze/seamless-reload-haproxy/issues)
[![Stars](https://img.shields.io/github/stars/amadeuszkryze/seamless-reload-haproxy.svg?style=social&label=Stars)]()
[![Fork](https://img.shields.io/github/forks/amadeuszkryze/seamless-reload-haproxy.svg?style=social&label=Fork)]()
[![Release](https://img.shields.io/github/release/amadeuszkryze/seamless-reload-haproxy.svg)](http://microbadger.com/images/lodufqa/haproxy.svg)

[![Docker build](http://dockeri.co/image/lodufqa/haproxy)](https://hub.docker.com/repository/docker/lodufqa/haproxy)

## Highly inspired by:
* https://github.com/million12/docker-haproxy
* https://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html

### Tags
Please specify tag when deploying for specific version.
Example:

`lodufqa/haproxy:2.0.10`

## Features:

  * Support for all features from HAProxy
  * Based on official haproxy image
  * Logging traffic and admin requsts to files
  * Log rotation via logrotate to optimize space usage.
  * Auto restart when: config, ssl certs or /etc/hosts changes. This container comes with inotify to monitor changes in HAProxy all previous things and reload HAProxy daemon. The reload is done in a way that no connection is lost.

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

*[from file](./ansible_example.yml)*
