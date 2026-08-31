#!/bin/bash

server=redis://127.0.0.1:6379/2

function param () {
  # "instance":"field" "value"
  #echo redis-cli -u $server set parameters:$1:$2 ${@:3}
  #redis-cli -u $server set parameters:$1:$2 ${@:3}
  echo redis-cli -u $server hset parameters:$1 ${@:2}
  redis-cli -u $server hset parameters:$1 ${@:2}
}

redis-cli -u $server  flushdb 

#===============================================================================================
#      isntance-id                field       value             field       value  
#===============================================================================================
#
# TdcType HR-TDC: 5, LR-TDC: 6 (on Jun. 7, 2024)

#param  STFBFilePlayer-0           in-file run000408_00_stf.dat
#param  STFBFilePlayer-0           in-file run002036.dat
param  STFBFilePlayer-0           in-file input_data/tdcdata/00/run003005.dat
param  STFBFilePlayer-1           in-file input_data/tdcdata/01/run003005.dat
param  STFBFilePlayer-2           in-file input_data/tdcdata/02/run003005.dat
param  STFBFilePlayer-3           in-file input_data/tdcdata/03/run003005.dat
param  STFBFilePlayer-4           in-file input_data/tdcdata/04/run003005.dat
param  STFBFilePlayer-5           in-file input_data/tdcdata/05/run003005.dat
param  STFBFilePlayer-6           in-file input_data/tdcdata/06/run003005.dat
param  STFBFilePlayer-7           in-file input_data/tdcdata/07/run003005.dat
param  STFBFilePlayer-8           in-file input_data/tdcdata/08/run003005.dat
param  STFBFilePlayer-9           in-file input_data/tdcdata/09/run003005.dat

param  AmQStrTdcSampler-0         msiTcpIp   192.168.10.35   TdcType     6
param  AmQStrTdcSampler-1         msiTcpIp   192.168.10.36   TdcType     5
param  AmQStrTdcSampler-2         msiTcpIp   192.168.10.37   TdcType     5
param  AmQStrTdcSampler-3         msiTcpIp   192.168.10.16   TdcType     6
#
param  STFBuilder-0  max-hbf 4
param  STFBuilder-1  max-hbf 4
param  STFBuilder-2  max-hbf 4
param  STFBuilder-3  max-hbf 4
param  STFBuilder-4  max-hbf 4
param  STFBuilder-5  max-hbf 4
param  STFBuilder-6  max-hbf 4
param  STFBuilder-7  max-hbf 4
param  STFBuilder-8  max-hbf 4
param  STFBuilder-9  max-hbf 4
#
param Scaler-0    prefix exedir/00 ext .dat
param Scaler-1    prefix exedir/01 ext .dat
param Scaler-2    prefix exedir/02 ext .dat
param Scaler-3    prefix exedir/03 ext .dat
#
param TimeFrameBuilder-0  decimation-factor 1000 discard-output false enable-uds false
param TimeFrameBuilder-1  decimation-factor 1000 discard-output false enable-uds false
param TimeFrameBuilder-2  decimation-factor 1000 discard-output false enable-uds false
param TimeFrameBuilder-3  decimation-factor 1000 discard-output false enable-uds false
#
param FileSink-0  multipart true prefix  data/rawdata/00 ext .dat write-sleep-in-msec 100
param FileSink-1  multipart true prefix  data/rawdata/01 ext .dat write-sleep-in-msec 100
param FileSink-2  multipart true prefix  data/rawdata/02 ext .dat write-sleep-in-msec 100
param FileSink-3  multipart true prefix  data/rawdata/03 ext .dat write-sleep-in-msec 100
#
param JsonSink-0  multipart true prefix  data/rawdata/00 ext .dat write-sleep-in-msec 0
param JsonSink-1  multipart true prefix  data/rawdata/01 ext .dat write-sleep-in-msec 0
param JsonSink-2  multipart true prefix  data/rawdata/02 ext .dat write-sleep-in-msec 0
param JsonSink-3  multipart true prefix  data/rawdata/03 ext .dat write-sleep-in-msec 0
#
param EDM4hepSink-0  multipart true  enable-uds false
param EDM4hepSink-1  multipart true enable-uds false
param EDM4hepSink-2  multipart true enable-uds false
param EDM4hepSink-3  multipart true enable-uds false
#
param ScrSink-0   multipart true  prefix scdata/00 ext .dat
param ScrSink-1   multipart true  prefix scdata/01 ext .dat
param ScrSink-2   multipart true  prefix scdata/02 ext .dat
param ScrSink-3   multipart true  prefix scdata/03 ext .dat
#
# Sink for Decimator         
param DecSink-0  multipart true prefix dcmdata/00 ext .dat
param DecSink-1  multipart true prefix dcmdata/01 ext .dat
param DecSink-2  multipart true prefix dcmdata/02 ext .dat
param DecSink-3  multipart true prefix dcmdata/03 ext .dat

param TimeFrameSlicerByLogicTiming time-offset-begin -25 time-offset-end 25

