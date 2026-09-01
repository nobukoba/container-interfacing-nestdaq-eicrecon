#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-container-interfacing-nestdaq-eicrecon:latest}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

docker run --rm -it \
  --name container-interfacing-nestdaq-eicrecon \
  --platform linux/amd64 \
  --network host \
  -v "${WORKSPACE_DIR}:/workspace" \
  -e DISPLAY=host.docker.internal:0 \
  "${IMAGE}"
