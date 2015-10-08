/opt/apache-ant-1.8.2/bin/ant -f data_build.xml db_pmdata_load_data 2> $MY_PATH/logs/db_pmdata_load_data.err.log > $MY_PATH/logs/db_pmdata_load_data.log








	# ---------------- IM: ----------------

	FILE="$I2B2_SRC/edu.harvard.i2b2.im/etc/spring/im.properties"

		sed -e 's/imschema=i2b2hive/imschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Modify I2B2HIVE schema for I2B2IM, non-MSSQL"



	# ---------------- CRC: ---------------- 

	#Edit CRCLoaderApplicationContext.xml

	FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/CRCLoaderApplicationContext.xml"

	sed -e '32,32s/jdbc:oracle:thin:@127.0.0.1:1521:XE/jdbc:postgresql:\/\/localhost:5432\/i2b2?searchpath='"$HIVE_SCHEMA"'/g;31,31s/oracle.jdbc.driver.OracleDriver/org.postgresql.Driver/g;34,34s/demouser/'"$HIVE_PASS"'/g;33,33s/i2b2hive/'"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change DB connection, Postgres"


	#Edit edu.harvard.i2b2.crc.loader.properties

	FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/edu.harvard.i2b2.crc.loader.properties"


		sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g;s/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=ORACLE/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=PostgreSQL/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change servertype setting to PostgreSQL"



	#Edit crc.properties

	FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/crc.properties"

		sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g;s/queryprocessor.ds.lookup.servertype=ORACLE/queryprocessor.ds.lookup.servertype=PostgreSQL/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change queryprocessor setting to PostgreSQL"


	# ---------------- ONT: ----------------

	FILE="$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/ontology.properties"

		sed -e 's/metadataschema=i2b2hive/metadataschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Set metadataschema I2B2HIVE schema"

		
    FILE="$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/OntologyApplicationContext.xml"

		sed -e '23,23s/jdbc:oracle:thin:@localhost:1521:xe/jdbc:postgresql:\/\/localhost\/i2b2?searchpath=i2b2metadata/g;22,22s/oracle.jdbc.driver.OracleDriver/org.postgresql.Driver/g;24,24s/metadata_uname/i2b2metadata/g;25,25s/demouser/i2b2metadata/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Configure database connection, POSTGRESQL"

	


	# ---------- Deploy edu.harvard.i2b2.server-common: ---------- 

	progressBar 10 "Deploying edu.harvard.i2b2.server-common ..."

	#checkJavaInstallation

	cd $I2B2_SRC/edu.harvard.i2b2.server-common/
	
	$ANT_HOME/bin/ant clean dist deploy jboss_pre_deployment_setup > $MY_PATH/logs/deploy1.log 2> $MY_PATH/logs/deploy1.err.log

	cd $MY_PATH

	errorHandler $LINENO "Deploy edu.harvard.i2b2.server-common" $MY_PATH/logs/deploy1.log $MY_PATH/logs/deploy1.err.log
	
	# ---------- Deploy edu.harvard.i2b2.pm: ---------- 

	progressBar 20 "Deploying edu.harvard.i2b2.pm ..."

	cd $I2B2_SRC/edu.harvard.i2b2.pm/

	#checkJavaInstallation

    	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy2.log 2> $MY_PATH/logs/deploy2.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.pm" $MY_PATH/logs/deploy2.log $MY_PATH/logs/deploy2.err.log
	
	# http://localhost:9090/i2b2/services/listServices
	# should now list: PMService

	# ---------- Deploy edu.harvard.i2b2.ontology: ---------- 

	progressBar 30 "Deploying edu.harvard.i2b2.ontology ..."

	cd $I2B2_SRC/edu.harvard.i2b2.ontology/
	

	#checkJavaInstallation
        
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy3.log 2> $MY_PATH/logs/deploy3.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.ontology" $MY_PATH/logs/deploy3.log $MY_PATH/logs/deploy3.err.log

	# ---------- Deploy edu.harvard.i2b2.im: ---------- 

	progressBar 45 "Deploying edu.harvard.i2b2.im ..."

	cd $I2B2_SRC/edu.harvard.i2b2.im/

	#checkJavaInstallation
    	
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy4.log 2> $MY_PATH/logs/deploy4.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.im" $MY_PATH/logs/deploy4.log $MY_PATH/logs/deploy4.err.log

	# ---------- Deploy edu.harvard.i2b2.crc: ---------- 

	progressBar 60 "Deploying edu.harvard.i2b2.crc ..."

	cd $MY_PATH

	cd $I2B2_SRC/edu.harvard.i2b2.crc/

	#checkJavaInstallation

    $ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy5.log 2> $MY_PATH/logs/deploy5.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.crc" $MY_PATH/logs/deploy5.log $MY_PATH/logs/deploy5.err.log

	# ---------- Deploy edu.harvard.i2b2.workplace: ---------- 

	progressBar 80 "Deploying edu.harvard.i2b2.workplace ..."

	cd $I2B2_SRC/edu.harvard.i2b2.workplace/
	
	#checkJavaInstallation
    	
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy6.log 2> $MY_PATH/logs/deploy6.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.workplace" $MY_PATH/logs/deploy6.log $MY_PATH/logs/deploy6.err.log

	# ---------- Deploy edu.harvard.i2b2.fr: ---------- 

	progressBar 90 "Deploying edu.harvard.i2b2.fr ..."

	cd $I2B2_SRC/edu.harvard.i2b2.fr/
	
	#checkJavaInstallation
    	
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy7.log 2> $MY_PATH/logs/deploy7.err.log
	
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.fr" $MY_PATH/logs/deploy7.log $MY_PATH/logs/deploy7.err.log