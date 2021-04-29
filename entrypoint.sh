#!/bin/bash

set -e
umask 0027

monitor() {
    while true
    do
        sleep 30
        PS_OUTPUT=$(ps ux)

        if [[ "${START_VQL_SERVER,,}" == 'true' && "$PS_OUTPUT" != *'Denodo VDP Server 8.0'* ]]; then
            echo "VQL Server not Running - Exiting Now"
            shutdown 1
        elif [[ ("${START_VQL_SERVER,,}" == 'true' || "${START_DESIGN_STUDIO,,}" == 'true' || "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' || "${START_DATA_CATALOG,,}" == 'true' || "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true') && "$PS_OUTPUT" != *'Denodo Web Container 8.0'* ]]; then
            echo "Other services not running - Exiting Now"
            shutdown 1
        elif [[ "${START_SCHEDULER,,}" == 'true' && "$PS_OUTPUT" != *'Denodo Scheduler Server 8.0'* ]]; then
            echo "Scheduler not running - Exiting Now"
            shutdown 1
        elif [[ "${START_INDEXING_SERVER,,}" == 'true' && "$PS_OUTPUT" != *'Denodo Aracne Index/Search Engine Server 8.0'* ]]; then
            echo "Indexing Server not running - Exiting Now"
            shutdown 1
        fi
    done
}

startup() {
    if [[ "${START_VQL_SERVER,,}" == 'true' ]]; then
        echo Starting VQL Server
        ${HOME}/bin/vqlserver_startup.sh
    fi
    if [[ "${START_DESIGN_STUDIO,,}" == 'true' ]]; then
        echo Starting Design Studio
        ${HOME}/bin/designstudio_startup.sh
    fi
    if [[ "${START_SCHEDULER,,}" == 'true' ]]; then
        echo Starting Scheduler
        ${HOME}/bin/scheduler_startup.sh
    fi
    if [[ "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' ]]; then
        echo Starting Scheduler Web Admin
        ${HOME}/bin/scheduler_webadmin_startup.sh
    fi
    if [[ "${START_INDEXING_SERVER,,}" == 'true' ]]; then
        echo Starting Indexing Server
        ${HOME}/bin/arnindex_startup.sh
    fi
    if [[ "${START_DATA_CATALOG,,}" == 'true' ]]; then
        echo Starting Data Catalog
        ${HOME}/bin/datacatalog_startup.sh
    fi
    if [[ "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true' ]]; then
        echo Starting Diagnostic and Monitoring
        ${HOME}/bin/diagnosticmonitoringtool_startup.sh
    fi
    monitor
}

shutdown() {
    if [[ "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true' ]]; then
        echo Stopping Diagnostic and Monitoring
        ${HOME}/bin/diagnosticmonitoringtool_shutdown.sh
    fi
    if [[ "${START_DATA_CATALOG,,}" == 'true' ]]; then
        echo Stopping Data Catalog
        ${HOME}/bin/datacatalog_shutdown.sh
    fi
    if [[ "${START_INDEXING_SERVER,,}" == 'true' ]]; then
        echo Stopping Indexing Server
        ${HOME}/bin/arnindex_shutdown.sh
    fi
    if [[ "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' ]]; then
        echo Stopping Scheduler Web Admin
        ${HOME}/bin/scheduler_webadmin_shutdown.sh
    fi
    if [[ "${START_SCHEDULER,,}" == 'true' ]]; then
        echo Stopping Scheduler
        ${HOME}/bin/scheduler_shutdown.sh
    fi
    if [[ "${START_DESIGN_STUDIO,,}" == 'true' ]]; then
        echo Stopping Design Studio
        ${HOME}/bin/designstudio_shutdown.sh
    fi
    if [[ "${START_VQL_SERVER,,}" == 'true' ]]; then
        echo Stopping VQL Server
        ${HOME}/bin/vqlserver_shutdown.sh
    fi

    exit ${1:-0}
}

entrypoint.py

${HOME}/bin/regenerateFiles.sh

trap "shutdown" INT TERM

unset "${!DENODO_@}"

startup