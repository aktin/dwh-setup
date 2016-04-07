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

