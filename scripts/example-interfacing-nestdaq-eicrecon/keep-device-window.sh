#!/usr/bin/env bash
set -u

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <label> <command> [args...]" >&2
  exit 2
fi

label="$1"
shift

"$@"
status=$?

echo
echo "========================================"
echo "${label} exited with status: ${status}"
echo "This tmux window is kept for debugging."
echo "========================================"
echo

# Keep the tmux pane alive even after the device has exited.
# The user can inspect the final log and run diagnostic commands here.
exec bash
