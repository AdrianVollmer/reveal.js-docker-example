#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# When updating, also update in Jenkinsfile. Or use this script in Jenkins
HEADLESS_CHROME_IMAGE='docker.io/yukinying/chrome-headless-browser:96.0.4662.6'

podman build -t reveal .

container=$(podman run --rm -d reveal)
address=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${container}")
pdf=$(mktemp --suffix=.pdf)

sleep 1

rm "${pdf}" || true

set -x
podman run -v /tmp:/tmp -u "$(id -u)" --entrypoint= -it --shm-size=4G ${HEADLESS_CHROME_IMAGE} \
  /usr/bin/google-chrome-unstable --headless --no-sandbox --disable-gpu --print-to-pdf="${pdf}" --run-all-compositor-stages-before-draw  --virtual-time-budget=10000 \
  "http://${address}:8080/?print-pdf"

ls -lah "${pdf}"

podman rm -f "${container}"
