#!/usr/bin/env bash

# first

# installJBoss711

MY_PATH=/vagrant/

chmod +x $MY_PATH/i2b2_install/install.conf
. $MY_PATH/i2b2_install/install.conf



#install ant
echo install ant
cd $PACKAGES
#later check whether in packages and if not download    
#   httpDownloadWizard apache-ant-1.8.2-bin.zip https://archive.apache.org/dist/ant/binaries/apache-ant-1.8.2-bin.zip e875a77c21714d36a6e445fe15d65fb2
    
# Apache ant 1.8.2 installation: 

if [ ! -d $ANT_HOME ]; then
    unzip -o $PACKAGES/apache-ant-1.8.2-bin.zip -d $BASE_APPDIR > $LOG_DIR/unzip_ant.log
fi



#stopJBoss
# ./jboss-cli.sh --connect --command=:shutdown > $MY_PATH/logs/jbossstop.log 2> $MY_PATH/logs/jbossstop.log &

# install
apt-get -q -y install aptitude unzip wget curl git openjdk-7-jre-headless  apt-offline libcurl3 php5-curl apache2 libaio1 libapache2-mod-php5 perl sed bc # openjdk-7-jdk


# JBoss installation:

# if jboss is not installed already
if [ ! -d $JBOSS_HOME ]; then
# both jboss and axis zip files are in the data folder 
    unzip -o $PACKAGES/jboss-as-7.1.1.Final.zip -d $BASE_APPDIR > $LOG_DIR/unzip_jboss.log

    # Memory settings:
    
    FILE="$JBOSS_HOME/bin/appclient.conf"
    if [ -f "$FILE.orig" ]; then  
        rm $FILE.orig
    fi
    echo n | cp -i $FILE $FILE.orig
    sed -e '45,45s/-Xms64m -Xmx512m/-Xms512m -Xmx1024m/g' <$FILE.orig >$FILE 

    # Change JBoss server ports:
    FILE="$JBOSS_HOME/standalone/configuration/standalone.xml"
    if [ -f "$FILE.orig" ]; then  
        rm $FILE.orig
    fi
    echo n | cp -i $FILE $FILE.orig
    sed -e '296,296s/8080/9090/g;295,295s/8009/9009/g' <$FILE.orig >$FILE.tmp 

    # Binding JBoss AS 7 to all interfaces (https://stackoverflow.com/questions/6853409/binding-jboss-as-7-to-all-interfaces): 
    sed -e '280,280s/<inet-address value=\"\${jboss.bind.address:127.0.0.1}\"\/>/\<any-address\/\>/g' <$FILE.tmp >$FILE 

    # Apache Axis2 installation:    
    mkdir $JBOSS_DEPLOY_DIR/i2b2.war
    touch $JBOSS_DEPLOY_DIR/i2b2.war.dodeploy
    
    cd $DATA_HOME
    
    mkdir $PACKAGES/temp/
    unzip -o $PACKAGES/axis2-1.6.2-war.zip -d $PACKAGES/temp/ > $LOG_DIR/unzip_axis2.log
    unzip -o $PACKAGES/temp/axis2.war -d $JBOSS_DEPLOY_DIR/i2b2.war > $LOG_DIR/unzip_axis2.log
    
    rm -r $PACKAGES/temp/
            
    # To check if Axis2 is working, go to: http://localhost:9090/i2b2/services/listServices

    #cd $DATA_HOME

    # unpack configurations and deployments
    unzip -o $PACKAGES/jboss-configuration-slim.zip -d $JBOSS_HOME/standalone > $LOG_DIR/unzip_jboss_config.log
    unzip -o $PACKAGES/jboss-deployment-xml.zip -d $JBOSS_DEPLOY_DIR/ > $LOG_DIR/unzip_jboss_deploy_xml.log
    unzip -o $PACKAGES/jboss-deployment-i2b2war-WEB-INF.zip -d $JBOSS_DEPLOY_DIR/i2b2.war > $LOG_DIR/unzip_jboss_deploy_webinf.log
    cp $PACKAGES/postgresql-9.2-1002.jdbc4.jar $JBOSS_DEPLOY_DIR/

    # deploy
#    cd $JBOSS_HOME
#    tar xvfz $PACKAGES/jboss-configuration.tar.gz
#    tar xvfz $PACKAGES/jboss-deployments.tar.gz

fi    

# unzip i2b2 to i2b2_src
if [ ! -d "$I2B2_SRC" ]; then  

    mkdir $I2B2_SRC
    # need this for admin
    unzip -o $PACKAGES/i2b2core-src-1705.zip -d $I2B2_SRC > $LOG_DIR/unzip_i2b2_core.log
    # data base structure
    unzip -o $PACKAGES/i2b2createdb-1705.zip -d $I2B2_SRC > $LOG_DIR/unzip_i2b2_core.log
    # webclient
    unzip -o $PACKAGES/i2b2webclient-1705.zip -d $I2B2_SRC > $LOG_DIR/unzip_i2b2_core.log

fi

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

# configure webclient
echo configure webclient
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


#restart apache
echo restart apache
/etc/init.d/apache2 restart > $LOG_DIR/apache_restart.log 2> $LOG_DIR/apache_restart.log

rm -r $DATA_HOME/jboss
cp -r $JBOSS_HOME $DATA_HOME/jboss

cd $DATA_HOME

. ./i2b2_db_full_install.sh 
