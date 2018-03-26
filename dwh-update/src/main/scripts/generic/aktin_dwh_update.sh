#!/usr/bin/env bash

# generic aktin dwh update to 0.7
# 28 Feb 2017
# Oldenburg

NEW_VERSION=${dwhJ2EEVersion}

# Initial parameters
SCRIPT=$(readlink -f "$0")
INSTALL_ROOT=$(dirname "$SCRIPT") # current directory
WILDFLY_HOME=/opt/wildfly-${wildfly.version} # wildfly directory
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c" # jboss cli command
i2b2_WEBDIR=/var/webroot/webclient # webclient directory

LOGFILE=$INSTALL_ROOT/update.log # logfile for update log
touch $LOGFILE

RCol='\e[0m'; Red='\e[0;31m'; BRed='\e[1;31m'; Yel='\e[0;33m'; BYel='\e[1;33m'; Gre='\e[0;32m'; BGre='\e[1;32m'; Blu='\e[0;34m'; BBlu='\e[1;34m'; 

echo ++++++++++++++++++++++
echo
echo AKTIN J2ee update auf $NEW_VERSION | tee -a $LOGFILE
date | tee -a $LOGFILE
echo
echo ++++++++++++++++++++++

echo
echo +++++ STEP 0 +++++ Überprüfung der Paths und Ausgabe der Status Informationen | tee -a $LOGFILE
echo
# check os version (set system based commands)
OS_VERSION=debian
# debian is standard TODO check wether is pure debian
# if [ $(ls /etc/d* | grep -c "debian") -gt 1 ] ; then 
# fi
# $(ls /etc/c* | grep -c "centos") -gt 1
# Decision if centos or redhat system
if [ -f "/etc/centos-release" ] ; then 
    OS_VERSION=centos
fi
if [ -f "/etc/redhat-release" ] ; then 
    # at the moment same as centos
    OS_VERSION=centos
fi
echo System als $OS_VERSION erkannt

# check wilfly home
if [ ! -d "$WILDFLY_HOME" ]; then
    echo +++ERROR+++ WILDFLY Home directory nicht gefunden! Update wird unterbrochen ... Code 126 | tee -a $LOGFILE
    exit 126 #Command invoked cannot execute
else
    echo WILDFLY Home directory checked | tee -a $LOGFILE
fi
# check i2b2 web folder
if [ ! -d "$i2b2_WEBDIR" ]; then
    echo +++ERROR+++ i2b2 Web directory nicht gefunden! Update wird unterbrochen ... Code 126 | tee -a $LOGFILE
    exit 126 #Command invoked cannot execute
else
    echo i2b2 Web directory checked | tee -a $LOGFILE
fi
# XXX check more paths? (compatible linux distribution?)
# XXX check if "service" command is available
# check older dwh-j2ee ear files
numdeployed=$(find $WILDFLY_HOME/standalone/deployments/ -name "dwh-j2ee-*" | grep -c deployed)
if [ $numdeployed -gt 0 ] ; then
    # not necessary / old : don't touch it
    if find $WILDFLY_HOME/standalone/deployments/ -name "dwh-j2ee-*.deployed" 1> /dev/null 2>&1; then
        OLD_VERSION=$(ls -t $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.deployed | head -1 | sed -n -e 's#'$WILDFLY_HOME'/standalone/deployments/dwh-j2ee-##'p | sed -n -e 's#.ear.deployed$##'p)
        echo Currently deployed version is $OLD_VERSION | tee -a $LOGFILE
    else
        echo -e "${BYel}+++WARNING+++${RCol} No EAR is currently deployed" | tee -a $LOGFILE
    fi
else 
    echo -e "${BYel}+++WARNING+++${RCol} No EAR is currently deployed" | tee -a $LOGFILE
fi

echo
echo +++++ STEP 0.01 +++++ JDK08 Fix  | tee -a $LOGFILE
echo
if [ "$OS_VERSION" == "debian" ] && [ $(java -version 2>&1 | grep -c "build 1.8") -le 0 ] ; then

    echo -e "${BYel}+++WARNING+++${RCol} Java Version ist nicht 1.8. Dies kann zu Probleme führen."
    # java is not jdk 8
    # Enable backports
    # http.debian.net/debian jessie-backports main
    # if [ $(grep -c -e "^deb http://http.debian.net/debian jessie-backports main" /etc/apt/sources.list) -le 0 ] ; then
    #     echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
    # fi

    # apt-get update
    # apt install -t jessie-backports -y openjdk-8-jre-headless ca-certificates-java

    #link java to jre 8
    # update-alternatives --set java $(update-alternatives --list java | grep "java-8")
