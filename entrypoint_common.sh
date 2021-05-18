# Replaces or Appends Key Value Pairs in a Java Style Properties File
prop_replace() {
    local KEY=$1
    local VALUE=$2
    local FILE=$3

    if ! grep --silent "^[#]*\s*${KEY}=.*" ${FILE} 2>/dev/null; then
        echo "APPENDING '${VALUE}' because '${KEY}' not found in ${FILE}."
        echo "${KEY}=${VALUE}" >> ${FILE}
    elif ! grep --silent "^${KEY}=${VALUE}" ${FILE} 2>/dev/null; then
        echo "UPDATING '${VALUE}' because '${KEY}' was different in ${FILE}."
        sed -i.backup "s~^[#]*\s*${KEY}=.*~${KEY}=${VALUE}~" ${FILE}
    else
        echo "SKIPPING '${KEY}' because '${VALUE}' already set in ${FILE}."
    fi
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

monitor() {
    while true
    do
        sleep 30
        PS_OUTPUT=$(ps ux)

        if [[ "${START_VQL_SERVER,,}" == 'true' && "$PS_OUTPUT" != *'Denodo VDP Server 8.0'* ]]; then
            echo "VQL Server not Running - Exiting Now"
            shutdown 1
        elif [[ "${WEB_CONTAINER_RUNNING,,}" == 'true' && "$PS_OUTPUT" != *'Denodo Web Container 8.0'* ]]; then
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

shutdown() {  
    # During shutdown we can just shutdown Tomcat 
    # instead of shutting each item down directly.
    echo Stopping Web Container
    ${HOME}/bin/webcontainer_shutdown.sh
    if [[ "${START_INDEXING_SERVER,,}" == 'true' ]]; then
        echo Stopping Indexing Server
        ${HOME}/bin/arnindex_shutdown.sh
    fi
    if [[ "${START_SCHEDULER,,}" == 'true' ]]; then
        echo Stopping Scheduler
        ${HOME}/bin/scheduler_shutdown.sh
    fi
    if [[ "${START_VQL_SERVER,,}" == 'true' ]]; then
        echo Stopping VQL Server
        ${HOME}/bin/vqlserver_shutdown.sh
    fi

    exit ${1:-0}    
}

configure_external_db() {
    if ! [[ "${DENODO_USE_EXTERNAL_DB,,}" == 'true' ]]
    then
        return 0
    fi
    
    echo "Enabling External Metadata Database"
    ${HOME}/bin/regenerateMetadata.sh \
        --adapter "${DENODO_STORAGE_PLUGIN}" \
        --version "${DENODO_STORAGE_VERSION}" \
        --driver "${DENODO_STORAGE_DRIVER}" \
        ${DENODO_STORAGE_DRIVER_PROPERTIES:+--driverProperties} "${DENODO_STORAGE_DRIVER_PROPERTIES}" \
        --classPath "${DENODO_STORAGE_CLASSPATH}" \
        --databaseUri "${DENODO_STORAGE_URI}" \
        --user "${DENODO_STORAGE_USER}" \
        --password "${DENODO_STORAGE_PASSWORD}" \
        ${DENODO_STORAGE_CATALOG:+--catalog} "${DENODO_STORAGE_CATALOG}" \
        ${DENODO_STORAGE_CATALOG:+--schema} "${DENODO_STORAGE_SCHEMA}" \
        --initialSize  "${DENODO_STORAGE_INITIAL_SIZE:-4}" \
        --maxActive "${DENODO_STORAGE_INITIAL_SIZE:-100}" \
        --testConnections \
        --pingQuery "${DENODO_STORAGE_PING_QUERY:-select 1}" \
        --yes
    }

configure_ssl() {
    if ! [[ "${DENODO_SSL_ENABLED,,}" == 'true' ]]
    then
        return 0
    fi

    echo "Enabling SSL"

    # Populating Credentials file with Keystore and Truststore Password
    #echo "keystore.password=$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_KEYSTORE_PASSWORD} | grep -v 'Encrypted Password:' )" > ${HOME}/conf/credentials
    #echo "truststore.password=$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_TRUSTSTORE_PASSWORD} | grep -v 'Encrypted Password:')" >> ${HOME}/conf/credentials

    prop_replace "keystore.password" "$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_KEYSTORE_PASSWORD} | grep -v 'Encrypted Password:' )" "${HOME}/conf/credentials"
    prop_replace "truststore.password" "$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_TRUSTSTORE_PASSWORD} | grep -v 'Encrypted Password:' )" "${HOME}/conf/credentials"
    
    # Making local copies so we don't have to modify the external files
    cp ${DENODO_SSL_KEYSTORE} ${HOME}/conf/keystore.jks
    cp ${DENODO_SSL_TRUSTSTORE} ${HOME}/conf/truststore.jks

    # Because Denodo made some poor descisions we need to extract the cert just to put it back
    keytool -exportcert -keystore ${DENODO_SSL_KEYSTORE} -storepass ${DENODO_SSL_KEYSTORE_PASSWORD} -alias ${DENODO_SSL_KEYSTORE_ALIAS} -file ${HOME}/conf/cert.cer 2>/dev/null

    # Running Denodo SSL Configuration Script
    ${HOME}/bin/denodo_tls_configurator.sh \
        --denodo-home ${HOME} \
        --keystore ${HOME}/conf/keystore.jks \
        --truststore ${HOME}/conf/truststore.jks \
        --cert-cer-file ${HOME}/conf/cert.cer \
        --credentials-file ${HOME}/conf/credentials \
        --license-manager-uses-tls=true
    
    # Cleanup Files    
    rm ${HOME}/conf/cert.cer ${HOME}/conf/credentials
}

# This breaks log4j2 so I'll have to wait for a fix from Denodo
# fix_java_11() {
#     for FILE in $(grep -P '^DENODO_JRE11_OPTIONS' ${HOME}/bin/*.sh -l)
#     do
#         : ${DENODO_JRE11_OPTIONS:=-Xshare:off -Djava.locale.providers=COMPAT,SP}
#         echo "Setting DENODO_JRE11_OPTIONS to \"${DENODO_JRE11_OPTIONS}\" in ${FILE}"
#         sed -i -r "s/(DENODO_JRE11_OPTIONS=).*/\1\"${DENODO_JRE11_OPTIONS}\"/" "${FILE}"
#     done
# }

configure_rmi_hostname() {
    prop_replace \
        "com.denodo.vdb.vdbinterface.server.VDBManagerImpl.registryURL" \
        "${DENODO_RMI_HOSTNAME:-localhost}" \
        ${HOME}/conf/vdp/VDBConfiguration.properties

    prop_replace \
        "com.denodo.tomcat.jmx.rmi.host" \
        "${DENODO_RMI_HOSTNAME:-localhost}" \
        ${HOME}/resources/apache-tomcat/conf/tomcat.properties
}

configure_java_opts() {
    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_VDP_JAVA_OPTS:--Xmx1024m -XX:NewRatio=4}" \
        ${HOME}/conf/vdp/VDBConfiguration.properties

    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_SM_JAVA_OPTS:--Xmx1024m}" \
        ${HOME}/conf/scheduler/ConfigurationParameters.properties

    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_WEB_JAVA_OPTS:--Xmx1024m -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true -Djava.locale.providers=COMPAT,SPI}" \
        ${HOME}/resources/apache-tomcat/conf/tomcat.properties
}

