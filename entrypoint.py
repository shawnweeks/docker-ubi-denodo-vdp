#!/usr/bin/python3

from entrypoint_helpers import env, gen_cfg, set_props

HOME = env["HOME"]

if "DENODO_USE_EXTERNAL_METADATA" in env and env["DENODO_USE_EXTERNAL_METADATA"].lower() == "true":
    gen_cfg("metadb.properties.j2", "{}/conf/metadb.properties".format(HOME))

gen_cfg("SolutionManager.properties.j2", "{}/conf/SolutionManager.properties".format(HOME))
gen_cfg("VDBConfiguration.properties.j2", "{}/conf/vdp/VDBConfiguration.properties".format(HOME))
gen_cfg("SchedulerConfigurationParameters.properties.j2", "{}/conf/scheduler/ConfigurationParameters.properties".format(HOME))
gen_cfg("SchedulerIndexConfigurationParameters.properties.j2", "{}/conf/arn-index/ConfigurationParameters.properties".format(HOME))
gen_cfg("tomcat.properties.j2", "{}/resources/apache-tomcat/conf/tomcat.properties".format(HOME))
gen_cfg("server.xml.j2", "{}/resources/apache-tomcat/conf/server.xml".format(HOME))