fi



echo
echo +++++ STEP 0.02.0a +++++ Vorbereitung auf Patch  | tee -a $LOGFILE
echo
if [ "$OS_VERSION" == "debian" ] ; then

    apt-get update
    apt install -y patch
fi
if [ "$OS_VERSION" == "centos" ] ; then
    yum -y install patch
fi



echo
echo +++++ STEP 0.02 +++++ Überprüfung aktin.properties  | tee -a $LOGFILE
echo
# check_aktin_properties checks if aktin.properties is already in wildfly config folder and if yes returns 0 else 124
$INSTALL_ROOT/lib/check_aktin_properties.sh 2>&1 | tee -a $LOGFILE
checkexit=${PIPESTATUS[0]}
if [ $checkexit -gt 0 ]; then
    echo -e "${BYel}+++WARNING+++${RCol} Bitte Überprüfen Sie auch die Angaben in $INSTALL_ROOT/email.config" | tee -a $LOGFILE
    echo -e "${Gre}    nano $INSTALL_ROOT/email.config${RCol}" | tee -a $LOGFILE
    echo und führen Sie diesen Script erneut aus. | tee -a $LOGFILE
    echo -e "${Gre}    $SCRIPT${RCol}" | tee -a $LOGFILE
    exit $checkexit

else 
    current=$(date +%Y%h%d%H%M)
    # create backup if not existent
    if [ ! -f aktin.properties.backup.$current ]; then
        # backup old file to this folder
        cp $WILDFLY_HOME/standalone/configuration/aktin.properties aktin.properties.backup.$current | tee -a $LOGFILE
    fi

    # if patchfiles exists at this point it is old, so remove it
    if [ -f properties.patch ]; then
        rm properties.patch | tee -a $LOGFILE
    fi

    # create patch file - only i2b2.project and new keys are changed
    # this means it will add all new additions to the existing patch file without touching the edited content
    diff $WILDFLY_HOME/standalone/configuration/aktin.properties aktin.properties | sed -n '/^[,0-9]\+d[,0-9]\+/{$!{:x;z;N;/^\s*[<]/bx;D;}}; /^[,0-9]\+c[,0-9]\+/{$!{:x;z;N;/^\s*[<>-]/bx;D;}}; P;' > properties.patch 2>&1 | tee -a $LOGFILE

    # test patch 
    patchErrorCount=$(patch $WILDFLY_HOME/standalone/configuration/aktin.properties --dry-run -i properties.patch 2>&1 | grep -c "Only garbage was found in the patch input")

    # if the patch produces "garbage" it will not be applied
    if [ ! $patchErrorCount -gt 0 ]; then 

        # apply patch
        patch $WILDFLY_HOME/standalone/configuration/aktin.properties -i properties.patch -o aktin.properties.patched 2>&1 | tee -a $LOGFILE

        # move new patched file to wildfly
        mv aktin.properties.patched $WILDFLY_HOME/standalone/configuration/aktin.properties  | tee -a $LOGFILE
        chown wildfly:wildfly $WILDFLY_HOME/standalone/configuration/aktin.properties  | tee -a $LOGFILE
    else 
        echo -e "${BYel}+++WARNING+++${RCol} Patch konnte nicht erfolgreich angewandt werden, bitte überprüfen Sie die neue Properties-Datei und fügen Sie eventuell neue Einstellungen in $WILDFLY_HOME/standalone/configuration/aktin.properties hinzu!" | tee -a $LOGFILE
    fi
fi


echo
echo +++++ STEP 1 +++++ Undeployment von allen alten dwh-j2ee EAR | tee -a $LOGFILE
echo
# if existing, undeploy older dwh-j2ee ear files
$INSTALL_ROOT/lib/undeploy_dwh_ear.sh 2>&1 | tee -a $LOGFILE

# clean up older ears
# rm $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*

echo
echo "+++++ STEP 2 +++++ Execute scripts (SQL, Copy files etc.)" | tee -a $LOGFILE
echo


#echo
#echo +++++ STEP 2.01 +++++ Fact Database Reset| tee -a $LOGFILE
#echo
# XXX not supported yet - NOP
# check id length and delete facts with "short" ids

