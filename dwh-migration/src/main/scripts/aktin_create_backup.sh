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
if [[ -d /opt/wildfly/ ]]; then
	readonly WILDFLY_HOME=/opt/wildfly
elif [[ -n $(ls /opt/wildfly-*) ]]; then
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

# backup /var/lib/aktin
echo -e "${YEL}Backup von /var/lib/aktin/ wird erstellt.${WHI}"
if [ ! -d $BACKUP_FOLDER/aktin_lib ]; then
	mkdir $BACKUP_FOLDER/aktin_lib
fi
cp -r /var/lib/aktin/* $BACKUP_FOLDER/aktin_lib

# zip BACKUP_FOLDER
echo -e "${YEL}Backup-Ordner wird komprimiert.${WHI}"
cd $MIGRATION_ROOT
tar -czf $MIGRATION_ROOT/aktin_backup_$CURRENT.tar.gz --absolute-names --warning=no-file-changed backup_$CURRENT/*

# remove BACKUP_FOLDER
echo -e "${YEL}Temporärer Backup-Ordner wird wieder entfernt.${WHI}"
rm -r $BACKUP_FOLDER

echo
echo "Backup abgeschlossen!"
echo
}

main | tee -a $LOGFILE
