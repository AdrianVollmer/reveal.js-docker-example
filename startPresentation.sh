#!/usr/bin/env bash

ARGUMENT=${1}

source ./vars

if [[ -z "$BIND_IP" ]] ; then BIND_IP=127.0.0.1 ; fi

set -o errexit -o nounset -o pipefail
set -o monitor # Job Control, needed for "fg"
echo "Starting presentation"

INTERNAL=""
DOCKER_ARGS="-p ${BIND_IP}:8000:8000 -p ${BIND_IP}:35729:35729"

if [[ "${ARGUMENT}" == "internal" ]]; then
    INTERNAL=true
    DOCKER_ARGS=""
fi


# For dist/theme: Don't mount whole folder to not overwrite other files in folder (fonts, images, etc.)
CONTAINER_ID=$(podman run  --detach \
    $([[ -d docs/slides ]] && echo "-v $(pwd)/docs/slides:/reveal/docs/slides") \
    $([[ -d dist/theme ]] && for f in dist/theme/*.css; do echo "-v $(pwd)/${f}:/reveal/${f}"; done) \
    $([[ -d images ]] && echo "-v $(pwd)/images:/reveal/images") \
    $([[ -d resources ]] && echo "-v $(pwd)/resources:/resources") \
    $([[ -d plugin ]] && for dir in plugin/*/; do echo "-v $(pwd)/${dir}:/reveal/${dir}"; done) \
    -e TITLE="$TITLE" \
    -e THEME_CSS="$THEME_CSS" \
    ${DOCKER_ARGS} \
   docker.io/cloudogu/reveal.js:4.4.0-r3-dev)

# Print logs in background while waiting for container to come up
podman logs ${CONTAINER_ID}
podman attach ${CONTAINER_ID} &

if [[ "${INTERNAL}" == "true" ]]; then
    REVEAL_HOSTNAME=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_ID})
else
    REVEAL_HOSTNAME="${BIND_IP}"
fi

echo "Waiting for presentation to become available on http://${REVEAL_HOSTNAME}:8000"

until $(curl -s -o /dev/null --head --fail ${REVEAL_HOSTNAME}:8000); do sleep 1; done

# Bring container to foreground, so it can be stopped using ctrl+c.
# But don't output "podman attach ${CONTAINER_ID}"
fg > /dev/null
