#!/usr/bin/env bash

ARGUMENT=${1}

source ./vars

if [[ -z "$BIND_IP" ]] ; then BIND_IP=127.0.0.1 ; fi
if [[ -z "$PORT" ]] ; then PORT=8000 ; fi

set -o errexit -o nounset -o pipefail
set -o monitor # Job Control, needed for "fg"
echo "Starting presentation"

INTERNAL=""
DOCKER_ARGS="-p ${BIND_IP}:${PORT}:8000 -p ${BIND_IP}:35729:35729"

if [[ "${ARGUMENT}" == "internal" ]]; then
    INTERNAL=true
    DOCKER_ARGS=""
fi

CONTAINER_FILE="./.container_id"
CONTAINER_ID="$(cat "${CONTAINER_FILE}" 2> /dev/null||true)"

if [[ -n "$CONTAINER_ID" ]] && podman container exists "${CONTAINER_ID}" ; then
    echo "Starting container: ${CONTAINER_ID}"
    podman start "${CONTAINER_ID}"
else

    echo "Creating new container..."
    # For dist/theme: Don't mount whole folder to not overwrite other files in folder (fonts, images, etc.)
    CONTAINER_ID=$(podman run  \
        $([[ -d docs/slides ]] && echo "-v $(pwd)/docs/slides:/reveal/docs/slides") \
        $([[ -d dist/theme ]] && for f in dist/theme/*.css; do echo "-v $(pwd)/${f}:/reveal/${f}"; done) \
        $([[ -d images ]] && echo "-v $(pwd)/images:/reveal/images") \
        $([[ -d resources ]] && echo "-v $(pwd)/resources:/resources") \
        $([[ -d plugin ]] && for dir in plugin/*/; do echo "-v $(pwd)/${dir}:/reveal/${dir}"; done) \
        -e TITLE="$TITLE" \
        -e THEME_CSS="$THEME_CSS" \
        ${DOCKER_ARGS} \
       docker.io/cloudogu/reveal.js:4.4.0-r3-dev)

    echo ${CONTAINER_ID} > "${CONTAINER_FILE}"
fi

# Print logs in background while waiting for container to come up
podman logs ${CONTAINER_ID}

if [[ "${INTERNAL}" == "true" ]]; then
    REVEAL_HOSTNAME=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_ID})
else
    REVEAL_HOSTNAME="${BIND_IP}"
fi

echo "Waiting for presentation to become available on http://${REVEAL_HOSTNAME}:${PORT}"

until $(curl -s -o /dev/null --head --fail ${REVEAL_HOSTNAME}:${PORT}); do sleep 1; done

control_c()
{
  podman stop "${CONTAINER_ID}" || true
  exit 0
}

trap control_c SIGINT

echo "Ready. Press CTRL-C to quit."

read -r -d '' _
