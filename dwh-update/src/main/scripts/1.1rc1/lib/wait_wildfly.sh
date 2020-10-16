#!/usr/bin/env bash

WILDFLY_HOME=/opt/wildfly-9.0.2.Final
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

WAIT=100

starttime=$(date +%s)
while true
do
    case $(/opt/wildfly-9.0.2.Final/bin/jboss-cli.sh -c --command="read-attribute server-state") in 
        'running') 
            echo ended after $(($(date +%s)-starttime)) s
            exit 1
            ;;
        *) 
            ;;
    esac

    diff=$(($(date +%s)-starttime))

    if [ $diff -gt $WAIT ]
    then
        echo after after $(($(date +%s)-starttime)) s still not on
        exit -1
    fi
done