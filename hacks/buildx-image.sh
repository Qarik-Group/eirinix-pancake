#!/bin/bash

set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

docker buildx build --progress=plain \
  --platform linux/amd64,linux/arm/v7,linux/arm64 \
  -f Dockerfile \
  --push \
  --tag docker.io/drnic/eirinix-pancake \
  .
