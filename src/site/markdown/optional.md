Optionale Konfiguration
======================================

Diese optionalen Konfigurationsschritte können jederzeit, ggf. auch mehrmals auf einem Server mit dem Releasestand 0.6 oder höher ausgeführt werden.

(Optional) Zeitpunkt des Produktivstarts manuell festlegen
----------------------------------------------------------

Wenn der Import aus dem Notaufnahmesystem während des Updates schon läuft, bringt das zwei Nachteile mit sich: Erstens wird die (dringend angeratene) Umstellung auf Version 2 des CDA-Tremplates erst nach dem DWH-Update durchgeführt und somit in der Zwischenzeit weitere Version 1 CDAs importiert. Dies ist technisch kein Problem, aber ggf. unschön für eine Auswertung. Zweitens ist der Produktiv-Start (also Beginn der Datensammlung) dann der Zeitpunkt, zu dem das Script ausgeführt wurde. Auch hier möchte man ggf. einen definierten Startzeitpunkt (z.B. Montag 0:00 Uhr) wählen. Dies lässt sich am einfachsten realisieren, indem man nachträglich alle Daten löscht, die vor dem selbst gewählten Startdatum liegen. Dazu sind folgende manuellen Schritte in der Server-Konsole auszuführen (das Datum kann frei gewählt werden, sollte aber nicht in der Zukunft liegen, da sonst natürlich wieder der Ausführungs-Zeitpunkt und nicht der angegebene der effektive Produktiv-Start wird). Dazu sollte man sich als `root` angemeldet sein.

```
su postgres
psql

\connect i2b2
delete from i2b2crcdata.observation_fact where import_date < '2016-10-01 0:00';
delete from i2b2crcdata.encounter_mapping where import_date < '2016-10-01 0:00';
delete from i2b2crcdata.patient_mapping pm  where not exists(select null from i2b2crcdata.patient_dimension pd where  pm.patient_num=pd.patient_num and pd.update_date >= '2016-10-01 0:00');


delete from i2b2crcdata.patient_dimension where update_date < '2016-10-01 0:00';
delete from i2b2crcdata.visit_dimension where import_date < '2016-10-01 0:00';
\q
exit
service wildfly restart

```

(Optional) SMTP Einrichtung
----------------------------

Als Vorbereitung für spätere Funktionen kann man bereits die SMTP E-Mail Funktion einrichten. Dazu benötigt man eine (im Intranet erreichbare) E-Mail-Adresse bzw. Server. Das AKTIN-DWH verwendet keinen eigenen Mail-Server. Voraussetzung ist also ein Mail-Server, der (ggf. im Intranet) vom AKTIN-Server erreichbar ist und eine E-Mail-Adresse, die der Server verwenden kann um per SMTP Informations-Mails zu versenden. Sinnvoll wäre dazu eine dedizierte AKTIN-Service-Adresse einzurichten.

Um SMTP einzurichten, sollte man die folgenden Befehlen in der Konsole eingeben, wobei `$WILDFLY_HOME` wieder auf den Wildfly Ordner verlinkt und in den Variablen `smtphost`, `smtpport`, `smtpuser`, `smtppass` sollten die Einstellungen eingetragen werden. Folgende Befehle sollten als `root` ausgeführt werden.

```
smtphost=smtp.example.com
smtpport=465
smtpuser=user@example.com
smtppass=myPassword
usessl=true

sessionname="AktinMailSession"
jndiname="java:jboss/mail/AktinMailSession"
smtpbind="aktin-smtp-binding"

$WILDFLY_HOME/bin/jboss-cli.sh -c "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:add(host=$smtphost, port=$smtpport)"
$WILDFLY_HOME/bin/jboss-cli.sh -c "/subsystem=mail/mail-session=$sessionname:add(jndi-name=$jndiname)"
$WILDFLY_HOME/bin/jboss-cli.sh -c "/subsystem=mail/mail-session=$sessionname/server=smtp:add(outbound-socket-binding-ref=$smtpbind, username=$smtpuser, password=$smtppass, ssl=$usessl)"
$WILDFLY_HOME/bin/jboss-cli.sh -c ":reload"
```
Mit der letzten Zeile werden alle Wildfly Dienste gestoppt und neu gestartet. Nach kurzer Zeit sind die Funktionen wieder wie gewohnt aufrufbar. 