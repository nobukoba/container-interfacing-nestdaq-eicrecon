#!/usr/bin/env bash
set -euo pipefail

SERVER="redis://127.0.0.1:6379/2"
RAWDATA_ROOT="${SPADI_EXAMPLE_RAWDATA:-/opt/spadi/example_rawdata}/raris_ac_lgad_202603"

if command -v valkey-cli >/dev/null 2>&1; then
  CLI=valkey-cli
elif command -v redis-cli >/dev/null 2>&1; then
  CLI=redis-cli
else
  echo "Neither valkey-cli nor redis-cli was found." >&2
  exit 1
fi

param() {
  echo "${CLI} -u ${SERVER} hset parameters:$1 ${*:2}"
  "${CLI}" -u "${SERVER}" hset "parameters:$1" "${@:2}"
}

"${CLI}" -u "${SERVER}" flushdb

# Example RAW-data inputs.
param STFBFilePlayer-0 in-file "/opt/spadi/example_rawdata/raris_ac_lgad_202603/00/partial_run000021.dat"
param STFBFilePlayer-1 in-file "/opt/spadi/example_rawdata/raris_ac_lgad_202603/01/partial_run000021.dat"
param STFBFilePlayer-2 in-file "/opt/spadi/example_rawdata/raris_ac_lgad_202603/02/partial_run000021.dat"

param STFBuilder-0 max-hbf 4
param STFBuilder-1 max-hbf 4
param STFBuilder-2 max-hbf 4

param TimeFrameBuilder-0 decimation-factor 1000 discard-output false enable-uds false
