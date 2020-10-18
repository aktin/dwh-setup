#! /bin/bash

# script to diagnose errors in i2b2 and aktin installation
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
# september 2020

set -euo pipefail # stop on errors

readonly WILDFLY_HOME=${path.wildfly.link}

# colors for console output
readonly WHI='\033[0m'
readonly RED='\e[1;31m'
readonly ORA='\e[0;33m'
readonly YEL='\e[1;33m'
readonly GRE='\e[0;32m'

# create a log folder for this diagnosis
CURRENT=$(date +%Y_%h_%d_%H:%M)
readonly LOGFOLDER=${path.log.folder}/aktin_diag_$CURRENT
if [[ ! -d ${path.log.folder} ]]; then
    mkdir ${path.log.folder}
fi
if [[ ! -d ${path.log.folder}/aktin_diag_$CURRENT ]]; then
    mkdir ${path.log.folder}/aktin_diag_$CURRENT
fi

# check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "${ORA}Dieses Script muss mit root-Rechten ausgeführt werden!${WHI}"
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
    echo -e "${YEL}/var/lib/aktin${WHI}" > $LOGFOLDER/permissions.txt
    echo $(ls -ld /var/lib/aktin/) >> $LOGFOLDER/permissions.txt
   		echo -e "${YEL}/var/lib/aktin/reports${WHI}" >> $LOGFOLDER/permissions.txt
        if [ -d /var/lib/aktin/reports ]; then  
            echo $(ls -ld /var/lib/aktin/reports) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}FOLDER DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        echo -e "${YEL}/var/lib/aktin/report-temp${WHI}" >> $LOGFOLDER/permissions.txt
        if [ -d /var/tmp/report-temp ]; then
            echo $(ls -ld /var/tmp/report-temp) >> $LOGFOLDER/permissions.txt
        else
           echo -e "${ORA}FOLDER DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        echo -e "${YEL}/var/lib/aktin/report-archive${WHI}" >> $LOGFOLDER/permissions.txt
        if [ -d /var/lib/aktin/report-archive ]; then
            echo $(ls -ld /var/lib/aktin/report-archive) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}FOLDER DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        echo -e "${YEL}/var/lib/aktin/broker${WHI}" >> $LOGFOLDER/permissions.txt
        if [ -d /var/lib/aktin/broker ]; then
            echo $(ls -ld /var/lib/aktin/broker) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}FOLDER DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
        echo -e "${YEL}/var/lib/aktin/broker-archive${WHI}" >> $LOGFOLDER/permissions.txt
        if [ -d /var/lib/aktin/broker-archive ]; then
            echo $(ls -ld /var/lib/aktin/broker-archive) >> $LOGFOLDER/permissions.txt
        else
            echo -e "${ORA}FOLDER DOES NOT EXIST${WHI}" >> $LOGFOLDER/permissions.txt
        fi
else
    echo -e "${RED}FOLDER /var/lib/aktin DOES NOT EXIST${WHI}" > permissions.txt
fi

# zip all logs and send per mail
tar -czf $LOGFOLDER/aktin_diag_$CURRENT.tar.gz --absolute-names --warning=no-file-changed $LOGFOLDER/
#curl -u ondtmZILwmueOoS:aktindiag5918 -T $LOGFOLDER/aktindiag.tar.gz "https://cs.uol.de/public.php/webdav/aktindiag_$dt.tar.gz"
