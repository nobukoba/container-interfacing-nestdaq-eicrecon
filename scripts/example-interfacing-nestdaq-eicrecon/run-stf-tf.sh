#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

SESSION="nestdaq"

echo "Starting Valkey..."
./start-valkey.sh

echo "Setting NestDAQ parameters..."
./mq-param.sh

echo "Setting NestDAQ topology..."
./topology-stf-tf.sh

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  echo "Removing existing tmux session: ${SESSION}"
  tmux kill-session -t "${SESSION}"
fi

# Keep one permanent control shell alive. This guarantees that the tmux
# session remains available even if all NestDAQ processes terminate.
tmux new-session -d \
  -s "${SESSION}" \
  -n control \
  -c "${SCRIPT_DIR}" \
  "exec bash"

# Keep finished device panes visible for debugging.
tmux set-window-option -g -t "${SESSION}" remain-on-exit on
tmux set-option -t "${SESSION}" allow-rename off

echo "Starting daq-webctl..."
tmux new-window \
  -t "${SESSION}" \
  -n webctl \
  -c "${SCRIPT_DIR}" \
  "exec daq-webctl --http-uri http://0.0.0.0:8080"

for runID in 0 1 2; do
  echo "Starting STFBFilePlayer ${runID}"
  tmux new-window \
    -t "${SESSION}" \
    -n "STF${runID}" \
    -c "${SCRIPT_DIR}" \
    "./keep-device-window.sh STFBFilePlayer ./start_device.sh STFBFilePlayer"
  sleep 0.2
done

echo "Starting TimeFrameBuilder"
tmux new-window \
  -t "${SESSION}" \
  -n TFB \
  -c "${SCRIPT_DIR}" \
  "./keep-device-window.sh TimeFrameBuilder ./start_device.sh TimeFrameBuilder"

echo
echo "NestDAQ tmux windows:"
tmux list-windows -t "${SESSION}"
echo
echo "The control window is kept alive permanently."
echo "STF/TFB windows also remain visible after their device process exits."
echo
echo "Attaching to tmux session: ${SESSION}"
if tmux list-windows -t "${SESSION}" -F '#W' | grep -qx webctl; then
  tmux select-window -t "${SESSION}:webctl"
else
  tmux select-window -t "${SESSION}:control"
fi
exec tmux attach-session -t "${SESSION}"
