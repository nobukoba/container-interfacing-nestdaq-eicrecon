#!/bin/bash

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/local/lib:$HOME/local/lib64


# 2. STFB
tmux new-session -d -t stfb
for runID in {0..9}
do
    echo "start device SubTime Frame Builder ${runID}"
	tmux new-window -d -n STF${runID} -t stfb -- ./start_device.sh STFBFilePlayer #--host-ip 192.168.2.51
    sleep 0.1
done

tmux kill-window -t stfb:0
xterm -geometry 80x15+500+0 -T SubTimeFrameBuilder -e tmux a -t stfb &
	
# 4. TFB
tmux new-session -d -t tfb
#for runID in {0..24}
for runID in {0..0}
#for runID in {0}
do
    echo "start device TimeFrameBuilder ${runID}"
    tmux new-window -d -n TFB${runID} -t tfb -- ./start_device.sh TimeFrameBuilder #--host-ip 192.168.2.51
    sleep 0.2
done
tmux kill-window -t tfb:0
xterm -geometry 80x15+0+270 -T TimeFrameBuilder -e tmux a -t tfb &

#ssh -X nestdaq@getdaq02 '(cd run ; ./run_sink_devel.sh)'
