Virtuelle Maschine für das Data Warehouse
======================================

Erstellung der Packete
----------------------
In dwh-install ein `mvn clean install` durchfüren. Dabei wird ein Datei mit dem Namen `dwh-install-{VERSION}.tar.gz` erstellt. Mittels `tar -zxvf` kann man das Verzeichnis entpacken. Es entsteht ein Ordner namens `aktin-dwh-installer` mit allen benötigten Paketen. Zusätzlich ist in `aktin-dwh-installer/packages/` immer die aktuelleste Version von `aktin-dwh-update` enthalten. 

Mit dem Befehl `mvn install -P profile-name,second-profile-name` kann man einzelne oder mehrere Installierprofile aufrufen. Mit z.B. `mvn install -P aktin-installer,aktin-package-only` werden zwei Pakete erstellt. Mit `mvn install -P aktin-testing` wird ein Ordner erstellt, womit man direkt eine Vagrant Testinstanz laden kann. 

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
