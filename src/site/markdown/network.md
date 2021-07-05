<h3><u>Netzwerk-Einstellungen</u></h3>

<h4>Installation</h4>
Für die Installation des AKTIN DWH braucht das Installationsskript Zugriff auf folgende Server:

<table>
<thead>
<tr>
    <th>Server</th>
    <th>IP-Adresse</th>
    <th>HTTP</th>
    <th>HTTPS</th>
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
    <td>github.com</td>
    <td>140.82.121.3</td>
    <td>80/tcp</td>
    <td>443/tcp</td>
</tr>
<tr>
    <td>download.jboss.org</td>
    <td>88.221.217.128</td>
    <td>80/tcp</td>
    <td>443/tcp</td>
</tr>
<tr>
    <td>jdbc.postgresql.org</td>
    <td>72.32.157.228</td>
    <td>80/tcp</td>
    <td>443/tcp</td>
</tr>
<tr>
    <td>aktin.org</td>
    <td>188.68.47.138</td>
    <td>80/tcp</td>
    <td>443/tcp oder 8443/tcp</td>
</tr>
</tbody>
</table>


<h4>Betrieb</h4>
Während des Betriebs muss der AKTIN Server periodisch auf folgenden Server der Uniklinik RWTH Aachen zugreifen können:

<table>
<thead>
<tr>
    <th>Server</th>
    <th>IP-Adresse</th>
    <th>HTTP</th>
    <th>HTTPS</th>
</tr>
</thead>
<tbody>
<tr>
    <td>aktin-broker.klinikum.rwth-aachen.de</td>
    <td>134.130.15.160</td>
    <td>-</td>
    <td>443/tcp</td>
</tr>
</tbody>
</table>


<h4>Weitere interne Regel</h4>
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

* Die Netzwerkeinstellungen können Sie über den Befehl `ip a` einsehen.

* Um `ipv6` zu deaktivieren, geben Sie in der Konsole folgende Befehle ein:

````
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

sudo sysctl -p
````