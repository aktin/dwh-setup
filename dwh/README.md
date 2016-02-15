Virtuelle Maschine fuer Data Warehouse
======================================

Ordner packages/
----------------

Im Ordner 'packages' sollten ZIP Archive liegen, die
für die Installation benötigt werden.

Von den offiziellen Webseiten von i2b2 https://www.i2b2.org/software/
müssen die folgenden Pakete heruntergeladen werden, da sie aus 
Lizenzgründen nicht automatisch heruntergeladen werden können:
* i2b2core-src-1705.zip
* i2b2createdb-1705.zip
* i2b2webclient-1705.zip

Zusätzlich werden Pakete die folgenden Pakete bei Bedarf
automatisch heruntergeladen:

* Axis2 1.6.2
* Apache Ant 1.8.2
* JBoss AS 7.1.1 Final


TODO
----
Remove the following files from jboss-configuration.zip:
- standalone*.xml 
- logging.properties
- application-*.properties

Deployment to Wildfly via CLI:
```
/opt/wildfly-9.0.2.Final/bin/jboss-cli.sh --controller=localhost:9990 --connect
--command="deploy ... --force"
```

Test wildfly 10.0.0

