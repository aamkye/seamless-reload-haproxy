#!/usr/bin/env bash

export PS4='+ $0:$LINENO '
set -uex

# build with docker if exists, if not use podman
if command -v docker &> /dev/null; then
  DOCKER_CMD="docker"
else
  DOCKER_CMD="podman"
fi

GIT_TAG="$(git describe --tags --abbrev=0)"
GIT_SHA="$(git log --pretty=format:'%h' -n 1)"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
GIT_DATE="$(git log --pretty=format:'%cI' -n 1)"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

${DOCKER_CMD} build --file=dockerfile --tag=lodufqa/haproxy:${GIT_TAG} \
  --platform linux/amd64 \
  --build-arg GIT_TAG="${GIT_TAG:-''}" \
  --build-arg GIT_SHA="${GIT_SHA:-''}" \
  --build-arg GIT_BRANCH="${GIT_BRANCH:-''}" \
  --build-arg GIT_DATE="${GIT_DATE:-''}" \
  --build-arg BUILD_DATE="${BUILD_DATE:-''}" \
  --no-cache .
