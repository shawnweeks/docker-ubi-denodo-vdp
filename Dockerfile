ARG BASE_REGISTRY
ARG BASE_IMAGE=redhat/ubi/ubi8
ARG BASE_TAG=8.3

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as build

ARG DENODO_VERSION
ARG DENODO_PACKAGE=denodo-install-7.0-20180330-linux64.zip
ARG DENODO_UPDATE_PACKAGE=denodo-v70-update-${DENODO_VERSION}.zip

COPY [ "${DENODO_PACKAGE}", "${DENODO_UPDATE_PACKAGE}", "denodo_response.xml", "/tmp/" ]

RUN yum install -y unzip java-1.8.0-openjdk-devel && \
    unzip /tmp/${DENODO_PACKAGE} -d /tmp/ && \
    mkdir -p /tmp/denodo-install-7.0/denodo-update/ && \
    unzip /tmp/${DENODO_UPDATE_PACKAGE} -d /tmp && \
    mv /tmp/denodo-v70-update-*.jar /tmp/denodo-install-7.0/denodo-update/denodo-update.jar && \
    sh /tmp/denodo-install-7.0/installer_cli.sh install --autoinstaller /tmp/denodo_response.xml && \
    rm -rf /opt/denodo/jre /opt/denodo/logs/*/*.log

###############################################################################
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

ENV DENODO_USER denodo
ENV DENODO_GROUP denodo
ENV DENODO_UID 2001
ENV DENODO_GID 2001

ENV DENODO_HOME /opt/denodo

RUN yum install -y java-1.8.0-openjdk-devel procps git python2 python2-jinja2 && \
    yum clean all && \    
    mkdir -p ${DENODO_HOME} && \
    groupadd -r -g ${DENODO_GID} ${DENODO_GROUP} && \
    useradd -r -u ${DENODO_UID} -g ${DENODO_GROUP} -M -d ${DENODO_HOME} ${DENODO_USER} && \
    chown ${DENODO_USER}:${DENODO_GROUP} ${DENODO_HOME} -R

COPY --from=build --chown=${DENODO_USER}:${DENODO_GROUP} [ "${DENODO_HOME}/", "${DENODO_HOME}/" ]
COPY --chown=${DENODO_USER}:${DENODO_GROUP} [ "entrypoint.sh", "entrypoint.py", "entrypoint_helpers.py", "${DENODO_HOME}/" ]
COPY [ "templates/*.j2", "/opt/jinja-templates/" ]

RUN chmod 755 ${DENODO_HOME}/entrypoint.*

VOLUME ${DENODO_HOME}/metadata/db

EXPOSE 9090 9443 9996 9997 9999

USER ${DENODO_USER}
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0
ENV PATH=${PATH}:${DENODO_HOME}
WORKDIR ${DENODO_HOME}
ENTRYPOINT [ "entrypoint.sh" ]