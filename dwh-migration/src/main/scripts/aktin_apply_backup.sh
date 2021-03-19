#! /bin/bash
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>

set -euo pipefail # stop on errors

readonly MIGRATION_ROOT=$(pwd)
readonly WILDFLY_HOME=/opt/wildfly
readonly SQL_FILES=$MIGRATION_ROOT/aktin-dwh-installer/dwh-update/sql
readonly TMP_SQL_FILES=/tmp/sql

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Dieses Script muss mit root-Rechten ausgeführt werden!${WHI}"
   exit 1
fi

# check for existance of only one backup folder
if [[ ! $(ls -l | grep -c "aktin_backup.*.tar.gz") == 1 ]]; then
    echo -e "${RED}Es muss sich im Verzeichnis eine einzige Backup-tar.gz befinden!${WHI}"
    exit 1
else
    if [[ ! $(ls -d */ | grep -c "backup_") == 0 ]]; then
        echo -e "${RED}In diesem Verzeichnis befindet sich bereits ein entpackter Backup-Ordner!${WHI}"
        exit 1
    else
        tar -xzf aktin_backup_*.tar.gz
        readonly BACKUP_FOLDER=$MIGRATION_ROOT/backup_*
    fi
fi

# create log file
readonly LOGFILE=$MIGRATION_ROOT/apply_backup_$(date +%Y_%h_%d_%H%M).log




# run dwh-install with dwh-update
tar xvzf packages/dwh-install-*.tar.gz
cd aktin-dwh-installer
./aktin_install.sh

