#! /bin/bash

# script to diagnose errors in i2b2 and aktin installation
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly WILDFLY_HOME=/opt/wildfly

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# create a log folder for this diagnosis
CURRENT=$(date +%Y_%h_%d_%H%M)
readonly LOGFOLDER=$(pwd)/aktin_diag_$CURRENT
if [[ ! -d $(pwd)/aktin_diag_$CURRENT ]]; then
    mkdir $(pwd)/aktin_diag_$CURRENT
fi

# check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${ORA}Dieses Script muss mit root-Rechten ausgeführt werden!${WHI}"
   exit 1
fi


# copy wildfly log into log folder
cp -R $WILDFLY_HOME/standalone/log $LOGFOLDER/wildfly_log

# copy apache2 log into log folder
cp -R /var/log/apache2 $LOGFOLDER/apache_log

# copy postgresql log into log folder
cp -R /var/log/postgresql $LOGFOLDER/postgresql_log

# list deployments of wildfly
ls -l $WILDFLY_HOME/standalone/deployments/ > $LOGFOLDER/deployments.txt

# check usage of hard drive space
df -h > $LOGFOLDER/diskspace.txt

# check running process
echo -e "${YEL}+++++ WILDFLY SERVICE STATUS +++++${WHI}" > $LOGFOLDER/services.txt
echo $(service wildfly status) >> $LOGFOLDER/services.txt

echo -e "${YEL}+++++ WILDFLY PS +++++${WHI}" >> $LOGFOLDER/services.txt
echo $(ps -ef | grep wildfly) >> $LOGFOLDER/services.txt

echo -e "${YEL}+++++ POSTGRES SERVICE STATUS +++++${WHI}" >> $LOGFOLDER/services.txt
echo $(service postgresql status) >> $LOGFOLDER/services.txt

echo -e "${YEL}+++++ POSTGRES PS +++++${WHI}" >> $LOGFOLDER/services.txt
echo $(ps -ef | grep postgresql) >> $LOGFOLDER/services.txt

echo -e "${YEL}+++++ JAVA PS +++++${WHI}" >> $LOGFOLDER/services.txt
echo $(ps -ef | grep java) >> $LOGFOLDER/services.txt

# check version numbers
echo -e "${YEL}+++++ OPERATING SYSTEM +++++${WHI}" > $LOGFOLDER/version.txt
echo $(hostnamectl) >> $LOGFOLDER/version.txt

echo -e "${YEL}+++++ POSTGRES VERSION +++++${WHI}" >> $LOGFOLDER/version.txt
echo $(psql --version) >> $LOGFOLDER/version.txt

echo -e "${YEL}+++++ JAVA VERSION +++++${WHI}" >> $LOGFOLDER/version.txt
echo $(java --version) >> $LOGFOLDER/version.txt

# check internal memory
top -b -n 1 > $LOGFOLDER/ram.txt

# check permission and existence of folders
if [ -d /var/lib/aktin/ ]; then
    echo $(ls -ld /var/lib/aktin/) >> $LOGFOLDER/permissions.txt
        if [ -d /var/lib/aktin/reports ]; then
            echo $(ls -ld /var/lib/aktin/reports) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}/var/lib/aktin/reports DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        if [ -d /var/tmp/report-temp ]; then
            echo $(ls -ld /var/tmp/report-temp) >> $LOGFOLDER/permissions.txt
        else
           echo -e "${ORA}/var/lib/aktin/report-temp DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        if [ -d /var/lib/aktin/report-archive ]; then
            echo $(ls -ld /var/lib/aktin/report-archive) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}/var/lib/aktin/report-archive DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        if [ -d /var/lib/aktin/broker ]; then
            echo $(ls -ld /var/lib/aktin/broker) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}/var/lib/aktin/broker DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        if [ -d /var/lib/aktin/broker-archive ]; then
            echo $(ls -ld /var/lib/aktin/broker-archive) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}/var/lib/aktin/broker-archive DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        if [ -d /var/lib/aktin/import ]; then
            echo $(ls -ld /var/lib/aktin/import) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}/var/lib/aktin/import DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        if [ -d /var/lib/aktin/import-scripts ]; then
            echo $(ls -ld /var/lib/aktin/import-scripts) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}/var/lib/aktin/import-scripts DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
else
    echo -e "${RED}FOLDER /var/lib/aktin DOES NOT EXIST${WHI}" > permissions.txt
fi

# zip all logs and send per mail
tar -czf $LOGFOLDER/aktin_diag_$CURRENT.tar.gz --absolute-names --warning=no-file-changed $LOGFOLDER/
#curl -u ondtmZILwmueOoS:aktindiag5918 -T $LOGFOLDER/aktindiag.tar.gz "https://cs.uol.de/public.php/webdav/aktindiag_$dt.tar.gz"
