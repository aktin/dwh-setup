<h3><u>Netzwerk-Einstellungen</u></h3>

<h4>Installation</h4>
Für die Installation des AKTIN DWH braucht das Installationsskript Zugriff auf folgende Server:

<table style="width:50%;">
<thead>
<tr>
    <th style="width:40%;">Server</th>
    <th style="width:20%;">IP-Adresse</th>
    <th style="width:20%;">HTTP</th>
    <th style="width:20%;">HTTPS</th>
</tr>
</thead>
<tbody>
<tr>
    <td>de.archive.ubuntu.com</td>
    <td>141.30.62.23</td>
    <td>80/tcp</td>
    <td>-</td>
</tr>
<tr>
    <td>aktin.org</td>
    <td>188.68.47.138</td>
    <td>-</td>
    <td>443/tcp oder 8443/tcp</td>
</tr>
</tbody>
</table>


<h4>Betrieb</h4>
Während des Betriebs muss der AKTIN Server periodisch auf folgenden Server zugreifen können:

<table style="width:50%;">
<thead>
<tr>
    <th style="width:40%;">Server</th>
    <th style="width:20%;">IP-Adresse</th>
    <th style="width:20%;">HTTP</th>
    <th style="width:20%;">HTTPS</th>
</tr>
</thead>
<tbody>
<tr>
    <td>aktin.org</td>
    <td>188.68.47.138</td>
    <td>-</td>
    <td>443/tcp oder 8443/tcp</td>
</tr>
<tr>
    <td>aktin-broker.klinikum.rwth-aachen.de</td>
    <td>134.130.15.160</td>
    <td>-</td>
    <td>443/tcp</td>
</tr>
</tbody>
</table>

<h4>Weitere Einstellungen und Informationen</h4>
* `Port 80` (HTTP) wird verwendet, um intern auf das Data Warehouse sowie Konfigurationoberflächen zuzugreifen.

* Datenimporte werden per RESTful oder SOAP-Schnittstelle über HTTP an `/aktin/cda` gesendet.

* Zum Versenden von Benachrichtgungen muss der Server intern Emails an ausgewählte lokale Adressen versenden können. Dafür wird ein E-Mail-Server benötigt. Tragen Sie die Konfiguration des E-Mail-Servers in `/opt/wildfly/standalone/configuration/aktin.properties` unter folgenden Feldern ein:

````
# mail server via java, use configuration below
email.session=local

# adress received mails will reply to
mail.x.replyto=it-support@aktin.org

# mail server protocol
mail.transport.protocol=smtp

# mail server name
mail.smtp.host=smtp.gmail.com

# mail server port, e.g. 465 (SSL) or 587 (TLS), or 25 (no auth)
mail.smtp.port=587

# mail server authentification, false for "no login is needed"
mail.smtp.auth=true

# user name for authentication (this name is displayed as addressor of every mail)
mail.user=userforssending

# password for authentication
mail.x.password=passwordforsending

# security configuration
mail.smtp.starttls.enable=true

# connection timeout
mail.smtp.timeout=10000
mail.smtp.connectiontimeout=10000
````

* Sofern für die Authentifizierung am E-Mail-Server ein Zertifikat benötigt wird, können Sie dieses über folgenden Befehl dem Java Truststore hinzufügen. Anschließend sollte ein Passwort-Aufforderung kommen. Sofern von Ihrer Seite kein Passwort festgelegt wurde, lautet das Standardpassword `changeit`. Den erfolgreichen Import können Sie anschließend über den zweiten Befehl testen. Starten Sie anschließen den Wildfly-Server neu.

````
keytool -importcert -alias [SELBSTGEWÄHLTER ALIASNAME] -file [PFAD ZUM ZERITIFIKAT] -keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts 

keytool –list –keystore /usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts | grep [ALIASNAME]

serivce wildfly restart
````

* Um `ipv6` zu deaktivieren, geben Sie in der Konsole folgende Befehle ein:

````
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

sudo sysctl -p
````

* Ein Proxy-Server muss im Wildfly händisch konfiguriert werden. Da die Netzwerkverbindung über Java läuft, muss der Proxy als JAVA_OPT unter `/opt/wildfly/bin/standalone.conf` eingetragen werden. Fügen Sie am Ende der Datei folgenden Eintrag hinzu. Nicht benötigte Felder können dabei weggelassen werden:

````
JAVA_OPTS="$JAVA_OPTS -Dhttps.proxyHost=xxx.x.x.xx -Dhttps.proxyPort=xxxx -Dhttps.proxyUser=MY_LOGIN -Dhttps.proxyPassword=MY_PASSWORD -Dhttp.proxyHost=xxx.x.x.xx -Dhttp.proxyPort=xxxx -Dhttp.proxyUser=MY_LOGIN -Dhttp.proxyPassword=MY_PASSWORD"
````

* Um den CDA Import über HTTPS zu verschlüsseln, müssen Sie zunächst über den Befehl `htpasswd` einen neuen User für die Authentifizierung anlegen. Wichtig ist dabei, den User aufgrund von Berechtigungsproblemen nicht unter `/root/` anzulegen und auch nicht im Verzeichnis des Webservers selbst, da die Datei von außen ausgelesen werden könnte. Legen Sie den User daher am besten unter `/home/` ab.  Mit dem fertigen User können Sie nun festlegen, welche Pfade im Apache eine Authentifizierung benötigen. Öffnen Sie hierfür die Konfiguration des Apache Webclients über den Befehl `nano /etc/apache2/sites-available/000-default.conf` (in manchen Fällen auch nur default.conf) und fügen Sie unter dem Eintrag `DocumentRoot /var/www/html` folgenden Block hinzu:

````
<Location /aktin/cda/fhir/Binary>
AuthUserFile /home/<Linux-User/.passwd>
AuthName "Password Protected"
AuthType Basic
require valid-user
</Location>
````

Speicher Sie die Datei ab und starten Sie den apache2-Server über den Befehl `service apache2 restart` neu. Nun ist der Pfad für den CDA Import nur noch über eine Authentifizierung des angelegten Users zugänglich.
