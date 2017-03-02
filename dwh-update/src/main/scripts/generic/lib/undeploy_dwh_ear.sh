#!/usr/bin/env bash

# Initial parameters
WILDFLY_HOME=/opt/wildfly-${wildfly.version}
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

for i in $(cd $WILDFLY_HOME/standalone/deployments/ && ls -t dwh-j2ee-*.deployed); 
    do
            ear=$(echo $i | sed 's/.deployed$//')
            echo undeploying: $ear           
            $JBOSSCLI "undeploy --name=$ear"
            echo
    done