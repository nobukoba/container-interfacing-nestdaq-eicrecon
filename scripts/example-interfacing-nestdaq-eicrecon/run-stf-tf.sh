#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

SESSION="nestdaq"
TMUX_SOCKET="spadi-sif"
CONTAINER_PATH="/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CONTAINER_LD_LIBRARY_PATH="/opt/spadi/lib:/opt/spadi/lib64"
TMUX=(tmux -L "${TMUX_SOCKET}")

echo "Starting Valkey..."
./start-valkey.sh

echo "Setting NestDAQ parameters..."
./mq-param.sh

echo "Setting NestDAQ topology..."
./topology-stf-tf.sh

if "${TMUX[@]}" has-session -t "${SESSION}" 2>/dev/null; then
  echo "Removing existing tmux session: ${SESSION}"
  "${TMUX[@]}" kill-session -t "${SESSION}"
fi

# Use a dedicated tmux server for the container. This prevents an existing
# host-side tmux server from launching panes with the host environment.
# Keep one permanent control shell alive so the session remains available
# even if all NestDAQ processes terminate.
"${TMUX[@]}" new-session -d \
  -s "${SESSION}" \
  -n control \
  -c "${SCRIPT_DIR}" \
  "exec env PATH=${CONTAINER_PATH} LD_LIBRARY_PATH=${CONTAINER_LD_LIBRARY_PATH} bash"

# Keep finished device panes visible for debugging.
"${TMUX[@]}" set-window-option -g -t "${SESSION}" remain-on-exit on
"${TMUX[@]}" set-option -t "${SESSION}" allow-rename off

echo "Starting daq-webctl..."
"${TMUX[@]}" new-window \
  -t "${SESSION}" \
  -n webctl \
  -c "${SCRIPT_DIR}" \
  "exec env PATH=${CONTAINER_PATH} LD_LIBRARY_PATH=${CONTAINER_LD_LIBRARY_PATH} /opt/spadi/bin/daq-webctl --http-uri http://0.0.0.0:8080"

for runID in 0 1 2; do
  echo "Starting STFBFilePlayer ${runID}"
  "${TMUX[@]}" new-window \
    -t "${SESSION}" \
    -n "STF${runID}" \
    -c "${SCRIPT_DIR}" \
    "env PATH=${CONTAINER_PATH} LD_LIBRARY_PATH=${CONTAINER_LD_LIBRARY_PATH} ./keep-device-window.sh STFBFilePlayer ./start_device.sh STFBFilePlayer"
  sleep 0.2
done

echo "Starting TimeFrameBuilder"
"${TMUX[@]}" new-window \
  -t "${SESSION}" \
  -n TFB \
  -c "${SCRIPT_DIR}" \
  "env PATH=${CONTAINER_PATH} LD_LIBRARY_PATH=${CONTAINER_LD_LIBRARY_PATH} ./keep-device-window.sh TimeFrameBuilder ./start_device.sh TimeFrameBuilder"

echo
echo "NestDAQ tmux windows:"
"${TMUX[@]}" list-windows -t "${SESSION}"
echo
echo "The control window is kept alive permanently."
echo "STF/TFB windows also remain visible after their device process exits."
echo "Dedicated tmux socket: ${TMUX_SOCKET}"
echo
echo "Attaching to tmux session: ${SESSION}"
if "${TMUX[@]}" list-windows -t "${SESSION}" -F '#W' | grep -qx webctl; then
  "${TMUX[@]}" select-window -t "${SESSION}:webctl"
else
  "${TMUX[@]}" select-window -t "${SESSION}:control"
fi
exec tmux -L "${TMUX_SOCKET}" attach-session -t "${SESSION}"
