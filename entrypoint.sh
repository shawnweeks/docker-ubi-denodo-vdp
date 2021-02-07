#!/bin/bash

set -e
umask 0027

monitor() {
    while true
    do   
        sleep 30
        PS_OUTPUT=$(ps ux)
        # if [[ "$PS_OUTPUT" != *'Denodo Platform License Manager 7.0'* ]]; then
        #     echo "License Manager Not Running - Exiting Now"
        #     shutdown 1
        # elif [[ "$PS_OUTPUT" != *'Denodo VDP Server 7.0'* ]]; then
        #     echo "VQL Server not Running - Exiting Now"
        #     shutdown 1
        # elif [[ "$PS_OUTPUT" != *'Denodo Platform Solution Manager 7.0'* ]]; then  
        #     echo "Solution Manager Not Runnig - Exiting Now"
        #     shutdown 1
        # elif [[ "$PS_OUTPUT" != *'apache-tomcat'* ]]; then  
        #     echo "Web Container Not Running - Exiting Now"
        #     shutdown 1          
        # fi
    done
}

startup() {    
    echo Starting VQL Server    
    ${HOME}/bin/vqlserver_startup.sh
    # echo Starting Scheduler
    # ${HOME}/bin/scheduler_startup.sh
    # echo Starting Scheduler Web Admin
    # ${HOME}/bin/scheduler_webadmin_startup.sh
    # echo Starting Data Catalog
    # ${HOME}/bin/scheduler_webadmin_startup.sh
    # echo Starting Diagnostic and Monitoring
    # ${HOME}/bin/diagnosticmonitoringtool_startup.sh
    tail -n +1 -F \
        $HOME/logs/vdp/vdp.log \
        $HOME/logs/vdp/vdp-cache.log \
        $HOME/logs/vdp/vdp-queries.log \
        $HOME/logs/vdp/vdp-requests.log \
        $HOME/logs/vdp-dmt/vdp-dmt.log \
        $HOME/logs/scheduler/scheduler-admin.log \
        $HOME/logs/scheduler/scheduler.log \
        $HOME/logs/apache-tomcat/tomcat.log \
        $HOME/logs/apache-tomcat/denodows.log \
        $HOME/resources/apache-tomcat/logs/catalina.out &
    TAIL_PID="$!"    
    monitor
}

shutdown() {
    echo Stopping VQL Server
    ${HOME}/bin/vqlserver_shutdown.sh    
    echo Stopping Logging
    kill -sigterm $TAIL_PID
    exit ${1:-0}    
}

entrypoint.py

${HOME}/bin/regenerateFiles.sh

trap "shutdown" INT TERM

unset "${!DENODO_@}"

startup