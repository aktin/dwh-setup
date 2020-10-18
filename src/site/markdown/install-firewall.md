Firewall-Einstellungen
======================

<!--  MACRO{toc|section=0|fromDepth=1|toDepth=6} -->

Externer Zugriff
----------------
Der AKTIN Server muss periodisch auf den Server `aktin-broker.klinikum.rwth-aachen.de` der Uniklinik RWTH Aachen mit der IP-Adresse `134.130.15.153` via `Port 443` (HTTPS) zugreifen können.


Interne Regeln
--------------
* `Port 80` (HTTP) wird verwendet, um intern auf das Data Warehouse sowie Konfigurationoberflächen zuzugreifen.

* Datenimporte werden per RESTful oder SOAP-Schnittstelle über HTTP an `/aktin/cda` gesendet.

* Zum Versenden von Benachrichtgungen muss der Server intern Emails an ausgewählte lokale Adressen versenden können. Dazu muss ein SMTP-Server mittels der Datei `email.config` konfiguriert werden.
