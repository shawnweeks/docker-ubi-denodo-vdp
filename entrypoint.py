#!/usr/bin/python2

from entrypoint_helpers import env, gen_cfg, set_props

HOME = env["HOME"]

gen_cfg("SolutionManager.properties.j2", "{}/conf/SolutionManager.properties".format(HOME))
gen_cfg("VDBConfiguration.properties.j2", "{}/conf/vdp/VDBConfiguration.properties".format(HOME))
gen_cfg("SchedulerConfigurationParameters.properties.j2", "{}/conf/scheduler/ConfigurationParameters.properties".format(HOME))
gen_cfg("SchedulerIndexConfigurationParameters.properties.j2", "{}/conf/arn-index/ConfigurationParameters.properties".format(HOME))
gen_cfg("tomcat.properties.j2", "{}/resources/apache-tomcat/conf/tomcat.properties".format(HOME))
gen_cfg("server.xml.j2", "{}/resources/apache-tomcat/conf/server.xml".format(HOME))