main(){

# copy aktin.properties to wildfly
echo -e "${YEL}Unbearbeitete aktin.properties wird nach $WILDFLY_HOME/standalone/configuration/ kopiert.${WHI}"
cp $MIGRATION_ROOT/aktin-dwh-installer/dwh-update/aktin.properties $WILDFLY_HOME/standalone/configuration/

# iterate through all rows in backup_aktin.properties,
# line start until '=' -> KEY
# '=' until line end -> VALUE
# search key in new aktin.properties
# overwrite value in new aktin.properties if found
echo -e "${YEL}aktin.properties in $WILDFLY_HOME/standalone/configuration/ wird mit dem Backup gepacht.${WHI}"
while read -r line1; do
    if [[ ! $line1 = \#* && ! -z $line1 ]]; then
        KEY=${line1%=*}
        VALUE=${line1#*=}
        while read -r line2; do
            if [[ ! $line2 = \#* && ! -z $line2 ]]; then
                if [[ ${line2%=*} == $KEY ]]; then
                    sed -i "s|${KEY}=.*|${KEY}=${VALUE}|" $WILDFLY_HOME/standalone/configuration/aktin.properties
                    break
                fi
            fi
        done < $WILDFLY_HOME/standalone/configuration/aktin.properties
    fi
done < $BACKUP_FOLDER/backup_aktin.properties
sed -i "s|email.session=.*|email.session=local|" $WILDFLY_HOME/standalone/configuration/aktin.properties


echo -e "${YEL}Service apache2 und wildfly werden gestoppt.${WHI}"
if ! systemctl is-active --quiet postgresql; then
    service postgresql start
fi
if systemctl is-active --quiet wildfly; then
    service wildfly stop
fi
if systemctl is-active --quiet apache2; then
    service apache2 stop
fi


# create tmp sql folder
if [[ ! -d $TMP_SQL_FILES ]]; then
    echo -e "${YEL}SQL-Dateien werden nach /tmp kopiert.${WHI}"
    mkdir $TMP_SQL_FILES
    cp $SQL_FILES/* $TMP_SQL_FILES/
    cp $BACKUP_FOLDER/backup_aktin.sql $TMP_SQL_FILES/
    cp $BACKUP_FOLDER/backup_i2b2.sql $TMP_SQL_FILES/
    chmod 777 -R $TMP_SQL_FILES
fi

# delete new databases aktin and i2b2
echo -e "${YEL}Die neu installierten Datenbanken aktin und i2b2 werden gelöscht.${WHI}"
sudo -u postgres psql -f $TMP_SQL_FILES/aktin_postgres_drop.sql
sudo -u postgres psql -f $TMP_SQL_FILES/i2b2_postgres_drop.sql

# re-init databases aktin and i2b2
echo -e "${YEL}Die Datenbanken aktin und i2b2 werden reinitialisiert.${WHI}"
sudo -u postgres psql -v ON_ERROR_STOP=1 -f $TMP_SQL_FILES/i2b2_postgres_init.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 -f $TMP_SQL_FILES/aktin_postgres_init.sql

# copy backup to databases aktin and i2b2
echo -e "${YEL}Das Backup der Datenbanken aktin und i2b2 wird eingespielt.${WHI}"
sudo -u postgres psql  -d i2b2 -f $TMP_SQL_FILES/backup_i2b2.sql
sudo -u postgres psql  -d aktin -f $TMP_SQL_FILES/backup_aktin.sql

# add AKTIN study to Study Manager
if [[ -z $(sudo -u postgres psql -d i2b2 -c "SELECT id FROM i2b2crcdata.optinout_studies;"| grep "AKTIN") ]]; then
    echo -e "${YEL}Studie AKTIN wird zur Datenbank hinzugefügt.${WHI}"
    sudo -u postgres psql -d i2b2 -c "INSERT INTO i2b2crcdata.optinout_studies (id,title,description,created_ts,options) VALUES ('AKTIN','AKTIN','Notaufnahmeregister','2018-01-01 00:00:00', 'OPT=O');"
fi

# delete tmp sql folder
if [[ -d $TMP_SQL_FILES ]]; then
    echo -e "${YEL}SQL-Dateien werden aus /tmp wieder gelöscht.${WHI}"
    rm -r $TMP_SQL_FILES
fi

# copy backuped logs to log folders
echo -e "${YEL}Backup der Logs von apache2, postgresql und wildfly wird eingespielt.${WHI}"
cp -r $BACKUP_FOLDER/apache2_log/* /var/log/apache2/
cp -r $BACKUP_FOLDER/postgresql_log/* /var/log/postgresql/
cp -r $BACKUP_FOLDER/wildfly_log/* $WILDFLY_HOME/standalone/log/

# copy backup of /var/lib/aktin into real /var/lib/aktin
echo -e "${YEL}Backup von /var/lib/aktin/ wird eingespielt.${WHI}"
cp -r $BACKUP_FOLDER/aktin_lib/* /var/lib/aktin/
chown -R wildfly:wildfly /var/lib/aktin

# remove BACKUP_FOLDER
echo -e "${YEL}Temporärer Backup-Ordner wird wieder entfernt.${WHI}"
rm -r $BACKUP_FOLDER


echo -e "${YEL}Service apache2 und wildfly werden wieder gestartet.${WHI}"
if ! systemctl is-active --quiet apache2; then
    service apache2 start
fi
if ! systemctl is-active --quiet wildfly; then
    service wildfly start
fi


echo
echo "Migration abgeschlossen!"
echo "Vielen Dank, dass Sie die AKTIN-Software verwenden."
echo
echo
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo "Es wurde die aktuellste Version des AKTIN Data Warehouse installiert und das Backup Ihrer Daten eingespielt. Die standardmäßig ausgelieferte aktin.properties wurde größtenteils mit dem Inhalt Ihrer alten aktin.properties gepacht. Kontrollieren Sie den Inhalt der gepachten Version mittels"
echo
echo -e "${GRE} nano $WILDFLY_HOME/standalone/configuration/aktin.properties${WHI}"
echo
echo -e "Es ist darauf hinzuweisen dass am Ende der Datei einige Felder für die Konfiguration des E-Mail-Servers hinzugekommen sind. Tragen Sie hier Ihre notierten Informationen der Datei ${RED}email.config${WHI} ein. Stellen Sie außerdem auch sicher, dass das Feld"
echo
echo -e "${GRE} email.session=local${WHI}"
echo
echo -e "entsprechend bezeichnet ist. Nur mit dem Keyword ${GRE}local${WHI} wird die Konfiguration innerhalb der aktin.properties genutzt. Starten Sie nach Abschluss der Bearbeitung den WildFly-Server neu, um die neue Konfiguration zu laden"
echo
echo -e "${GRE} service wildfly restart${WHI}"
echo
echo
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo -e "Bitte melden Sie auftretende Fehler an ${GRE}it-support@aktin.org${WHI}!"
echo
}

main | tee -a $LOGFILE
