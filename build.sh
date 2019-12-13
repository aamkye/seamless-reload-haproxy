#!/usr/bin/env bash

set -uex

GIT_TAG="$(git describe --tags --abbrev=0)"
GIT_SHA="$(git log --pretty=format:'%h' -n 1)"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
GIT_DATE="$(git log --pretty=format:'%cI' -n 1)"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

docker build --file=dockerfile --tag=lodufqa/haproxy:${GIT_TAG} \
  --build-arg GIT_TAG="${GIT_TAG:-''}" \
  --build-arg GIT_SHA="${GIT_SHA:-''}" \
  --build-arg GIT_BRANCH="${GIT_BRANCH:-''}" \
  --build-arg GIT_DATE="${GIT_DATE:-''}" \
  --build-arg BUILD_DATE="${BUILD_DATE:-''}" \
  --no-cache .
