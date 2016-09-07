#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final

# get settings
LOCAL_SETTING=$install_root/local_smtp_settings.conf
. $LOCAL_SETTING

smtpchange=false

while [[ $# -gt 1 ]]
do
key="$1"
case $key in
    -y)
    prompt=false
    shift # past argument
    ;;
    -c|--change)
    smtpchange=true
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done
smtpchange=true

# prompt for input if not "y" as parameter
if [ $prompt ]; then
	read -p "Möchten Sie die Einstellungen für den SMTP Server jetzt anpassen? Wählen Sie nein, wenn die Einstellungen in der Datei $LOCAL_SETTING bereits angepasst sind. [Ja/Nein]" yn
	case $yn in
	    [Nn]* ) ;; # do nothing
		* ) 
			# read in configurations
			while true ; do 
				read -p "Bitte geben Sie den SMTP Host ein: (jetziger Wert: $smtphost)" input
				if [ ! -z "$input" ]; then
					smtphost=$input
				fi
				read -p "Bitte geben Sie den SMTP Port ein: (jetziger Wert: $smtpport)" input
				if [ ! -z "$input" ]; then
					smtpport=$input
				fi
				read -p "Bitte geben Sie den SMTP user ein: (jetziger Wert: $smtpuser)" input
				if [ ! -z "$input" ]; then
					smtpuser=$input
				fi
				# -s -p
				read -p "Bitte geben Sie das SMTP password ein:" smtppass
				# check input data
				echo "============================================"
				echo "Bitte überprüfen Sie die eingegebene Daten: "
				echo "SMTP Host: $smtphost"
				echo "SMTP Port: $smtpport"
				echo "SMTP user: $smtpuser"
				echo "SMTP password: $smtppass"
				read -p "Sind die oben gelisteten Daten richtig? [Ja/Nein]" yn
				case $yn in
					[YJyj]* ) # move out of loop
						break
					;;
					* ) # falsche Eingaben
						echo "============================================"
						echo "Bitte geben Sie SMTP Daten ein: "
					;; 	
				esac
			done

			read -p "Möchten Sie die Einstellungen in die Datei $LOCAL_SETTING speichern? Die jetzige Datei wird dabei überschrieben. [Ja/Nein]" yn
			case $yn in
	    		[Nn]* ) ;; # do nothing
	    		* ) 
					if [ ! -f "$LOCAL_SETTING.orig" ]; then 
						mv $LOCAL_SETTING $LOCAL_SETTING.orig
					fi
					echo "smtphost=$smtphost" > $install_root/local_settings.conf
					echo "smtpport=$smtpport" >> $install_root/local_settings.conf
					echo "smtpuser=$smtpuser" >> $install_root/local_settings.conf
					echo "smtppass=$smtppass" >> $install_root/local_settings.conf
					echo "usessl=$usessl" >> $install_root/local_settings.conf
				;;
			esac
		;;
	esac
fi

sessionname="AktinMailSession"
jndiname="java:jboss/mail/AktinMailSession"
smtpbind="aktin-smtp-binding"

if [ $smtpchange ]; then
	$WILDFLY_HOME/bin/jboss-cli.sh -c "/subsystem=mail/mail-session=$sessionname/server=smtp:remove"
	$WILDFLY_HOME/bin/jboss-cli.sh -c "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:remove"
	$WILDFLY_HOME/bin/jboss-cli.sh -c "/subsystem=mail/mail-session=$sessionname:remove"
fi
$WILDFLY_HOME/bin/jboss-cli.sh -c "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:add(host=$smtphost, port=$smtpport)"
$WILDFLY_HOME/bin/jboss-cli.sh -c "/subsystem=mail/mail-session=$sessionname:add(jndi-name=$jndiname)"
$WILDFLY_HOME/bin/jboss-cli.sh -c "/subsystem=mail/mail-session=$sessionname/server=smtp:add(outbound-socket-binding-ref=$smtpbind, username=$smtpuser, password=$smtppass, ssl=$usessl)"

$WILDFLY_HOME/bin/jboss-cli.sh -c "reload"
