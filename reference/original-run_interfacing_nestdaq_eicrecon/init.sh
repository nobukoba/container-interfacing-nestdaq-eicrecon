#!/bin/sh
pkill daq-webctl
sleep 0.2
#
redis-server $HOME/spadi/etc/redis.conf --loadmodule $HOME/spadi/lib/redistimeseries.so
#RIHOST=0.0.0.0 redisinsight-linux64 &
#daq-webctl >& $NESTDAQ/log/daq-webctl.log &
#$HOME/nestdaq/bin/daq-webctl >& /dev/null &
cmd="$HOME/spadi/bin/daq-webctl --http-uri http://0.0.0.0:5962 >& /dev/null &"
echo $cmd
eval $cmd
