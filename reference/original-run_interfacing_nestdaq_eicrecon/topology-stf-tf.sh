#!/bin/bash

#host=127.0.0.1
#port=6379
#db=0
server=redis://127.0.0.1:6379/0

#function config_endpoint () {
function endpoint () {
  # Usage: 
  #   config_endpoint "service" "channel" "parameters"
  
  echo redis-cli -u $server hset daq_service:topology:endpoint:$1:$2 ${@:3}  
  redis-cli -u $server hset daq_service:topology:endpoint:$1:$2 ${@:3}  
}

#function config_link () {
function link () {
  # config_link "service1" "channel" "service2" "channel" "parameters"
  
  echo redis-cli -u $server set daq_service:topology:link:$1:$2,$3:$4 non
  redis-cli -u $server set daq_service:topology:link:$1:$2,$3:$4 none
}


echo "---------------------------------------------------------------------"
echo " config endpoint (socket)"
echo "---------------------------------------------------------------------"
#------------------------------------------------------------------------------------
#            service                channel         options
#------------------------------------------------------------------------------------

# subtime frame builder
endpoint  STFBFilePlayer    out           type push  method connect autoSubChannel true
# tf                                                                                                                         
endpoint     TimeFrameBuilder        in            type pull  method bind
endpoint     TimeFrameBuilder        out           type push  method bind enable-uds false portRangeMin 5555 portRangeMax 5555
#endpoint     TimeFrameBuilder        decimator     type push  method connect

echo "---------------------------------------------------------------------"
echo " config link"
echo "---------------------------------------------------------------------"
#------------------------------------------------------------------------------------
#       service1                channel1              service2        channel2      
#------------------------------------------------------------------------------------

link    STFBFilePlayer        out                  TimeFrameBuilder  in
#link    STFBuilder              dqm                  Scaler           in
#link    Scaler                  out                  ScrSink          in
