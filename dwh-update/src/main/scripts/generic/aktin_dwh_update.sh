#!/usr/bin/env bash

NEW_VERSION=0.7

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"
i2b2_WEBDIR=/var/webroot/webclient

LOGFILE=$install_root/update.log
touch $LOGFILE
echo ++++++++++++++++++++++
echo
echo AKTIN J2ee update to $NEW_VERSION | tee -a $LOGFILE
date | tee -a $LOGFILE
echo
echo ++++++++++++++++++++++

echo
echo +++++ STEP 0 +++++ Check Paths and Log Status Information | tee -a $LOGFILE
echo
if [ ! -d "$WILDFLY_HOME" ]; then 
    echo +++ERROR+++ WILDFLY Home directory not in default location, check paths! Exiting update procedure... | tee -a $LOGFILE
    exit 126 #Command invoked cannot execute
else
    echo WILDFLY Home directory checked | tee -a $LOGFILE
fi
if [ ! -d "$i2b2_WEBDIR" ]; then 
    echo +++ERROR+++ i2b2 Web directory not in default location, check paths! Exiting update procedure... | tee -a $LOGFILE
    exit 126 #Command invoked cannot execute
else
    echo i2b2 Web directory checked | tee -a $LOGFILE
fi
# XXX check more paths? (compatible linux distribution?)
# XXX check if "service" command is available

#OLD_VERSION=$(ls -t $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.deployed | head -1 | sed -n -e 's/$WILDFLY_HOME/standalone/deployments/dwh-j2ee-//'p | sed -n -e 's/.ear.deployed$//'p)
#if ls $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.deployed 1> /dev/null 2>&1; then 
#    echo Currently deployed version is $OLD_VERSION | tee -a $LOGFILE
#else
#    echo +++WARNING+++ No EAR is currently deployed | tee -a $LOGFILE
#fi

echo
echo +++++ STEP 1 +++++ Undeploy all old dwh-j2ee EARs | tee -a $LOGFILE
echo
for i in $(cd $WILDFLY_HOME/standalone/deployments/ && ls -t dwh-j2ee-*.deployed); 
    do
            ear=$(echo $i | sed 's/.deployed$//')
            echo undeploying: $ear | tee -a $LOGFILE            
            $JBOSSCLI "undeploy --name=$ear" 2>&1 | tee -a $LOGFILE
            echo
    done

echo
echo "+++++ STEP 2 +++++ Execute scripts (SQL, Copy files etc.)" | tee -a $LOGFILE
echo

echo
echo +++++ STEP 2.01 +++++ Fact Database Reset | tee -a $LOGFILE
echo
# XXX not supported yet
# check id length and delete facts with "short" ids

echo
echo +++++ STEP 2.02 +++++ Update local DWH ontology | tee -a $LOGFILE
echo
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
CDATMPDIR=/var/tmp/cda-ontology
mkdir $CDATMPDIR
touch update_sql.log
echo update ontology to ${org.aktin:cda-ontology:jar.version} 2>&1 | tee -a update_sql.log
# unzip the sql jar 
unzip $install_root/packages/cda-ontology-${org.aktin:cda-ontology:jar.version}.jar -d $CDATMPDIR
cp remove_test_ont.sql $CDATMPDIR/sql/remove_test_ont.sql
chmod 777 -R $CDATMPDIR
# call sql script files. no console output
echo remove test ontology 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/remove_test_ont.sql" 2>&1 >> update_sql.log
echo update metadata 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" 2>&1 >> update_sql.log
echo update crcdata 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" 2>&1 >> update_sql.log
# remove temp directory
rm -r $CDATMPDIR
echo Ontology Update done. Result logged in update_sql.log

echo
echo +++++ STEP 2.03 +++++ Remove login form defaults | tee -a $LOGFILE
echo
# xxx check if necessary
#if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
#	cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
#	echo "Webclient PM file backed up" 2>&1 | tee -a $LOGFILE
#fi
#sed -i "s/name=\"uname\" id=\"loginusr\" value=\"demo\"/name=\"uname\" id=\"loginusr\" value=\"\"/g; s/name=\"pword\" id=\"loginpass\" value=\"demouser\"/name=\"pword\" id=\"loginpass\" value=\"\"/g" #$i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js
# xxx check result?

echo
echo +++++ STEP 2.04 +++++ Create AKTIN Database in postgres | tee -a $LOGFILE
echo
cp "$install_root/postgres_db_script.sh" /var/tmp/
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
	echo "removed older aktin datasource " | tee -a $LOGFILE
fi
# XXX does this work without wildfly reload???

$JBOSSCLI --file=create_aktin_datasource.cli 2>&1 | tee -a $LOGFILE
# xxx check result? echo "created aktin datasource" | tee -a $LOGFILE
# $WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --commands="reload" 2>&1 | tee -a $LOGFILE
# echo "reload" 2>&1 | tee -a $LOGFILE

echo
echo +++++ STEP 2.06 +++++  Copy aktin.properties  | tee -a $LOGFILE
echo
# copy aktin.properties into the wildfly configuration folder
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	cp -v $install_root/aktin.properties $WILDFLY_HOME/standalone/configuration/aktin.properties 2>&1 | tee -a $LOGFILE
	if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
        echo +++WARNING+++ properties file not copied | tee -a $LOGFILE
	else
        echo properties file successfully copied | tee -a $LOGFILE
    fi
else 
	#Kopieren abgebrochen, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist.
	echo aktin.properties already present,  not copied | tee -a $LOGFILE
fi

# TODO sync preferences (this or separate step): for each property in new aktin.properties check if exists in old one, if not append!
# TODO make list of properties which NEED to be changed and make sure that they are changed. 

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
echo +++++ STEP 2.08 +++++  SMTP configuration | tee -a $LOGFILE
echo
# xxx check if necessary
# xxx Raphael
# . $install_root/smtp_setup_config.sh
# xxx check result?

echo
echo +++++ STEP 3 +++++  Stop Wildfly Service | tee -a $LOGFILE
echo
service wildfly stop 2>&1 | tee -a $LOGFILE
# wait 5 seconds
#sleep 5
echo wildfly stopped | tee -a $LOGFILE

echo
echo +++++ STEP 4 +++++  Remove all dwh.ear, dwh.ear.failed, dwh.ear.undeployed | tee -a $LOGFILE
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
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_EAR.ear" ]; then 
	cp -v $install_root/packages/dwh-j2ee-*.ear $WILDFLY_HOME/standalone/deployments/ 2>&1 | tee -a $LOGFILE
    echo Waiting for deployment...  | tee -a $LOGFILE
	while [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.ear.deployed ] && [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.ear.failed ]    
    do
        sleep 1
    done
	if [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.ear.deployed ]; then 
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