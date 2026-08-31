#!/usr/bin/env bash
set -euo pipefail

DAQSERVICE_URI=' --registry-uri tcp://127.0.0.1:6379/0'
METRICS_URI=' --metrics-uri tcp://127.0.0.1:6379/1'
CONFIG_URI=' --parameter-config-uri tcp://127.0.0.1:6379/2'
NESTDAQ_HOST_IP="${NESTDAQ_HOST_IP:-127.0.0.1}"

if [[ "${1:-}" =~ ^fairmq- ]]; then
  BINDIR=""
else
  BINDIR="/opt/spadi/bin/"
fi

PLUGIN_LIBDIR="/opt/spadi/lib64"
[[ -d "${PLUGIN_LIBDIR}" ]] || PLUGIN_LIBDIR="/opt/spadi/lib"

PLUGIN_SEARCH_PATH=" -S '<${PLUGIN_LIBDIR}'"
DAQSERVICE_PLUGIN=" -P daq_service"
METRICS_PLUGIN=" -P metrics"
CONFIG_PLUGIN=" -P parameter_config"

run_device() {
  local cmd="${BINDIR}$1"
  shift
  local opts=""
  opts+="${PLUGIN_SEARCH_PATH}"
  opts+="${DAQSERVICE_PLUGIN}"
  opts+="${METRICS_PLUGIN}"
  opts+="${CONFIG_PLUGIN}"
  opts+="${DAQSERVICE_URI}"
  opts+="${METRICS_URI}"
  opts+="${CONFIG_URI}"
  opts+=" --host-ip ${NESTDAQ_HOST_IP}"
  opts+=" --severity debug4"

  echo "${cmd} $* ${opts}"
  eval "\"${cmd}\" \"$@\" ${opts}"
}

run_device "$@"
