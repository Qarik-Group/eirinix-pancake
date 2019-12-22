#!/bin/bash

set -eu

DOCKER_PREFIX=${DOCKER_PREFIX:-docker.io/starkandwayne}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

docker buildx build --progress=plain \
  --platform linux/amd64,linux/arm/v7,linux/arm64 \
  -f Dockerfile \
  --push \
  --tag "$DOCKER_PREFIX/eirinix-pancake" \
  .
