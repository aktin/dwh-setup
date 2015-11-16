/opt/apache-ant-1.8.2/bin/ant -f data_build.xml db_pmdata_load_data 2> $MY_PATH/logs/db_pmdata_load_data.err.log > $MY_PATH/logs/db_pmdata_load_data.log


IM 
DEMO -> CRC
HIVE    		x
PM   			x
meta 			x
work 			x








# Fix bugs in the i2b2 1.7 data:

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/procedures/oracle/INSERT_EID_MAP_FROMTEMP.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "\"I2B2DEMODATA\".\"INSERT_EID_MAP_FROMTEMP\"" "INSERT_EID_MAP_FROMTEMP";
	
		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/procedures/oracle/UPDATE_OBSERVATION_FACT.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "\"I2B2DEMODATA\".\"UPDATE_OBSERVATION_FACT\"" "UPDATE_OBSERVATION_FACT";

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/procedures/postgresql/CREATE_TEMP_PROVIDER_TABLE.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "CREATE_TEMP_PROVIDER_TABLE.sql" " ";
	
		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/work_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2workdata";
	
		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/ont_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2metadata";

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/im_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2imdata";

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/crc_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2demodata";








17:08:51,386 ERROR [stderr] (Thread-74)         at org.postgresql.jdbc2.AbstractJdbc2Statement.execute(AbstractJdbc2Sta
ement.java:555)
17:08:51,386 ERROR [stderr] (Thread-74)         at org.postgresql.jdbc2.AbstractJdbc2Statement.executeWithFlags(Abstrac
Jdbc2Statement.java:417)
17:08:51,519 ERROR [stderr] (Thread-74)         at org.postgresql.jdbc2.AbstractJdbc2Statement.executeQuery(AbstractJdb
2Statement.java:302)
17:08:51,520 ERROR [stderr] (Thread-74)         at org.jboss.jca.adapters.jdbc.WrappedPreparedStatement.executeQuery(Wr
ppedPreparedStatement.java:462)
17:08:51,521 ERROR [stderr] (Thread-74)         at edu.harvard.i2b2.crc.ejb.ProcessQueue.run(ProcessQueue.java:136)
17:08:51,528 ERROR [stderr] (Thread-72) org.postgresql.util.PSQLException: ERROR: relation "public.qt_query_master" doe
 not exist
17:08:51,528 ERROR [stderr] (Thread-72)   Position: 144
17:08:51,529 ERROR [stderr] (Thread-72)         at org.postgresql.core.v3.QueryExecutorImpl.receiveErrorResponse(QueryE
ecutorImpl.java:2157)
17:08:51,530 ERROR [stderr] (Thread-72)         at org.postgresql.core.v3.QueryExecutorImpl.processResults(QueryExecuto
Impl.java:1886)
17:08:51,534 ERROR [stderr] (Thread-72)         at org.postgresql.core.v3.QueryExecutorImpl.execute(QueryExecutorImpl.j
va:255)
17:08:51,580 ERROR [stderr] (Thread-72)         at org.postgresql.jdbc2.AbstractJdbc2Statement.execute(AbstractJdbc2Sta
ement.java:555)
17:08:51,597 ERROR [stderr] (Thread-72)         at org.postgresql.jdbc2.AbstractJdbc2Statement.executeWithFlags(Abstrac
Jdbc2Statement.java:417)
17:08:51,598 ERROR [stderr] (Thread-72)         at org.postgresql.jdbc2.AbstractJdbc2Statement.executeQuery(AbstractJdb
2Statement.java:302)
17:08:51,602 ERROR [stderr] (Thread-72)         at org.jboss.jca.adapters.jdbc.WrappedPreparedStatement.executeQuery(Wr
ppedPreparedStatement.java:462)
17:08:51,639 ERROR [stderr] (Thread-72)         at edu.harvard.i2b2.crc.ejb.ProcessQueue.run(ProcessQueue.java:136)
17:08:51,642 ERROR [stderr] (Thread-74) org.postgresql.util.PSQLException: ERROR: relation "public.qt_query_master" doe
 not exist


 


