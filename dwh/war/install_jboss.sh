#!/usr/bin/env bash

# installJBoss711

DATA_HOME=/vagrant/war
ANT_HOME=/opt/apache-ant-1.8.2
LOG_DIR=$DATA_HOME/logs

BASE_APPDIR=/opt

JBOSS_HOME=$BASE_APPDIR/jboss-as-7.1.1.Final
ANT_HOME=$BASE_APPDIR/apache-ant-1.8.2
JBOSS_LOG=$JBOSS_HOME/standalone/log/boot.log
JBOSS_LOG_2=$JBOSS_HOME/standalone/log/server.log
	
	# httpDownloadWizard $MY_PATH/packages/jboss-as-7.1.1.Final.zip http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip 175c92545454f4e7270821f4b8326c4e

	# httpDownloadWizard $MY_PATH/packages/axis2-1.6.2-war.zip http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist//axis/axis2/java/core/1.6.2/axis2-1.6.2-war.zip 7c1ef0245c4e13ac04cee47583bc5406
	
    # JBoss installation:
   
    if [ ! -d $JBOSS_HOME ]; then
    	updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'JBoss' (from ZIP file) ..." 5 60
       
        unzip -o $DATA_HOME/jboss-as-7.1.1.Final.zip -d $BASE_APPDIR > $LOG_DIR/unzip_jboss.log
    
        # Memory settings:
        
        FILE="$JBOSS_HOME/bin/appclient.conf"
        echo n | cp -i $FILE $FILE.orig
        sed -e '45,45s/-Xms64m -Xmx512m/-Xms512m -Xmx1024m/g' <$FILE.orig >$FILE 

        # Change JBoss server ports:
        FILE="$JBOSS_HOME/standalone/configuration/standalone.xml"
        echo n | cp -i $FILE $FILE.orig
        sed -e '296,296s/8080/9090/g;295,295s/8009/9009/g' <$FILE.orig >$FILE.tmp 
		checkFileChanged $FILE.orig $FILE.tmp "JBoss installation: Change JBoss server port"

		# Binding JBoss AS 7 to all interfaces (https://stackoverflow.com/questions/6853409/binding-jboss-as-7-to-all-interfaces): 
        sed -e '280,280s/<inet-address value=\"\${jboss.bind.address:127.0.0.1}\"\/>/\<any-address\/\>/g' <$FILE.tmp >$FILE 
		checkFileChanged $FILE.tmp $FILE "JBoss installation: Allow JBoss 7 to bind to all network interfaces"
		
        # Apache Axis2 installation:    
        mkdir $JBOSS_HOME/standalone/deployments/i2b2.war
		touch $JBOSS_HOME/standalone/deployments/i2b2.war.dodeploy
				
		cd $DATA_HOME
		
		mkdir temp
		unzip -o $DATA_HOME/axis2-1.6.2-war.zip -d $DATA_HOME/temp/ > $LOG_DIR/unzip_axis2.log
    	unzip -o $MY_PATH/temp/axis2.war -d $JBOSS_HOME/standalone/deployments/i2b2.war > $LOG_DIR/unzip_axis2.log
		
		rm -r temp
				
        # To check if Axis2 is working, go to: http://localhost:9090/i2b2/services/listServices
    
		cd $MY_PATH
    fi   
