#!/bin/bash
count=0

MAX_COUNT=5

if [ $(netstat -tlnp|grep named|wc -l) -eq 0 ]
then
    #wait for while
    while [ $count -lt $MAX_COUNT ]
    do 
        let count+=1
        sleep 2
    done
    if [ $(netstat -tlnp|grep named|wc -l) -eq 0 ]
    then
        echo "stop keepalived"
        /etc/init.d/keepalived stop
    fi
fi
