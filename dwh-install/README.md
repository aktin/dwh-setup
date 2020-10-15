Virtuelle Maschine fuer Data Warehouse
======================================

Erstellung der Packete
----------------------
In dwh-install ein Maven clean install durchführen:
```
mvn clean install
```
Dabei wird ein Datei mit dem Namen `dwh-install-0.1-SNAPSHOT-full.tar.gz` erstellt. Mittels `tar -zxvf` entpackt, erhält man den vollständigen `aktin-dwh-snapshot`, wobei alle benötigten Pakete bereits in `aktin-dwh-snapshot/packages/` enthalten sind. 
Mit dem Befehl 
```
mvn install -P profile-name,second-profile-name
```
kann man einzelne oder mehrere Installierprofile aufrufen. Mit z.B. `mvn install -P aktin-installer,aktin-package-only` werden zwei Pakete erstellt. 
Mit `mvn install -P aktin-testing` wird ein Ordner erstellt, womit man direkt ein Vagrant Testinstanz laden kann. 

Simple-CDD
----------
Zum erstellen des Prepared-ISO ...

Ordner packages/
----------------

Im Ordner 'packages' sollten ZIP Archive liegen, die
für die Installation benötigt werden.

Von den offiziellen Webseiten von i2b2 https://www.i2b2.org/software/
müssen die folgenden Pakete heruntergeladen werden, da sie aus 
Lizenzgründen nicht automatisch heruntergeladen werden können:
* i2b2core-src-1706.zip
* i2b2createdb-1706.zip
* i2b2webclient-1706.zip

Zusätzlich werden Pakete die folgenden Pakete bei Bedarf
automatisch heruntergeladen:

* Axis2 1.6.2
* JBoss  Wildfly 9.0.2 Final


TODO
----
* mv scripts to /src/scripts
* build src dest mv to /usr/local/aktin/install eg
* logs to /var/log/aktin
* packages to /usr/local/aktin/packages - copy packages from src/resources
* dont include vagrant file, readme, postgres, logging

* pre manipulation of files - folder path!
* create AKTIN database and user and add jboss datasource (see below). Tables are verified/created/updated by the respective modules
* create query result folders (default name for config)

Wildfly Administration
----------------------

If wildfly is running, connect from the command line 
with `/opt/wildfly-9.0.2.Final/bin/jboss-cli.sh --connect`

Set jndi variable
```
/subsystem=naming/binding=java\:global\/a:add(binding-type=simple, type=int, value=100)
```

Show JNDI name tree: `/subsystem=naming:jndi-view`

Write JNDI binding: Writes value to standalone.xml and reads the new value upon restart.
```
/subsystem=naming/binding=java\:global\/a:write-attribute(name=value,value=123)
```

