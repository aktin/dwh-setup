<h3><u>Firewall-Einstellungen</u></h3>

<h4>Externer Zugriff</h4>
Der AKTIN Server muss periodisch auf den Server `aktin-broker.klinikum.rwth-aachen.de` der Uniklinik RWTH Aachen mit der IP-Adresse `134.130.15.153` via `Port 443` (HTTPS) zugreifen können.
<br></br>

<h4>Interne Regeln</h4>
* `Port 80` (HTTP) wird verwendet, um intern auf das Data Warehouse sowie Konfigurationoberflächen zuzugreifen.

* Datenimporte werden per RESTful oder SOAP-Schnittstelle über HTTP an `/aktin/cda` gesendet.

* Zum Versenden von Benachrichtgungen muss der Server intern Emails an ausgewählte lokale Adressen versenden können. Dazu muss ein SMTP-Server konfiguriert werden.
