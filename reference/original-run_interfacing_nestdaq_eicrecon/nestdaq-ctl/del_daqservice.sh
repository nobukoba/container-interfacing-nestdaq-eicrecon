#!/bin/bash

echo "#########################################################"
echo "This script: $0"
echo "Script start time: " `date +"%Y-%m-%d %H:%M:%S"`
echo "#########################################################"
echo "redis-cli -n 0 keys 'daq_service:*' | xargs redis-cli del"
redis-cli -n 0 keys 'daq_service:*' | xargs redis-cli del
#echo "redis-cli -u redis://127.0.0.1:6379 flushall"
#redis-cli -u redis://127.0.0.1:6379 flushall
#echo "redis-cli -u redis://127.0.0.1:6379/0 flushdb"
#redis-cli -u redis://127.0.0.1:6379/0 flushdb
#echo "redis-cli -u redis://127.0.0.1:6379/1 flushdb"
#redis-cli -u redis://127.0.0.1:6379/1 flushdb
echo "redis-cli -u redis://127.0.0.1:6379/2 flushdb"
redis-cli -u redis://127.0.0.1:6379/2 flushdb 