echo
echo +++++ STEP 2.02 +++++ Update local DWH ontology | tee -a $LOGFILE
echo
# this step updates the meta database
SQLLOG=$INSTALL_ROOT/update_sql.log
# folder where the postgres user can call sql files
CDATMPDIR=/var/tmp/cda-ontology
mkdir $CDATMPDIR
echo "-- update ontology to ${org.aktin:cda-ontology:jar.version}" 2>&1 | tee -a $LOGFILE | tee -a $SQLLOG
# unzip the sql jar to the folder
unzip $INSTALL_ROOT/packages/cda-ontology-${org.aktin:cda-ontology:jar.version}.jar -d $CDATMPDIR
cp -v $INSTALL_ROOT/lib/remove_ont.sql $CDATMPDIR/sql/remove_ont.sql 2>&1 | tee -a $LOGFILE  # copy the remove ont file 
chmod 777 -R $CDATMPDIR # change the permissions of the folder
# call sql script files. no console output
echo "-- remove old ontology" 2>&1 | tee -a $LOGFILE | tee -a $SQLLOG
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/remove_ont.sql" 2>&1 >> $SQLLOG
echo "-- update metadata" 2>&1 | tee -a $LOGFILE | tee -a $SQLLOG
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" 2>&1 >> $SQLLOG
echo "-- update crcdata" 2>&1 | tee -a $LOGFILE | tee -a $SQLLOG
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" 2>&1 >> $SQLLOG
# remove temp directory
echo "- Ontology Update done. Result logged in $SQLLOG"


echo
echo +++++ STEP 2.02.01 +++++ Patienten Datum Fix | tee -a $LOGFILE
echo
cp -v $INSTALL_ROOT/lib/fix_visit_patient_date_accuracy.sql $CDATMPDIR/sql/fix_visit_patient_date_accuracy.sql 2>&1 | tee -a $LOGFILE  # copy the sql file 
echo "-- fix visit patient date accuracy" 2>&1 | tee -a $LOGFILE | tee -a $SQLLOG
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/fix_visit_patient_date_accuracy.sql" 2>&1 >> $SQLLOG


echo
echo +++++ STEP 2.02.end +++++ Aufräumen der Temporären Dateien | tee -a $LOGFILE
echo
echo "- löschen des Ordners"
rm -r $CDATMPDIR

