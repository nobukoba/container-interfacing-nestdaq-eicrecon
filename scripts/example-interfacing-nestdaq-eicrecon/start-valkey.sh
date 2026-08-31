#!/usr/bin/env bash
set -euo pipefail

PORT="${VALKEY_PORT:-6379}"
RTS_MODULE="${REDISTIMESERIES_MODULE:-/opt/spadi/lib/redistimeseries.so}"
PIDFILE="/tmp/spadi-valkey-${PORT}.pid"
LOGFILE="/tmp/spadi-valkey-${PORT}.log"

if [[ ! -r "${RTS_MODULE}" ]]; then
  echo "RedisTimeSeries module not found: ${RTS_MODULE}" >&2
  exit 1
fi

# Reuse an already-running local Valkey instance when available.
if valkey-cli -h 127.0.0.1 -p "${PORT}" ping >/dev/null 2>&1; then
  echo "Valkey is already running on 127.0.0.1:${PORT}."
else
  rm -f "${PIDFILE}"

  valkey-server \
    --bind 127.0.0.1 \
    --port "${PORT}" \
    --loadmodule "${RTS_MODULE}" \
    --daemonize yes \
    --pidfile "${PIDFILE}" \
    --logfile "${LOGFILE}" \
    --dir /tmp

  # The daemon may need a short time before accepting connections.
  for _ in $(seq 1 50); do
    if valkey-cli -h 127.0.0.1 -p "${PORT}" ping >/dev/null 2>&1; then
      break
    fi

    if [[ -f "${PIDFILE}" ]]; then
      pid="$(cat "${PIDFILE}" 2>/dev/null || true)"
      if [[ -n "${pid}" ]] && ! kill -0 "${pid}" 2>/dev/null; then
        echo "Valkey terminated during startup." >&2
        [[ -f "${LOGFILE}" ]] && cat "${LOGFILE}" >&2
        exit 1
      fi
    fi

    sleep 0.1
  done
fi

if ! valkey-cli -h 127.0.0.1 -p "${PORT}" ping; then
  echo "Could not start Valkey on 127.0.0.1:${PORT}." >&2
  [[ -f "${LOGFILE}" ]] && cat "${LOGFILE}" >&2
  exit 1
fi

# Fail early if the TimeSeries module was not loaded correctly.
if ! valkey-cli -h 127.0.0.1 -p "${PORT}" COMMAND INFO TS.ADD | grep -qi 'ts.add'; then
  echo "RedisTimeSeries TS.ADD command is unavailable." >&2
  valkey-cli -h 127.0.0.1 -p "${PORT}" MODULE LIST >&2 || true
  [[ -f "${LOGFILE}" ]] && cat "${LOGFILE}" >&2
  exit 1
fi

echo "RedisTimeSeries TS.ADD is available."
