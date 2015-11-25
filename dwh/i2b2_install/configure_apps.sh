#!/usr/bin/env bash

# installJBoss711

MY_PATH=/vagrant/

chmod +x $MY_PATH/i2b2_install/install.conf
. $MY_PATH/i2b2_install/install.conf

# set configurations

# Working-Directories for i2b2 Webservices: 
IM_APPDIR=$JBOSS_HOME/standalone/configuration/imapp
CRC_APPDIR=$JBOSS_HOME/standalone/configuration/crcapp
FR_APPDIR=$JBOSS_HOME/standalone/configuration/frapp
ONT_APPDIR=$JBOSS_HOME/standalone/configuration/ontologyapp
WORK_APPDIR=$JBOSS_HOME/standalone/configuration/workplaceapp

IM_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.im/etc/spring/im_application_directory.properties
CRC_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/crc_application_directory.properties
FR_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.fr/etc/spring/fr_application_directory.properties
ONT_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/ontology_application_directory.properties
WORK_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.workplace/etc/spring/workplace_application_directory.properties

cd $DATA_HOME

cat $DATA_HOME/ds-config/pm-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' > $I2B2_SRC/edu.harvard.i2b2.pm/etc/jboss/pm-ds.xml
cat $DATA_HOME/ds-config/ont-ds.xml| sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.ontology/etc/jboss/ont-ds.xml
cat $DATA_HOME/ds-config/crc-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.crc/etc/jboss/crc-ds.xml
#cat $DATA_HOME/ds-config/crc-jms-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g' >  $I2B2_SRC/edu.harvard.i2b2.crc/etc/jboss/crc-jms-ds.xml
cat $DATA_HOME/ds-config/work-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.workplace/etc/jboss/work-ds.xml
cat $DATA_HOME/ds-config/im-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.im/etc/jboss/im-ds.xml


# configure working paths:
echo "edu.harvard.i2b2.im.applicationdir=$IM_APPDIR" > $IM_APPDIR_FILE
echo "edu.harvard.i2b2.crc.applicationdir=$CRC_APPDIR" > $CRC_APPDIR_FILE
echo "edu.harvard.i2b2.frapplicationdir=$FR_APPDIR" > $FR_APPDIR_FILE
echo "edu.harvard.i2b2.ontology.applicationdir=$ONT_APPDIR" > $ONT_APPDIR_FILE
echo "edu.harvard.i2b2.workplace.applicationdir=$WORK_APPDIR" > $WORK_APPDIR_FILE
    
# modify files to allow custom PM and HIVE schemas:

# ---------------- IM: ----------------

FILE="$I2B2_SRC/edu.harvard.i2b2.im/etc/spring/im.properties"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi    

sed -e 's/imschema=i2b2hive/imschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 

# ---------------- CRC: ---------------- 

#Edit CRCLoaderApplicationContext.xml

FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/CRCLoaderApplicationContext.xml"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi    

sed -e '32,32s/jdbc:oracle:thin:@127.0.0.1:1521:XE/jdbc:postgresql:\/\/localhost:5432\/i2b2?searchpath='"$HIVE_SCHEMA"'/g;31,31s/oracle.jdbc.driver.OracleDriver/org.postgresql.Driver/g;34,34s/demouser/'"$HIVE_PASS"'/g;33,33s/i2b2hive/'"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 

#Edit edu.harvard.i2b2.crc.loader.properties

FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/edu.harvard.i2b2.crc.loader.properties"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi    

sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g;s/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=ORACLE/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=PostgreSQL/g' <$FILE.orig >$FILE 

#Edit crc.properties

FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/crc.properties"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi    

sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g;s/queryprocessor.ds.lookup.servertype=ORACLE/queryprocessor.ds.lookup.servertype=PostgreSQL/g' <$FILE.orig >$FILE   

# ---------------- ONT: ----------------

FILE="$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/ontology.properties"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi    

sed -e 's/metadataschema=i2b2hive/metadataschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 

FILE="$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/OntologyApplicationContext.xml"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi 

sed -e '23,23s/jdbc:oracle:thin:@localhost:1521:xe/jdbc:postgresql:\/\/localhost\/i2b2?searchpath=i2b2metadata/g;22,22s/oracle.jdbc.driver.OracleDriver/org.postgresql.Driver/g;24,24s/metadata_uname/i2b2metadata/g;25,25s/demouser/i2b2metadata/g' <$FILE.orig >$FILE 
   
# ---------------- WORK: ----------------
    
FILE="$I2B2_SRC/edu.harvard.i2b2.workplace/etc/spring/workplace.properties"
if [ ! -f "$FILE.orig" ]; then  
    cp -i $FILE $FILE.orig
fi    

sed -e 's/metadataschema=i2b2hive/metadataschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 

# copy property files to jboss 


# configure working paths:

cp -r $I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/* $CRC_APPDIR
rm $CRC_APPDIR/crc_application_directory.properties

cp -r $I2B2_SRC/edu.harvard.i2b2.fr/etc/spring/* $FR_APPDIR
rm $FR_APPDIR/fr_application_directory.properties		

cp -r $I2B2_SRC/edu.harvard.i2b2.im/etc/spring/* $IM_APPDIR
rm $IM_APPDIR/im_application_directory.properties

cp -r $I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/* $ONT_APPDIR
rm $ONT_APPDIR/ontology_application_directory.properties

cp -r $I2B2_SRC/edu.harvard.i2b2.workplace/etc/spring/* $WORK_APPDIR
rm $WORK_APPDIR/workplace_application_directory.properties

