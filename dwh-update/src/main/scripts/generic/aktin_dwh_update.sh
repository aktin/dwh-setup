#!/usr/bin/env bash

# generic aktin dwh update to 0.7
# 28 Feb 2017
# Oldenburg

NEW_VERSION=0.7-SNAPSHOT

# Initial parameters
SCRIPT=$(readlink -f "$0")
INSTALL_ROOT=$(dirname "$SCRIPT") # current directory
WILDFLY_HOME=/opt/wildfly-${wildfly.version} # wildfly directory
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c" # jboss cli command
i2b2_WEBDIR=/var/webroot/webclient # webclient directory

LOGFILE=$INSTALL_ROOT/update.log # logfile for update log
touch $LOGFILE

echo ++++++++++++++++++++++
echo
echo AKTIN J2ee update auf $NEW_VERSION | tee -a $LOGFILE
date | tee -a $LOGFILE
echo
echo ++++++++++++++++++++++

echo
echo +++++ STEP 0 +++++ Überprüfung der Paths und Ausgabe der Status Informationen | tee -a $LOGFILE
echo
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
if ls $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.deployed 1> /dev/null 2>&1; then
    OLD_VERSION=$(ls -t $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.deployed | head -1 | sed -n -e 's#'$WILDFLY_HOME'/standalone/deployments/dwh-j2ee-##'p | sed -n -e 's#.ear.deployed$##'p)
    echo Currently deployed version is $OLD_VERSION | tee -a $LOGFILE
else
    echo +++WARNING+++ No EAR is currently deployed | tee -a $LOGFILE
fi


echo
echo +++++ STEP 0.01 +++++ Überprüfung aktin.properties  | tee -a $LOGFILE
echo
$INSTALL_ROOT/lib/check_aktin_properties.sh 2>&1 | tee -a $LOGFILE
checkexit=${PIPESTATUS[0]}
if [ $checkexit -gt 0 ]; then
    exit $checkexit
fi

# TODO sync preferences (this or separate step): for each property in new aktin.properties check if exists in old one, if not append!
# TODO make list of properties which NEED to be changed and make sure that they are changed.


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


echo
echo +++++ STEP 2.01 +++++ Fact Database Reset| tee -a $LOGFILE
echo
# XXX not supported yet - NOP
# check id length and delete facts with "short" ids

echo
echo +++++ STEP 2.02 +++++ Update local DWH ontology | tee -a $LOGFILE
echo
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
rm -r $CDATMPDIR
echo "- Ontology Update done. Result logged in $SQLLOG"

echo
echo +++++ STEP 2.03 +++++ Entfernen der Defaulteinträge in Loginformular | tee -a $LOGFILE
echo
# check wether the login username needs to be removed. 
if [ $(grep -c "name=\"uname\" id=\"loginusr\" value=\"demo\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
then
    echo "- Username bereits entfernt. NOP" | tee -a LOGFILE
else 
    if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
       cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
       echo "- Webclient PM file backed up" 2>&1 | tee -a $LOGFILE
    fi
    sed -i "s/name=\"uname\" id=\"loginusr\" value=\"demo\"/name=\"uname\" id=\"loginusr\" value=\"\"/g" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js
    if [ $(grep -c "name=\"uname\" id=\"loginusr\" value=\"demo\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
    then 
        echo "+++WARNING+++ Username konnte nicht erfolgreich entfernt werden" | tee -a LOGFILE
    else 
        echo -e "- Username wurde entfernt" | tee -a LOGFILE
        # $(grep -c "name=\"uname\" id=\"loginusr\" value=\"demo\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) occurences 
        # $(grep -oE "<input .* name=\"uname\" id=\"loginusr\".* />" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js)
    fi
fi
# same for the password
if [ $(grep -c "name=\"pword\" id=\"loginpass\" value=\"demouser\"" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js) -gt 0 ]
then
    echo "- Password bereits entfernt. NOP" | tee -a LOGFILE
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
        echo -e "- Passwort entfernt" | tee -a LOGFILE
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
echo +++++ STEP 2.06 +++++  Create /var/lib/aktin  | tee -a $LOGFILE
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
echo +++++ STEP 2.07 +++++  Add new SMTP configuration | tee -a $LOGFILE
echo
$INSTALL_ROOT/lib/email_create.sh 2>&1 | tee -a $LOGFILE

echo
echo +++++ STEP 3 +++++  Stop Wildfly Service | tee -a $LOGFILE
echo
service wildfly stop 2>&1 | tee -a $LOGFILE
# wait 5 seconds
#sleep 5
echo wildfly stopped | tee -a $LOGFILE

echo
echo "+++++ STEP 4 +++++  Remove all dwh.ear[*] (including .failed, .deployed, .undeployed)" | tee -a $LOGFILE
echo
rm -v $WILDFLY_HOME/standalone/deployments/dwh-j2ee-* 2>&1 | tee -a $LOGFILE
if ls dwh-j2ee-* 1> /dev/null 2>&1; then 
    echo +++WARNING+++ EAR files not completely removed | tee -a $LOGFILE
else
    echo EAR files removed | tee -a $LOGFILE
fi

echo
echo +++++ STEP 5 +++++  Start Wildfly Service | tee -a $LOGFILE
echo
service wildfly start
echo wildfly restarted | tee -a $LOGFILE

echo
echo +++++ STEP 6 +++++  Deploy new dwh-j2ee EAR | tee -a $LOGFILE
echo
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear" ]; then 
	cp -v $INSTALL_ROOT/packages/dwh-j2ee-$NEW_VERSION.ear $WILDFLY_HOME/standalone/deployments/ 2>&1 | tee -a $LOGFILE
    echo "Waiting for deployment (max. 60 sec)..."
    COUNTER=0
	while [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.deployed ] && [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.failed ]    
    do
        sleep 1
        ((COUNTER++))
        if [ $COUNTER = "60" ]; then
                break
        fi
    done

	if [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.deployed ]; then 
        echo +++WARNING+++ file not successfully deployed, check for file: dwh-j2ee-$NEW_VERSION.ear.deployed  | tee -a $LOGFILE
    else 
        echo EAR successfully deployed | tee -a $LOGFILE
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