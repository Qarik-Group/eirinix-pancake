#!/bin/bash

set -eu

# USAGE:
#   export SERVICE_ACCOUNT=service-account
#   ./hacks/kpack-branch.sh | kubectl apply -f -
#
# To watch Cloud Native Buildpack logs in progress:
#   logs -image eirinix-pancake

: "${SERVICE_ACCOUNT:?required name of serviceAccount with Docker Registry + Git secrets}"

KPACK_IMAGE=${KPACK_IMAGE:-eirinix-pancake}
KPACK_BUILDER_IMAGE=${KPACK_BUILDER_IMAGE:-cloudfoundry/cnb:bionic}
KPACK_CACHE_SIZE=${KPACK_CACHE_SIZE:-} # set "1.5Gi" to enable cache

# guess that local *nix user == docker hub username; probably wrong though for many people
DOCKER_REGISTRY_ROOT=${DOCKER_REGISTRY_ROOT:-$(whoami)}
DOCKER_IMAGE=${DOCKER_IMAGE:-eirinix-pancake}

GIT_BRANCH=${GIT_BRANCH:-$(git branch | grep '^\*' | awk '{print $2}')}
GIT_REMOTE=${GIT_REMOTE:-$(git remote -v | grep -v "^origin" | head -n1 | awk '{print $2}')}
# convert git@github.com:drnic/eirinix-pancake.git -> https://github.com/drnic/eirinix-pancake.git
GIT_REMOTE=${GIT_REMOTE//:/\/}
GIT_REMOTE=${GIT_REMOTE//git@/https:\/\/}

# End result looks similar to:
# apiVersion: build.pivotal.io/v1alpha1
# kind: Builder
# metadata:
#   name: "eirinix-pancake-builder"
# spec:
#   image: "cloudfoundry/cnb:bionic"
#   updatePolicy: polling
# ---
# apiVersion: build.pivotal.io/v1alpha1
# kind: Image
# metadata:
#   name: "eirinix-pancake"
# spec:
#   builder:
#     name: "eirinix-pancake-builder"
#     kind: Builder
#   serviceAccount: service-account
#   cacheSize: "1.5Gi"
#   source:
#     git:
#       url: "https://github.com/drnic/eirinix-pancake.git"
#       revision: "generate-kpack-image"
#   tag: "drnic/eirinix-pancake:generate-kpack-image"

cat <<-YAML
apiVersion: build.pivotal.io/v1alpha1
kind: Builder
metadata:
  name: "${KPACK_IMAGE}-builder"
spec:
  image: "${KPACK_BUILDER_IMAGE}"
  updatePolicy: polling
---
apiVersion: build.pivotal.io/v1alpha1
kind: Image
metadata:
  name: "${KPACK_IMAGE}"
spec:
  builder:
    name: "${KPACK_IMAGE}-builder"
    kind: Builder
  serviceAccount: "${SERVICE_ACCOUNT}"
  ${KPACK_CACHE_SIZE:+cacheSize: "$KPACK_CACHE_SIZE"}
  source:
    git:
      url: "${GIT_REMOTE}"
      revision: "${GIT_BRANCH}"
  tag: "${DOCKER_REGISTRY_ROOT}/${DOCKER_IMAGE}:${GIT_BRANCH}"
YAML
