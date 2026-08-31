#!/bin/bash

echo "#########################################################"
echo "This script: $0"
echo "Script start time: " `date +"%Y-%m-%d %H:%M:%S"`
echo "#########################################################"
echo "pkill -HUP start_device.sh"
pkill -HUP start_device.sh