configure() {
    START_VQL_SERVER="${DENODO_START_VQL_SERVER:-true}"
    START_DESIGN_STUDIO="${DENODO_START_DESIGN_STUDIO:-true}"
    START_SCHEDULER="${DENODO_START_SCHEDULER:-true}"
    START_SCHEDULER_WEB_ADMIN="${DENODO_START_SCHEDULER_WEB_ADMIN:-true}"
    START_INDEXING_SERVER="${DENODO_START_INDEXING_SERVER:-true}"
    START_DATA_CATALOG="${DENODO_START_DATA_CATALOG:-true}"
    START_DIAGNOSTIC_AND_MONITORING="${DENODO_START_DIAGNOSTIC_AND_MONITORING:-true}"
    
    if [[ "${START_VQL_SERVER,,}" == 'true' || "${START_DESIGN_STUDIO,,}" == 'true' || "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' || "${START_DATA_CATALOG,,}" == 'true' || "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true' ]]; then
        WEB_CONTAINER_RUNNING='true'
    else
        WEB_CONTAINER_RUNNING='false'
    fi

    #echo "${DENODO_LICENSE}" > /opt/denodo/conf/denodo.lic
    
    entrypoint.py

    # This breaks log4j2 so I'll have to wait for a fix from Denodo
    # fix_java_11

    #configure_rmi_hostname
    
    #configure_java_opts

    #configure_ssl

    #configure_external_db

    ${HOME}/bin/regenerateFiles.sh
}