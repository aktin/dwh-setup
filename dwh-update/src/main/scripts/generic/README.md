Automatisiertes Update auf 0.7
==============================
- Also Admin einloggen ("sudo su -" oder "su -")
- Download von dwh-update-0.3.tar.gz
    + wget ... 
- Entpacken tar xfvz dwh-update-0.3.tar.gz
    + Entpacken tar xfvz dwh-update-0.3.tar.gz
- cd dwh-update
- aktin.properties bearbeiten mit den Standorteigenen Daten, besonders wichtig: local.email anpassen. Danach nach wildfly config Ordner kopieren
    + nano aktin.properties
    + cp aktin.properties /opt/wildfly-9.0.2.Final/standalone/configurations/
- email.config bearbeiten. Einstellungen für ausgehende Emails eintragen. Wird zum Verschicken von Reports und Ähnliches genutzt.    
    + Im Folgenden ein Beispiel für Googlemail Einrichtung (nutzt SSL)
        * smtphost=smtp.googlemail.com
        * smtpport=465
        * smtpuser=gmailname
        * smtppass=
        * mailfrom=
        * usessl=true
        * usetls=false
    + Mit TLS (z.B. Uni Oldenburg)
        * smtphost=smtp.uni-oldenburg.de
        * smtpport=587
        * smtpuser=sike0150
        * smtppass=
        * mailfrom=tingyan.xu@uni-oldenburg.de
        * usessl=false
        * usetls=true
- Update Skript ausführen: 
    + ./aktin_dwh_update.sh
- Das Updateprozess kann bis zu 5 Minuten andauern. Nach Beendigung kann man mit dem folgenden Befehl überprüft werden, ob alles einwandfrei installiert wurde.
    + ls /opt/wildfly-9.0.2.Final/standalone/deployments/dwh-j2ee*
        * Es sollten jeweils die Datei dwh-j2ee-0.7.ear sowie  dwh-j2ee-0.7.ear.deployed angezeigt werden.
        * Sollte die zweite Datei dwh-j2ee-0.7.ear.deployed fehlen und stattdessen die Datei dwh-j2ee-0.7.ear.isdeploying noch existieren, ist der Update noch nicht beendet. (Dies kann in Komibination mit der Dateien dwh-j2ee-0.7.ear.dodeploy auftreten)
        * Sollte die statt dwh-j2ee-0.7.ear.deployed nur dwh-j2ee-0.7.ear.failed aufgelistet werden, bitte kontaktiere unsere Support it-support(at)aktin.org
- Nach dem Updateprozess kann auf der Seite ihre-dwh-seite/aktin/admin/test/ eine Test der neuen Funktionalitäten durchgeführt werden. 
    + Mit Test Broker kann die Konnektivität zum Broker getest werden
    + Test Email überprüft die Email Einstellungen und schickt an der in aktin.properties angegebene Mail-Adresse eine Testmail. Sollte dieser Test fehlschlagen, überprüfen Sie bitte die Email Konfigurationen und führen Sie die Schritte unter "Email erneut Einrichten" durch.
    + Mit Test R wird die Reportgenerierung getestet.
- Sollte weitere Probleme und Fragen auftauchen, bitte kontaktieren Sie unsere Support it-support(at)aktin.org.

Email erneut Einrichten
-----------------------
- In der Datei email.config die Änderungen vornehmen.
- die Datei email_config_reset.sh aufrufen (./email_config_reset.sh)
- Den Updateskript erneut durchaurufen (./aktin_dwh_update.sh)

Änderungen in aktin.properties
------------------------------
- In der Datei /opt/wildfly-9.0.2.Final/standalone/configurations/aktin.properties die erwünschten Änderungen vornehmen
- Den wildfly Service neustarten 
    + service wildfly stop
    + service wildfly start





Generic Update Procedure
========================
not supported:
pre-0.6

currently supported:
0.6
0.6.3


notation [all]=executed for all updates; [pre yy]=executed only if the version before upgrade is yy or lower
-------------------

Step 0) Check Paths and Log Status Information (target and active EAR version etc.) [all]

Step 1) Undeploy all old dwh-j2ee EARs [all]

Step 2) Execute scripts (SQL, Copy files etc.) [all]

Step 2.01) Fact Database Reset [pre 0.6.3]

Step 2.02) Update local DWH ontology [all]

Step 2.03) Remove login form defaults [pre 0.6.3]

Step 2.04) Create AKTIN Database in postgres [pre 0.7]

Step 2.05) Create Aktin Data source in wildfly [pre 0.7]

Step 2.06) Copy aktin.properties [pre 0.7]

Step 2.07) Create /var/lib/aktin [pre 0.7]

Step 2.08) SMTP configuration [pre 0.7]

Step 3) Stop Wildfly Service [all]

Step 4) Remove all dwh.ear, dwh.ear.failed, dwh.ear.undeployed

Step 5) Start Wildfly Service [all]

Step 6) Copy/Deploy new dwh-j2ee EAR [all]

