#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
INSTALL_ROOT=$(dirname "$(dirname "$SCRIPT")")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# get smtp settings
LOCAL_SETTING=$INSTALL_ROOT/email.config
. $LOCAL_SETTING

# not changeable parameters
sessionname=AktinMailSession
jndiname=java:jboss/mail/AktinMailSession
smtpbind=aktin-smtp-binding


count=$(($( grep -c "smtp-server outbound-socket-binding-ref=\"$smtpbind\"" $WILDFLY_HOME/standalone/configuration/standalone.xml )+$( grep -c "outbound-socket-binding name=\"$smtpbind\"" $WILDFLY_HOME/standalone/configuration/standalone.xml )+$( grep -c "mail-session name=\"$sessionname\"" $WILDFLY_HOME/standalone/configuration/standalone.xml )))
if [ $count -gt 0 ]; then 
	echo Email bereits eingestellt. Dieser Schritt wird übersprungen.
	echo Für Änderungen bitte email_config_reset.sh aufrufen und diesen Update erneut durchführen
else
	# create new settings
	$JBOSSCLI "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:add(host=$smtphost, port=$smtpport)"
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname:add(jndi-name=$jndiname)"
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname/server=smtp:add(outbound-socket-binding-ref=$smtpbind, username=$smtpuser, password=$smtppass, tls=$usetls, ssl=$usessl)"
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname/:write-attribute(name=from, value=$mailfrom)"
fi


