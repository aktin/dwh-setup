#!/usr/bin/env bash
# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final

# get settings
LOCAL_SETTING=$install_root/local_smtp_settings.conf
. $LOCAL_SETTING

# check whether console parameter was given. use -y to avoid prompt
prompt=true
# if [ $# -eq 0 ] || [ $1 != "y" ];	then
# 	prompt=false
# else
# 	prompt=true
# fi
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

# prompt for input if not "y" as parameter
if [ $prompt ]; then
	read -p "Möchten Sie die Einstellungen für den SMTP Server jetzt anpassen? Wählen Sie nein, wenn die Einstellungen in der Datei $LOCAL_SETTING bereits angepasst sind. [Ja/Nein]" yn
	case $yn in
	    [Nn]* ) ;; # do nothing
		* ) 
			# read in configurations
			while true ; do 
				read -p "Bitte geben Sie den SMTP Host ein: (jetziger Wert: $smtphost) []" input
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
				read -p -s "Bitte geben Sie den SMTP password ein: " smtppass
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

# replace strings in the cli file
CLI_SERVICE=/var/tmp/aktin_tmp_setup_mail_service.cli
# if [ ! -f "$CLI_SERVICE.orig" ]; then 
# 	cp $CLI_SERVICE $CLI_SERVICE.orig
# fi
# sed -i "s/@smtphost@/\"$smtphost\"/g; s/@smtpport@/$smtpport/g; s/@smtpuser@/\"$smtpuser\"/g; s/@smtppass@/\"$smtppass\"/g; s/@usessl@/$usessl/g" $CLI_SERVICE

sessionname="AktinMailSession"
jndiname="java:jboss/mail/AktinMailSession"
smtpbind="aktin-smtp-binding"
echo " " > $CLI_SERVICE
if [$smtpchange]; then
	echo "/subsystem=mail/mail-session=$sessionname/server=smtp:remove" >> $CLI_SERVICE
	echo "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:remove" >> $CLI_SERVICE
	echo "/subsystem=mail/mail-session=$sessionname:remove" >> $CLI_SERVICE
fi
echo "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:add(host=$smtphost, port=$smtpport)" >> $CLI_SERVICE
echo "/subsystem=mail/mail-session=$sessionname:add(jndi-name=$jndiname)" >> $CLI_SERVICE
echo "/subsystem=mail/mail-session=$sessionname/server=smtp:add(outbound-socket-binding-ref=$smtpbind, username=$smtpuser, password=$smtppass, ssl=$usessl)" >> $CLI_SERVICE
echo "reload" >> $CLI_SERVICE

# run jboss cli script
$WILDFLY_HOME/bin/jboss-cli.sh -c --file=$CLI_SERVICE
# clean up
rm $CLI_SERVICE