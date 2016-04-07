Virtuelle Maschine fuer Data Warehouse
======================================

Erstellung der Packete
----------------------
In dwh-install ein Maven clean install durchf�hren:
```
mvn clean install
```
Dabei wird ein Datei mit dem Namen `dwh-install-0.1-SNAPSHOT-full.tar.gz` erstellt. Mittels `tar -zxvf` entpackt, erh�lt man den vollst�ndigen `aktin-dwh-snapshot`, wobei alle ben�tigten Pakete bereits in `aktin-dwh-snapshot/packages/` enthalten sind. 
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
f�r die Installation ben�tigt werden.

Von den offiziellen Webseiten von i2b2 https://www.i2b2.org/software/
m�ssen die folgenden Pakete heruntergeladen werden, da sie aus 
Lizenzgr�nden nicht automatisch heruntergeladen werden k�nnen:
* i2b2core-src-1706.zip
* i2b2createdb-1706.zip
* i2b2webclient-1706.zip

Zus�tzlich werden Pakete die folgenden Pakete bei Bedarf
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

