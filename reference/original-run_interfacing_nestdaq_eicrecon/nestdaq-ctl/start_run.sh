#!/bin/bash

function state_consistency_wait() {
    ret=`redis-cli -n 0 keys '*' | grep 'health' | grep 'health'`
    ret=`echo "$ret" | head -1`
    first_dev=${ret%:health}
    first_dev=${first_dev#daq_service:*:}

    ret=`redis-cli -n 0 keys '*' | grep 'health' `
    #echo "$ret"
    for str in $ret
    do
	dev=${str%:health}
	dev=${dev#daq_service:*:}
	#echo "$dev"
	for i in {1..10}
	do
	    first_dev_state=`redis-cli -n 1 hget metrics:state ${first_dev}`
	    state=`redis-cli -n 1 hget metrics:state ${dev}`
	    #echo $state
	    if [ "$state" = "" ]; then
		echo "Null state"
		sleep 1
		continue
	    fi
	    if [ "$state" = "$first_dev_state" ]; then
		break
	    else
		#echo ""
		#echo "Waiting..."
		#echo "Device: $dev"
		#echo "Required state: $req_state"
 		#echo "Current state: $state..."
		sleep 1
	    fi
	done
	if [ "$i" = "10" ]; then
	    echo "Time out: states are not consistent."
	    break
	fi
    done
    consistent_state="$first_dev_state"
}

function state_wait() {
    req_state=$1
    state_consistency_wait
    if [ ! "$req_state" = "$consistent_state" ]; then
	echo "states are not consistent!!!"
    fi
}

function start_run() {
    redis-cli  'PUBLISH' 'daqctl' '{"command": "change_state", "value": "CONNECT",    "services": ["all"], "instances": ["all"] }' > /dev/null
    state_wait 'DEVICE READY'
    redis-cli  'PUBLISH' 'daqctl' '{"command": "change_state", "value": "INIT TASK",  "services": ["all"], "instances": ["all"] }'  > /dev/null
    state_wait 'READY'
    redis-cli  'PUBLISH' 'daqctl' '{"command": "change_state", "value": "RUN",        "services": ["all"], "instances": ["all"] }' > /dev/null
    state_wait 'RUNNING'
    run_num=`redis-cli -n 0 get run_info:run_number`
    echo ""
    echo ""
    echo "New run started..."
    echo "Current run number: $run_num"
    echo "Run start time: "`date +"%Y-%m-%d %H:%M:%S"`
}

script_name=$0
echo "#########################################################"
echo "This script: $script_name"
echo "Script start time: " `date +"%Y-%m-%d %H:%M:%S"`
echo "#########################################################"
start_run
