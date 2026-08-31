#!/usr/bin/env bash
set -euo pipefail
IMAGE="${IMAGE:-container-interfacing-nestdaq-eicrecon:latest}"
docker run --rm -it \
  --name container-interfacing-nestdaq-eicrecon \
  --platform linux/amd64/v2 \
  --network host \
  -e DISPLAY=host.docker.internal:0 \
  "${IMAGE}"
