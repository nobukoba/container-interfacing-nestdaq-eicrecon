#!/usr/bin/env bash
set -euo pipefail

PORT="${VALKEY_PORT:-6379}"
RTS_MODULE="${REDISTIMESERIES_MODULE:-/opt/spadi/lib/redistimeseries.so}"

if [[ ! -r "${RTS_MODULE}" ]]; then
  echo "RedisTimeSeries module not found: ${RTS_MODULE}" >&2
  exit 1
fi

valkey-server \
  --bind 127.0.0.1 \
  --port "${PORT}" \
  --loadmodule "${RTS_MODULE}" \
  --daemonize yes \
  --dir /tmp

valkey-cli -p "${PORT}" ping

# Fail early if the TimeSeries module was not loaded correctly.
if ! valkey-cli -p "${PORT}" COMMAND INFO TS.ADD | grep -qi 'ts.add'; then
  echo "RedisTimeSeries TS.ADD command is unavailable." >&2
  valkey-cli -p "${PORT}" MODULE LIST >&2 || true
  exit 1
fi

echo "RedisTimeSeries TS.ADD is available."
