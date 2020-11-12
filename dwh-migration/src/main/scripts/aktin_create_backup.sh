#! /bin/bash
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>

set -euo pipefail # stop on errors

readonly MIGRATION_ROOT=$(pwd)

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

# create timestamp and log file
readonly CURRENT=$(date +%Y_%h_%d_%H%M)
readonly LOGFILE=$MIGRATION_ROOT/create_backup_$CURRENT.log

# get wildfly home directory
if [ -d /opt/wildfly/ ]; then
	readonly WILDFLY_HOME=/opt/wildfly
elif [ -d /opt/wildfly-* ]; then
	readonly WILDFLY_HOME=/opt/wildfly-*
fi




main(){

# create folder for current backup
echo -e "${YEL}Temporärer Ordner für das Backup wird erstellt.${WHI}"
if [ ! -d $MIGRATION_ROOT/backup_$CURRENT ]; then
	mkdir $MIGRATION_ROOT/backup_$CURRENT
	readonly BACKUP_FOLDER=$MIGRATION_ROOT/backup_$CURRENT
fi

# backup aktin.properties
echo -e "${YEL}Backup von aktin.properties wird erstellt.${WHI}"
cp $WILDFLY_HOME/standalone/configuration/aktin.properties $BACKUP_FOLDER/backup_aktin.properties

# backup Databases
echo -e "${YEL}Backup der Datenbanken aktin und i2b2 wird erstellt.${WHI}"
sudo -u postgres pg_dump i2b2 > $BACKUP_FOLDER/backup_i2b2.sql
sudo -u postgres pg_dump aktin > $BACKUP_FOLDER/backup_aktin.sql

# backup log folders and add ".backup_TIMESTAMP" to each file in backuped log folders
echo -e "${YEL}Backup der Logs von apache2, postgresql und wildfly wird erstellt.${WHI}"
FOLDERS=( apache2_log postgresql_log wildfly_log )
LOG_PATH=( /var/log/apache2 /var/log/postgresql $WILDFLY_HOME/standalone/log )
for i in "${!FOLDERS[@]}"
do
	if [ ! -d $BACKUP_FOLDER/${FOLDERS[$i]} ]; then
		mkdir $BACKUP_FOLDER/${FOLDERS[$i]}
	fi
	cp -r ${LOG_PATH[$i]}/* $BACKUP_FOLDER/${FOLDERS[$i]}/
	cd $BACKUP_FOLDER/${FOLDERS[$i]}
	for file in *
	do
		mv $file backup_$file
	done
done

# backup /var/lib/aktin
echo -e "${YEL}Backup von /var/lib/aktin/ wird erstellt.${WHI}"
if [ ! -d $BACKUP_FOLDER/aktin_lib ]; then
	mkdir $BACKUP_FOLDER/aktin_lib
fi
cp -r /var/lib/aktin $BACKUP_FOLDER/aktin_lib

# zip BACKUP_FOLDER
echo -e "${YEL}Backup-Ordner wird komprimiert.${WHI}"
cd $MIGRATION_ROOT
tar -czf $MIGRATION_ROOT/aktin_backup_$CURRENT.tar.gz --absolute-names --warning=no-file-changed backup_$CURRENT/*

# remove BACKUP_FOLDER
echo -e "${YEL}Temporärer Backup-Ordner wird wieder entfernt.${WHI}"
rm -r $BACKUP_FOLDER

echo
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo "Um die Migration erfolgreich durchzuführen, befolgen Sie folgende Schritte:"
echo
echo "1. Sichern Sie alle Dateien in diesem Ordner auf ein externes Medium. Es wurde ein Backup von folgenden Komponenten erstellt:"
echo -e "- Die Datei ${GRE}aktin.properties${WHI}"
echo -e "- Die Datenbanken ${GRE}aktin${WHI} und ${GRE}i2b2${WHI}"
echo -e "- Die Logs von ${GRE}apache2${WHI}, ${GRE}postgresql${WHI} und ${GRE}wildfly${WHI}"
echo -e "- Der Ordner ${GRE}/var/lib/aktin/${WHI}"
echo -e "Sollten Sie noch weitere Dateien absichern wollen, melden Sie dies bitte an ${GRE}it-support@aktin.org${WHI}."
echo
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo -e "Notieren Sie sich außerdem manuell den Inhalt der Datei ${RED}email.config${WHI}. Die dort enthaltenen Informationen Ihres E-Mail-Servers müssen anschließend in die neue aktin.properties eingegeben werden."
echo
echo -e "2. Überschreiben Sie das Betriebssystem dieses Servers mit ${GRE}Ubuntu Server 20.04 LTS${WHI} oder einem ähnlichen Betriebssystem. Eine Anleitung hierzu finden Sie online auf ${GRE}www.aktin.org/de-de/support.html${WHI}."
echo
echo "3. Kopieren Sie alle gesicherten Dateien des externen Mediums in einen beliebigen Ordner auf dem neu installierten Betriebssystems."
echo
echo -e "4. Führen Sie in diesem Ordner das Skript ${GRE}aktin_apply_backup.sh${WHI} aus. Das Skript wird zunächst das AKTIN-Installationsskript und das AKTIN-Updateskript ausführen, um die aktuellste Version des AKTIN Data Warehouse auf dem neuen Betriebssystem zu installieren. Anschließend werden Ihre gesicherten Dateien des Backup-Ordners in das Data Warehouse eingespielt. ${RED}Beachten Sie hierfür auch die Hinweise in der Konsolenausgabe der anderen Skripte!${WHI}"
echo
}

main | tee -a $LOGFILE
