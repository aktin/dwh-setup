#! /bin/bash

# skript to remove email-configuration in wildfly/standalone.xml
set -euo pipefail # stop on errors

readonly WILDFLY_HOME=/opt/wildfly
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}

# check for running wildlfy server
if  [[ $(service wildfly status | grep "not" | wc -l) == 1 ]]; then
   echo -e "${RED}Running instance of wildfly could not be found!${WHI}"
   exit 1
fi

# not changeable parameters
readonly SESSIONNAME=AktinMailSession
readonly JNDINAME=java:jboss/mail/AktinMailSession
readonly SMTPBIND=aktin-smtp-binding

# delete injected configuration of email.config
if [ $( grep -c "smtp-server outbound-socket-binding-ref=\"$SMTPBIND\"" $WILDFLY_HOME/standalone/configuration/standalone.xml ) -gt 0 ]; then 
	$JBOSSCLI "/subsystem=mail/mail-session=$SESSIONNAME/server=smtp:remove"
fi
if [ $( grep -c "outbound-socket-binding name=\"$SMTPBIND\"" $WILDFLY_HOME/standalone/configuration/standalone.xml ) -gt 0 ]; then 
	$JBOSSCLI "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$SMTPBIND:remove"
fi
if [ $( grep -c "mail-session name=\"$SESSIONNAME\"" $WILDFLY_HOME/standalone/configuration/standalone.xml ) -gt 0 ]; then 
	$JBOSSCLI "/subsystem=mail/mail-session=$SESSIONNAME:remove"
fi	
