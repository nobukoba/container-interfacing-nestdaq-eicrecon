#!/bin/bash

session_name=$1

echo "#########################################################"
echo "This script: $0 $1"
echo "Script start time: " `date +"%Y-%m-%d %H:%M:%S"`
echo "#########################################################"

if [ "$1" == "" ]; then
    echo "Usage: $0 < session name >"
    echo ""
    echo "Select session name from below"
    tmux ls
else
    echo "tmux kill-session -t $1"
    tmux kill-session -t $1
fi
