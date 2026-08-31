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

# Create a temporary bootstrap window first.  This lets us set
# remain-on-exit before any NestDAQ process is launched, so a failed
# device window remains visible instead of disappearing immediately.
tmux new-session -d \
  -s "${SESSION}" \
  -n bootstrap \
  -c "${SCRIPT_DIR}"

tmux set-option -t "${SESSION}" remain-on-exit on
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

# The bootstrap window is no longer needed.
tmux kill-window -t "${SESSION}:bootstrap"

echo
echo "NestDAQ tmux windows:"
tmux list-windows -t "${SESSION}"
echo
echo "STF/TFB windows stay open after their device process exits."
echo "Select the window to inspect the final log and exit status."
echo
echo "Attaching to tmux session: ${SESSION}"
tmux select-window -t "${SESSION}:webctl"
exec tmux attach-session -t "${SESSION}"
