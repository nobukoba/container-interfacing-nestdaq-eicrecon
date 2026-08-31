#!/usr/bin/env bash
set -euo pipefail

SESSION="nestdaq"

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  echo "Stopping tmux session: ${SESSION}"
  tmux kill-session -t "${SESSION}"
else
  echo "tmux session is not running: ${SESSION}"
fi
