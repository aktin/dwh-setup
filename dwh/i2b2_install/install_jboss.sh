#!/usr/bin/env bash

# installJBoss711

MY_PATH=/vagrant/
DATA_HOME=/vagrant/i2b2_install
LOG_DIR=/vagrant/logs
PACKAGES=/vagrant/packages

BASE_APPDIR=/opt

JBOSS_HOME=$BASE_APPDIR/jboss-as-7.1.1.Final
ANT_HOME=$BASE_APPDIR/apache-ant-1.8.2
JBOSS_LOG=$JBOSS_HOME/standalone/log/boot.log
JBOSS_LOG_2=$JBOSS_HOME/standalone/log/server.log
JBOSS_DEPLOY_DIR=$JBOSS_HOME/standalone/deployments

WEBSERVERDIRECTORY=/var/www/html
I2B2_SRC=$DATA_HOME/i2b2_src


# install needed packages


#stopJBoss
# ./jboss-cli.sh --connect --command=:shutdown > $MY_PATH/logs/jbossstop.log 2> $MY_PATH/logs/jbossstop.log &

# install
apt-get -q -y install aptitude unzip wget curl git openjdk-7-jre-headless openjdk-7-jdk apt-offline libcurl3 php5-curl apache2 libaio1 libapache2-mod-php5 perl sed bc 


# JBoss installation:

# if jboss is not installed already
if [ ! -d $JBOSS_HOME ]; then
# both jboss and axis zip files are in the data folder 
    unzip -o $PACKAGES/jboss-as-7.1.1.Final.zip -d $BASE_APPDIR > $LOG_DIR/unzip_jboss.log

    # Memory settings:
    
    FILE="$JBOSS_HOME/bin/appclient.conf"
    echo n | cp -i $FILE $FILE.orig
    sed -e '45,45s/-Xms64m -Xmx512m/-Xms512m -Xmx1024m/g' <$FILE.orig >$FILE 

    # Change JBoss server ports:
    FILE="$JBOSS_HOME/standalone/configuration/standalone.xml"
    echo n | cp -i $FILE $FILE.orig
    sed -e '296,296s/8080/9090/g;295,295s/8009/9009/g' <$FILE.orig >$FILE.tmp 

    # Binding JBoss AS 7 to all interfaces (https://stackoverflow.com/questions/6853409/binding-jboss-as-7-to-all-interfaces): 
    sed -e '280,280s/<inet-address value=\"\${jboss.bind.address:127.0.0.1}\"\/>/\<any-address\/\>/g' <$FILE.tmp >$FILE 

    # Apache Axis2 installation:    
    #mkdir $JBOSS_DEPLOY_DIR/i2b2.war
    #touch $JBOSS_DEPLOY_DIR/i2b2.war.dodeploy
            
    #cd $DATA_HOME
    
    #mkdir temp
    #unzip -o $DATA_HOME/axis2-1.6.2-war.zip -d $DATA_HOME/temp/ > $LOG_DIR/unzip_axis2.log
    #unzip -o $DATA_HOME/temp/axis2.war -d $JBOSS_DEPLOY_DIR/i2b2.war > $LOG_DIR/unzip_axis2.log
    
    #rm -r temp
            
    # To check if Axis2 is working, go to: http://localhost:9090/i2b2/services/listServices

    #cd $DATA_HOME
fi   

#deploy war
cd $DATA_HOME/deploy

cp -r i2b2.war $JBOSS_DEPLOY_DIR/i2b2.war
touch $JBOSS_DEPLOY_DIR/i2b2.war.dodeploy

cp crc-ds.xml $JBOSS_DEPLOY_DIR/
touch $JBOSS_DEPLOY_DIR/crc-ds.xml.dodeploy

cp im-ds.xml $JBOSS_DEPLOY_DIR/
touch $JBOSS_DEPLOY_DIR/im-ds.xml.dodeploy

cp ont-ds.xml $JBOSS_DEPLOY_DIR/
touch $JBOSS_DEPLOY_DIR/ont-ds.xml.dodeploy

cp pm-ds.xml $JBOSS_DEPLOY_DIR/
touch $JBOSS_DEPLOY_DIR/pm-ds.xml.dodeploy

cp work-ds.xml $JBOSS_DEPLOY_DIR/
touch $JBOSS_DEPLOY_DIR/work-ds.xml.dodeploy

cp postgresql-9.2-1002.jdbc4.jar $JBOSS_DEPLOY_DIR/
touch $JBOSS_DEPLOY_DIR/postgresql-9.2-1002.jdbc4.jar.dodeploy




#find webclient directory
if [ ! -d $WEBSERVERDIRECTORY ]; then  
    mkdir $WEBSERVERDIRECTORY
fi

# move webclient files to webdirectory
if [ ! -d "$WEBSERVERDIRECTORY/webclient" ]; then  
    cd $I2B2_SRC
    cp -r webclient $WEBSERVERDIRECTORY
    cp -r admin $WEBSERVERDIRECTORY
fi

IP_ADDR="127.0.0.1"
HIVE_ID=i2b2demo
# configure webclient


FILE=$WEBSERVERDIRECTORY/webclient/i2b2_config_data.js
if [ ! -f "$FILE.orig" ]; then  
   cp -i $FILE $FILE.orig
fi
cat $FILE.orig | sed -e 's/allowAnalysis: false/allowAnalysis: true/g;s/isSHRINE: true/isSHRINE: false/g;s/debug: false/debug: true/g;s/HarvardDemo/'"$HIVE_ID"'/g;s/i2b2demo/'"$HIVE_ID"'/g;s/webservices.i2b2.org/'"$IP_ADDR"':9090/g;s/services.i2b2.org/'"$IP_ADDR"':9090/g;s/rest/services/g' > $FILE
   
FILE=$WEBSERVERDIRECTORY/admin/i2b2_config_data.js
if [ ! -f "$FILE.orig" ]; then  
   cp -i $FILE $FILE.orig
fi
cat $FILE.orig | sed -e 's/HarvardDemo/'"$HIVE_ID"'/g;s/webservices.i2b2.org/'"$IP_ADDR"':9090/g;s/amdinOnly/adminOnly/g' > $FILE


#install ant
cd $PACKAGES
#later check whether in packages and if not download    
#   httpDownloadWizard apache-ant-1.8.2-bin.zip https://archive.apache.org/dist/ant/binaries/apache-ant-1.8.2-bin.zip e875a77c21714d36a6e445fe15d65fb2
    
# Apache ant 1.8.2 installation: 

if [ ! -d $ANT_HOME ]; then
    unzip -o $PACKAGES/apache-ant-1.8.2-bin.zip -d $BASE_APPDIR > $LOG_DIR/unzip_ant.log
fi

cd $MY_PATH 

#restart apache
/etc/init.d/apache2 restart > $LOG_DIR/apache_restart.log 2> $LOG_DIR/apache_restart.log

cd $MY_PATH 
