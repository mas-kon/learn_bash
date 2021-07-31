#!/bin/bash

if [ -z $1 ]
then
    echo "Please, input file name"
else
    size=$(ls -al $1 | cut -d " " -f 5)
#    echo $size
    if [ $size -le 1024 ]
    then
        echo "OK"
    else
        echo "FAIL"
    fi
fi
