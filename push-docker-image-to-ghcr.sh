#!/usr/bin/env bash
set -euo pipefail
OWNER="${GHCR_OWNER:-nobukoba}"
IMAGE_NAME="${IMAGE_NAME:-spadi-interfacing-nestdaq-eicrecon}"
STAMP="${1:-$(docker images "${IMAGE_NAME}" --format '{{.Tag}}' | grep -E '^[0-9]{8}-[0-9]{4}utc$' | sort -r | head -n1)}"
[[ -n "${STAMP}" ]] || { echo "No YYYYMMDD-HHMMutc tag found."; exit 1; }

REMOTE="ghcr.io/${OWNER}/${IMAGE_NAME}"
docker tag "${IMAGE_NAME}:${STAMP}" "${REMOTE}:${STAMP}"
docker tag "${IMAGE_NAME}:${STAMP}" "${REMOTE}:latest"
docker push "${REMOTE}:${STAMP}"
docker push "${REMOTE}:latest"
