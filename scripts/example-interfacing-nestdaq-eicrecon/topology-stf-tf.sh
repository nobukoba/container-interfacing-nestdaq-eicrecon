#!/usr/bin/env bash
set -euo pipefail

SERVER="redis://127.0.0.1:6379/0"

if command -v valkey-cli >/dev/null 2>&1; then
  CLI=valkey-cli
elif command -v redis-cli >/dev/null 2>&1; then
  CLI=redis-cli
else
  echo "Neither valkey-cli nor redis-cli was found." >&2
  exit 1
fi

endpoint() {
  echo "${CLI} -u ${SERVER} hset daq_service:topology:endpoint:$1:$2 ${*:3}"
  "${CLI}" -u "${SERVER}" hset "daq_service:topology:endpoint:$1:$2" "${@:3}"
}

link() {
  echo "${CLI} -u ${SERVER} set daq_service:topology:link:$1:$2,$3:$4 none"
  "${CLI}" -u "${SERVER}" set "daq_service:topology:link:$1:$2,$3:$4" none
}

endpoint STFBFilePlayer out type push method connect autoSubChannel true
endpoint TimeFrameBuilder in type pull method bind address tcp://127.0.0.1:5500
endpoint TimeFrameBuilder out type push method bind address tcp://127.0.0.1:5501 enable-uds false

link STFBFilePlayer out TimeFrameBuilder in
