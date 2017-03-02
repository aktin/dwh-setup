#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# undeploy dwh to prevent crash
echo DWH EAR wird undeployed
$install_root/lib/undeploy_dwh_ear.sh

# get smtp settings
LOCAL_SETTING=$install_root/email.config
. $LOCAL_SETTING

# not changeable parameters
sessionname=AktinMailSession
jndiname=java:jboss/mail/AktinMailSession
smtpbind=aktin-smtp-binding

# delete older config with aktin mail
if [ $( grep -c "smtp-server outbound-socket-binding-ref=\"$smtpbind\"" $WILDFLY_HOME/standalone/configuration/standalone.xml ) -gt 0 ]; then 
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname/server=smtp:remove"
fi
if [ $( grep -c "outbound-socket-binding name=\"$smtpbind\"" $WILDFLY_HOME/standalone/configuration/standalone.xml ) -gt 0 ]; then 
	$JBOSSCLI "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:remove"
fi
if [ $( grep -c "mail-session name=\"$sessionname\"" $WILDFLY_HOME/standalone/configuration/standalone.xml ) -gt 0 ]; then 
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname:remove"
fi	

# $JBOSSCLI --command="/:reload"
# $install_root/wait_wildfly.sh
# local wait_wildfly=$?

# if [ $wait_wildfly -lt 0 ] then
# 	echo "- jboss state unstable. exiting running script"
# 	exit -1
# fi