# --------- Load "Metadata" ---------

	progressBar 15 "Loading Metadata (takes very long, progressbar may look stuck) ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Metadata/ 

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_metadata_tables_release_$I2B2RELEASE > $MY_PATH/logs/bostonload2.log 2> $MY_PATH/logs/bostonload2.err.log
	#Ignore any error here:
	errorHandler $LINENO "create_metadata_tables_release_$I2B2RELEASE" $MY_PATH/logs/bostonload2.log $MY_PATH/logs/bostonload2.err.log
	
	progressBar 20 "Loading Metadata (takes very long, progressbar may look stuck) ..."
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_metadata_load_data > $MY_PATH/logs/bostonload3.log 2> $MY_PATH/logs/bostonload3.err.log
	#Ignore any error here:
	errorHandler $LINENO "db_metadata_load_data" $MY_PATH/logs/bostonload3.log $MY_PATH/logs/bostonload3.err.log








# was macht IM? Daten laden?


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

#


DB_SERVER=localhost
DB_PORT=5432
DB_SYSUSER=postgres
DB_SYSPASS=i2b2


installPostgreSQL() {

	autoPackageInstall verbose 'postgresql'
	-->
	apt-get -q -y install aptitude $i > $MY_PATH/logs/autoPackageInstall_$i.log 2> $MY_PATH/logs/autoPackageInstall_$i.err.log
					A="aptitude search '~i ^$i\$'"
	
# change psql user password
	sudo -u postgres psql -c "alter user $DB_SYSUSER with password '$DB_SYSPASS';"  > $MY_PATH/logs/config_postgres1.log 2> $MY_PATH/logs/config_postgres1.err.log

#create db
	sudo -u postgres createdb i2b2 > $MY_PATH/logs/config_postgres2.log 2> $MY_PATH/logs/config_postgres2.err.log



# --------- Create users for project "Demo" ---------
	progressBar 5 "Creating schema I2B2DEMODATA ..."

	# Create user I2B2DEMODATA
	
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
  
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2DEMODATA"'/g;s/I2B2DB_PWD/'"i2b2demodata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (1)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log
	
	progressBar 7 "Creating schema I2B2METADATA ..."

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	rm $FILE
	mv $FILE.orig $FILE

	# ---
	
	# Create user I2B2METADATA
	
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2METADATA"'/g;s/I2B2DB_PWD/'"i2b2metadata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (2)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

	progressBar 9 "Enabling full text indexing ..."

	
	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	progressBar 11 "Creating schema I2B2WORKDATA ..."
	
	rm $FILE
	mv $FILE.orig $FILE

	# ---
	# Create user I2B2WORKDATA
	
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2WORKDATA"'/g;s/I2B2DB_PWD/'"i2b2workdata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (3)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	progressBar 13 "Creating schema IMDATA ..."

	
	rm $FILE
	mv $FILE.orig $FILE

	# Creating User IMDATA
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
 
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2IMDATA"'/g;s/I2B2DB_PWD/'"i2b2imdata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (4)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	#checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi
	
	rm $FILE
	mv $FILE.orig $FILE





# --------- Create users $HIVE_SCHEMA and $PM_SCHEMA---------
	
	# Creating User $PM_SCHEMA
	progressBar 10 "Creating User $PM_SCHEMA ..."
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
  
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"$PM_SCHEMA"'/g;s/I2B2DB_PWD/'"$PM_PASS"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (5)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	rm $FILE
	mv $FILE.orig $FILE
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

    	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	
	# Creating User $HIVE_SCHEMA
	progressBar 15 "Creating User $HIVE_SCHEMA ..."
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
 
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"$HIVE_SCHEMA"'/g;s/I2B2DB_PWD/'"$HIVE_PASS"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (6)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1B.err.log > $MY_PATH/logs/loadhive1B.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1B.log $MY_PATH/logs/loadhive1B.err.log

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi
	
	rm $FILE
	mv $FILE.orig $FILE
	

	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS
