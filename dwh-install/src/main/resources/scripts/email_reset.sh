#! /bin/bash

# skript to remove email-configuration in wildfly/standalone.xml
set -euo pipefail # stop on errors

readonly INSTALL_ROOT=$(dirname "$(pwd)") # current directory with installation files
readonly INSTALL_DEST=${install.destination} # destination of aktin installation
readonly SCRIPT_FILES=$INSTALL_ROOT/scripts

readonly WILDFLY_HOME=$INSTALL_DEST/wildfly
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"


# start wildfly safely
cd $SCRIPT_FILES
./wildfly_safe_start.sh

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

# stop wildfly safely
cd $SCRIPT_FILES
./wildfly_safe_stop.sh
