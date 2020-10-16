#! /bin/bash

# skript to inject email-configuration in wildfly/standalone.xml
set -euo pipefail # stop on errors

readonly INSTALL_ROOT=${path.install.link}
readonly INSTALL_DEST=${path.install.destination}

readonly WILDFLY_HOME=$INSTALL_DEST/wildfly
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"


# start wildfly safely
cd $INSTALL_ROOT
./wildfly_safe_start.sh

# get smtp settings (see email.config)
cd $INSTALL_ROOT
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

# stop wildfly safely
cd $INSTALL_ROOT
./wildfly_safe_stop.sh
