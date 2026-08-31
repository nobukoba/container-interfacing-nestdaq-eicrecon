#!/bin/bash


ret=`redis-cli -n 0 keys '*' | grep 'health' `
#echo "$ret"
echo "#########################################################"
echo "This script: $0"
echo "Script start time: " `date +"%Y-%m-%d %H:%M:%S"`
echo "#########################################################"
run_number=`redis-cli -n 0 get run_info:run_number`
latest_run_number=`redis-cli -n 0 get run_info:latest_run_number`
echo "Nest run number:   $run_number" 
echo "Latest run number: $latest_run_number" 
echo ""
echo "State | FairMQ device"
echo "---------------------"
for str in $ret
do
    dev=${str%:health}
    dev=${dev#daq_service:*:}
    state=`redis-cli -n 1 hget metrics:state ${dev}`
    echo "$state | $dev"
done
