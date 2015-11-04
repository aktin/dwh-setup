


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
