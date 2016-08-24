#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final

prompt=true
if [ $# -eq 0 ] || [ $1 != "y" ];	then
	prompt=true
else
	prompt=false
fi

echo clense postgres i2b2 database crc tables
# su - postgres bash -c "$install_root/postgres_db_script.sh"
su - postgres bash -c "psql -d i2b2 -f $install_root/postgres_cleanse_crc_db_script.sql"
echo create mail service
# get settings
. $install_root/local_settings.conf
# prompt for input if not "y" as parameter
if [ $prompt ]; then
	read -p "Möchten Sie die Einstellungen für den SMTP Server jetzt anpassen? Wählen Sie nein, wenn die Einstellungen in der Datei $install_root/local_settings.conf bereits angepasst sind. [Ja/Nein]" yn
	case $yn in
	    [Nn]* ) ;; # do nothing
		* ) 
			read -p "Bitte geben Sie den SMTP Host ein: [jetziger Wert: $smtphost]" input
			if [ ! -z "$input" ]; then
				smtphost=$input
			fi
			read -p "Bitte geben Sie den SMTP Port ein: [jetziger Wert: $smtphost]" input
			if [ ! -z "$input" ]; then
				smtpport=$input
			fi
			read -p "Bitte geben Sie den SMTP user ein: [jetziger Wert: $smtphost]" input
			if [ ! -z "$input" ]; then
				smtpuser=$input
			fi
			read -p -s "Bitte geben Sie den SMTP password ein: " smtppass

			read -p "Möchten Sie die Einstellungen in die Datei $install_root/local_settings.conf speichern? Die jetzige Datei wird dabei überschrieben. [Ja/Nein]" yn
			case $yn in
	    		[Nn]* ) ;; # do nothing
	    		* ) 
					if [ ! -f "$install_root/local_settings.conf.orig" ]; then 
						mv $install_root/local_settings.conf $install_root/local_settings.conf.orig
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
sed -i "s/@smtphost@/\"$smtphost\"/g; s/@smtpport@/$smtpport/g; s/@smtpuser@/\"$smtpuser\"/g; s/@smtppass@/\"$smtppass\"/g; s/@usessl@/$usessl/g" $install_root/create_mail_service.cli
# run jboss cli script
$WILDFLY_HOME/bin/jboss-cli.sh -c --file=$install_root/create_mail_service.cli