echo
echo +++++ STEP 2.03 +++++ Entfernen der Defaulteinträge in Loginformular | tee -a $LOGFILE
echo
# check whether the login username needs to be removed. 
if [ $(grep -c "name=\"uname\" id=\"loginusr\" value=\"demo\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
then
    echo "- Username bereits entfernt. NOP" | tee -a $LOGFILE
else 
    # erstmal backup
    if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
       cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
       echo "- Webclient PM file backed up" 2>&1 | tee -a $LOGFILE
    fi
    # mit s/ suchen und dann / ersetzten
    sed -i "s/name=\"uname\" id=\"loginusr\" value=\"demo\"/name=\"uname\" id=\"loginusr\" value=\"\"/g" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js
    if [ $(grep -c "name=\"uname\" id=\"loginusr\" value=\"demo\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
    then 
        echo "+++WARNING+++ Username konnte nicht erfolgreich entfernt werden" | tee -a LOGFILE
    else 
        echo -e "- Username wurde entfernt" | tee -a $LOGFILE
        # $(grep -c "name=\"uname\" id=\"loginusr\" value=\"demo\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) occurences 
        # $(grep -oE "<input .* name=\"uname\" id=\"loginusr\".* />" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js)
    fi
fi
# same for the password
if [ $(grep -c "name=\"pword\" id=\"loginpass\" value=\"demouser\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
then
    echo "- Password bereits entfernt. NOP" | tee -a $LOGFILE
else 
    if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
       cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
       echo "- Webclient PM file backed up" 2>&1 | tee -a $LOGFILE
    fi
    sed -i "s/name=\"pword\" id=\"loginpass\" value=\"demouser\"/name=\"pword\" id=\"loginpass\" value=\"\"/g" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js

    if [ $(grep -c "name=\"pword\" id=\"loginpass\" value=\"demouser\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
    then 
        echo "+++WARNING+++ Passwort konnte nicht entfernt werden." | tee -a LOGFILE
    else 
        echo -e "- Passwort entfernt" | tee -a $LOGFILE
        # $(grep -c "name=\"pword\" id=\"loginpass\" value=\"demouser\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) occurences 
        # $(grep -oE "<input .* name=\"pword\" id=\"loginpass\".* />" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js)
    fi
fi

echo
echo +++++ STEP 2.04 +++++ Create AKTIN Database in postgres | tee -a $LOGFILE
echo
# XXX check if the database or user exist. if not, then create. if yes. only update. Right now, creating while existing will return error, but continue with the code.
cp "$INSTALL_ROOT/lib/postgres_db_script.sh" /var/tmp/
chmod a+rx /var/tmp/postgres_db_script.sh
su - postgres bash -c "/var/tmp/postgres_db_script.sh" 2>&1 | tee -a $LOGFILE
echo AKTIN database created | tee -a $LOGFILE
rm /var/tmp/postgres_db_script.sh

echo
echo +++++ STEP 2.05 +++++ Create Aktin Data source in wildfly | tee -a $LOGFILE
echo
existAktinDS=$( grep -c AktinDS $WILDFLY_HOME/standalone/configuration/standalone.xml)
echo "- $existAktinDS occurences of AKTINDS in Standalone.xml found" | tee -a $LOGFILE
if [ "$existAktinDS" -gt 0 ]
then
	$JBOSSCLI "data-source remove --name=AktinDS,/subsystem=datasources:read-resource" 2>&1 | tee -a $LOGFILE
	echo "- removed older aktin datasource " | tee -a $LOGFILE
fi
# jboss will be reloaded at the end of this update script. changes will be made, but will only take effect after reload
$JBOSSCLI --file="$INSTALL_ROOT/lib/create_aktin_datasource.cli" 2>&1 | tee -a $LOGFILE
# xxx check result? 
echo "- created aktin datasource" | tee -a $LOGFILE
# $WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --commands="reload" 2>&1 | tee -a $LOGFILE
# echo "reload" 2>&1 | tee -a $LOGFILE

echo
echo +++++ STEP 2.06 +++++  Change Logging Properties in wildfly  | tee -a $LOGFILE
echo


if [ ! $( grep -c size-rotating-file-handler $WILDFLY_HOME/standalone/configuration/standalone.xml) -gt 0 ] ; then
    if [ ! -f $WILDFLY_HOME/standalone/configuration/standalone.xml.$NEW_VERSION.orig ] ; then 
        cp $WILDFLY_HOME/standalone/configuration/standalone.xml $WILDFLY_HOME/standalone/configuration/standalone.xml.$NEW_VERSION.orig
    fi
    $JBOSSCLI --file="$INSTALL_ROOT/lib/update_wildfly_logging.cli" 2>&1 | tee -a $LOGFILE
fi

echo
echo +++++ STEP 2.07 +++++  Create /var/lib/aktin  | tee -a $LOGFILE
echo
if [ ! -d "/var/lib/aktin" ]; then 
    mkdir -p /var/lib/aktin 2>&1 | tee -a $LOGFILE
    chown wildfly /var/lib/aktin 2>&1 | tee -a $LOGFILE
    if [ ! -d "/var/lib/aktin" ]; then 
        echo +++WARNING+++ /var/lib/aktin not created | tee -a $LOGFILE
	else
        echo /var/lib/aktin successfully created | tee -a $LOGFILE
    fi 
else
    echo /var/lib/aktin present, no action necessary
fi

echo
echo +++++ STEP 2.08 +++++  Add new SMTP configuration | tee -a $LOGFILE
echo
$INSTALL_ROOT/lib/email_create.sh 2>&1 | tee -a $LOGFILE


echo
echo +++++ STEP 2.09 +++++  Wildfly JAVA VM Arbeitsspeicher Zuordnung | tee -a $LOGFILE
echo
if [ $( grep -c Xmx1024m $WILDFLY_HOME/bin/standalone.conf) -gt 0 ] ; 
then
    if [ ! -f $WILDFLY_HOME/bin/standalone.conf.orig.$NEW_VERSION ] ;
    then
        echo Backup der Config Datei nach standalone.conf.orig.$NEW_VERSION
        cp -v $WILDFLY_HOME/bin/standalone.conf $WILDFLY_HOME/bin/standalone.conf.orig.$NEW_VERSION 2>&1 | tee -a $LOGFILE
    fi
    echo Anpassung der Java VM Arbeitsspeicherzuordnung
    sed 's/Xmx1024m/Xmx2g/g' $WILDFLY_HOME/bin/standalone.conf > $WILDFLY_HOME/bin/standalone1.conf 2>&1 | tee -a $LOGFILE
    mv $WILDFLY_HOME/bin/standalone1.conf $WILDFLY_HOME/bin/standalone.conf 2>&1 | tee -a $LOGFILE
else 
    echo Keine Anpassung durchgeführt.
fi


echo
echo +++++ STEP 3 +++++  Stop Wildfly Service | tee -a $LOGFILE
echo
if [ "$OS_VERSION" == "centos" ] ; then
    systemctl stop wildfly
    echo wildfly stopped, code $?| tee -a $LOGFILE
    date | tee -a $LOGFILE
else 
    service wildfly stop
    echo wildfly stopped, code $?| tee -a $LOGFILE
    date | tee -a $LOGFILE
fi
# wait 5 seconds
#sleep 5
echo
echo "+++++ STEP 4 +++++  Remove all dwh.ear[*] (including .failed, .deployed, .undeployed)" | tee -a $LOGFILE
echo
rm -v $WILDFLY_HOME/standalone/deployments/dwh-j2ee-* 2>&1 | tee -a $LOGFILE
if ls $WILDFLY_HOME/standalone/deployments/dwh-j2ee-* 1> /dev/null 2>&1; then 
    echo +++WARNING+++ EAR files not completely removed | tee -a $LOGFILE
else
    echo EAR files removed | tee -a $LOGFILE
fi

echo
echo +++++ STEP 4.01 +++++  Alte, periodische Logdateien Komprimieren und Löschen | tee -a $LOGFILE
echo
if [ $( ls /opt/wildfly-9.0.2.Final/standalone/log/server.log.201* 2>/dev/null | wc -l ) -gt 0 ] ; 
then
    current=$(date +%Y%h%d%H%M)
    echo Alte Logdateien der Form server.log.YYYY-MM-DD werden entfernt und in die Datei serverlog_pre_${NEW_VERSION}_${current}.tgz verpackt. | tee -a $LOGFILE
    tar cvfz $WILDFLY_HOME/standalone/log/serverlog_pre_${NEW_VERSION}_${current}.tgz $WILDFLY_HOME/standalone/log/server.log.201* 2>&1  $LOGFILE
    rm -v $WILDFLY_HOME/standalone/log/server.log.201* 2>&1 $LOGFILE
fi

echo
echo +++++ STEP 5 +++++  Start Wildfly Service | tee -a $LOGFILE
echo
if [ "$OS_VERSION" == "centos" ] ; then
    systemctl start wildfly
    echo wildfly restarted, code $? | tee -a $LOGFILE
    date | tee -a $LOGFILE
else 
    service wildfly start
    echo wildfly restarted, code $? | tee -a $LOGFILE
    date | tee -a $LOGFILE
fi

echo
echo +++++ STEP 6 +++++  Deploy new dwh-j2ee EAR | tee -a $LOGFILE
echo
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear" ]; then 
    chown wildfly:wildfly $INSTALL_ROOT/packages/dwh-j2ee-$NEW_VERSION.ear
	cp -v $INSTALL_ROOT/packages/dwh-j2ee-$NEW_VERSION.ear $WILDFLY_HOME/standalone/deployments/ 2>&1 | tee -a $LOGFILE
    echo "Waiting for deployment (max. 120 sec)..."
    COUNTER=0
	while [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.deployed ] && [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.failed ]    
    do
        sleep 1
        ((COUNTER++))
        if [ $COUNTER = "120" ]; then
                break
        fi
    done

	if [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.deployed ]; then 
        echo +++WARNING+++ file not successfully deployed after $COUNTER sec, check for file: dwh-j2ee-$NEW_VERSION.ear.deployed  | tee -a $LOGFILE
    else 
        echo -e "${Gre}+++SUCCESS+++ EAR successfully deployed after $COUNTER sec${RCol}" | tee -a $LOGFILE
        echo -e "${Gre}+++UPDATE ERFOLGREICH+++ Version $NEW_VERSION ist nun installiert${RCol}" | tee -a $LOGFILE
    fi
else 
	echo +++WARNING+++ file already present, this should never happen | tee -a $LOGFILE
fi

echo
date | tee -a $LOGFILE
echo
echo Thank you for using the AKTIN software.  | tee -a $LOGFILE
echo "Please report errors to it-support@aktin.org (include $LOGFILE)" | tee -a $LOGFILE
echo
echo +++++ End of Update Procedure +++++  | tee -a $LOGFILE