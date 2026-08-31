#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-container-interfacing-nestdaq-eicrecon:latest}"
WORK_DIR="${WORK_DIR:-$PWD/work}"

mkdir -p "${WORK_DIR}"

docker run --rm -it \
  --name container-interfacing-nestdaq-eicrecon \
  --platform linux/amd64/v2 \
  --network host \
  -v "${WORK_DIR}:/work" \
  -e DISPLAY=host.docker.internal:0 \
  "${IMAGE}"
