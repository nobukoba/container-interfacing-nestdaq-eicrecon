#!/bin/sh

./mq-param.sh
./topology-stf-tf-eicrecon.sh
exec ./run-stf-tf-eicrecon.sh
