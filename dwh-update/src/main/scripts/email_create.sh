#! /bin/bash

# skript to inject email-configuration in wildfly/standalone.xml
set -euo pipefail # stop on errors

readonly WILDFLY_HOME=/opt/wildfly
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}

# check for running wildlfy server
if  [[ $(service wildfly status | grep "not" | wc -l) == 1 ]]; then
   echo "${RED}Running instance of wildfly could not be found!${WHI}"
   exit 1
fi

# get smtp settings (see email.config)
. email.config

# not changeable parameters
readonly SESSIONNAME=AktinMailSession
readonly JNDINAME=java:jboss/mail/AktinMailSession
readonly SMTPBIND=aktin-smtp-binding

# create new settings in standalone.xml
$JBOSSCLI "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$SMTPBIND:add(host=$SMTPHOST, port=$SMTPPORT)"
$JBOSSCLI "/subsystem=mail/mail-session=$SESSIONNAME:add(jndi-name=$JNDINAME)"
if $AUTH ; then 
	$JBOSSCLI "/subsystem=mail/mail-session=$SESSIONNAME/server=smtp:add(outbound-socket-binding-ref=$SMTPBIND, username=$SMTPUSER, password=$SMTPPASS, tls=$USETLS, ssl=$USESSL)"
else 
	$JBOSSCLI "/subsystem=mail/mail-session=$SESSIONNAME/server=smtp:add(outbound-socket-binding-ref=$SMTPBIND)"
fi
$JBOSSCLI "/subsystem=mail/mail-session=$SESSIONNAME/:write-attribute(name=from, value=$MAILFROM)"
