<h3><u>Firewall-Einstellungen</u></h3>

<h4>Externer Zugriff</h4>
Der AKTIN Server muss periodisch auf den Server `aktin-broker.klinikum.rwth-aachen.de` der Uniklinik RWTH Aachen mit der IP-Adresse `134.130.15.160` via `Port 443` (HTTPS) zugreifen können.
<br></br>

<h4>Interne Regeln</h4>
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