Add datasource
```
connect 127.0.0.1
 
batch
 
module add --name=com.mysql --resources=/home/jboss/Downloads/mysql-connector-java-5.1.24-bin.jar --dependencies=javax.api,javax.transaction.api
  
/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql)
 
data-source add --jndi-name=java:/jboss/MySQLDS --name=MySQLPool --connection-url=jdbc:mysql://localhost:3306/as7development --driver-name=mysql --user-name=jboss --password=jboss
 
run-batch
```
#TODO
# Folders and content
- **aktin-dwh-installer** : old i2b2 installer (from source)
- **aktin-dwh-upate** : old aktin update for old i2b2 installer
- **aktin-misc** : notes and miscellaneous files
    - **`addon\_*.old`** : old crc/meta-data for i2b2 (aktin replacement for i2b2's own crc/meta-data)
    - **`DOMAIN\_AKTIN\_i2b2\_db.sql`** : pg_dump of i2b2 database without i2b2 demodata and domain/project_id 'AKTIN' (instead of i2b2demo/Demo)
    - **`DOMAIN\_AKTIN\_i2b2\_db_demo.sql`** : pg_dump of i2b2 database with i2b2 demodata and domain/project_id 'AKTIN' (instead of i2b2demo/Demo)
    - **`VM\_aktin.sql`** : pg_dump of old aktin database from VM (debian 8)
    - **`VM\_i2b2.sql`** : pg_dump of old i2b2 database from VM (debian 8)
- **aktin-vm2-centos** : files of @rmajeed for reworked old installation/update
- **demo-distribution-0.13** : java client server for fhir/xds testing
- **edu.harvard.i2b2.data** : ant installer for i2b2 database with demodata
    - **NEWInstall_AKTIN** : changed build config to domain/project_id 'AKTIN'
    - **NEWInstall_DEMO** : unchanged build config with domain 'i2b2demo' and project_id 'Demo'
- **img** : 
- **integration** : single script and resources to test i2b2/aktin installation
    - **`aktin_test_\*.xml`** : CDA documents to test CDA import of AKTIN
    - **`i2b2_test_\*.xml`** : exemplary querys to test functionality of i2b2 frontend (login and query for allergies)
    - **`demo-server-0.13.jar`** : simple java client (is capalbe of sending CDA documents)
    - **`logging.properties`** : log configuration for java
    - **`test_integration.sh`** : script to test installation, tests basic functionality of i2b2, tests cda-import, module broker, module email, module R and consent-manager of AKTIN 
- **packages** : compressed files
    - **`dwh-j2ee-\*.ear`** : AKTIN client
    - **`i2b2.war`** : i2b2 client
    - **`postgresql-\*.jar`** : jdbc driver
- **scripts** : additional bash/cli scripts
    - **`aktin_datasource_create.cli`** : creates datasource for AKTIN in standalone.xml
    - **`aktin_diag.sh`** : diagnostic script, collects logs and OS information
    - **`aktin_reset.sh`** : resets i2b2/aktin installation, deletes wildfly-server, webclient and drops databases, does not removed installed packages (like postgresql, apache2, etc.)
    - **`email_create.sh`** : reads email.config and creates email configuration in standalone.xml
    - **`email_reset.sh`** : deletes email configuration of _email\_create.sh_ from standalone.xml
    - **`wildfly_logging_update.cli`** : updates logging of wildfly in standalone.xml
    - **`wildfly_safe_start.sh`** : script to safely start wildfly as a service with deployed _dwh-j2ee-\*.ear_ (with ear deployed, running postgresql is needed to start wildfly or undeployment of ear)
    - **`wildfly_safe_stop.sh`** : script to stop wildfly service after starting it safely (with redeployment ear)
- **sql** : sql queries and data dumps
    - **`addon_i2b2crcdata.concept_dimension.sql`** : new aktin replacement for i2b2's crc-data (as a pg_dump)
    - **`addon_i2b2metadata.i2b2.sql`** : new aktin replacement for i2b2's meta-data (as a pg_dump)
    - **`aktin_postgres_drop.sql`** : drops database and user 'AKTIN'
    - **`aktin_postgres_init.sql`** : creates database and user 'AKTIN'
    - **`i2b2_db.sql`** : dump of i2b2 database (without crc- and meta-data)
    - **`i2b2_db_demo.sql`** : dump of i2b2 database (with loaded crc- and meta-data, use for development only)
    - **`i2b2_postgres_drop.sql`** : drops database 'i2b2' and respective users of i2b2 cells
    - **`i2b2_postgres_init.sql`** : creates database 'i2b2' and respective users for i2b2 cells
- **xml** : datasources for i2b2 cells
- **`aktin.properties`** : configuration file for AKTIN client/broker
- **`aktin_install.sh`** : installation script for ubuntu 20.04 LTS (no preconditions necessary)
- **`Dockerfile`** : docker build file for installation and integration testing
- **`email.config`** : configuration for mail server

# Installation
Following files are necessary for the installation:
- **packages**
- **scripts**
- **sql** (i2b2_db_demo.sql is not necessary)
- **xml**
- **`aktin.properties`** 
- **`aktin_install.sh`** 
- **`email.config`**

1. Prior installing, configure **`aktin.properties`** and **`email.config`** appropriately. The installation can be completed even without proper configuration, but the AKTIN component will not work.

2. For the first step of the installation, a connection to the internet is necessary. An internet connection for the full course of the installation is recommended.

3. To start the installation, copy all necessary files to a folder on a newly installed ubunut 20.04 LTS. Inside this folder, run **`aktin_install.sh`**. The script will automatically download and install all needed packages, as well as configure all components. The install destination is always `/opt/`. Should the installation be disrupted during any step, the script can be started again. In this case it will skip all steps that have already been taken. For each installation a log-file will be created in `/opt/aktin_log`. 

4. (Optional) Copy **integration** to the other files. Run **`test_integration.sh`** to test all installed components on functionality.

5. Should errors occur during the installation, the entire installation can be reset using **`aktin_reset.sh`** in **scripts**. In this case, rerun **`aktin_install.sh`** after **`aktin_reset.sh`**.

---------------------
Another way is to install AKTIN via a docker container. Download all files and run **`docker build .`** inside the folder. This will copy all files to a docker container and run **`aktin_install.sh`** and **`test_integration.sh`**. Run **`docker run -it {CONTAINER_ID}`** to access the container after intallation finished.

# Ports and URLs
Following port are used by the installed components:
- apache2 (webclient i2b2) : PORT 80
- wildfly (webclient AKTIN) : PORT 9090 (redirected via apache2 to PORT 80)
- postgresql : PORT 5432

Notable URLs:
- http://localhost:80/admin - i2b2 user administration
- http://localhost:80/webclient/ - i2b2 webclient
- http://localhost:80/aktin/admin - AKTIN webclient
- http://localhost:80/aktin/cda/fhir/Binary - AKTIN CDA import
- http://localhost:80/aktin/admin/plain/test.html - module testing of AKTIN webclient