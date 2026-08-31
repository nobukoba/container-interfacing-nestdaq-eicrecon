#!/bin/bash

run_number=`redis-cli -n 0 get run_info:run_number`
latest_run_number=`redis-cli -n 0 get run_info:latest_run_number`
echo "#########################################################"
echo "This script: $0"
echo "Script start time: " `date +"%Y-%m-%d %H:%M:%S"`
echo "#########################################################"
echo "Nest run number:   $run_number" 
echo "Latest run number: $latest_run_number" 
