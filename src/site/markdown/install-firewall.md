Firewall-Einstellungen
======================

<!--  MACRO{toc|section=0|fromDepth=1|toDepth=6} -->

Externer Zugriff
----------------

Der AKTIN Server muss periodisch auf folgenden Server
der an der Uniklinik RWTH Aachen via HTTPS (Port 443) zugreifen können:

* `aktin-broker.klinikum.rwth-aachen.de` mit der IP-Adresse: 134.130.15.153


Interne Regeln
--------------

Port 80 (HTTP) wird verwendet um intern auf das Data
Warehouse sowie Konfigurationoberflächen zuzugreifen.

Zusätzlich werden Datenimport per RESTful oder SOAP-Schnittstelle über HTTP
an /aktin/cda gesendet.

Zum Versenden von Benachrichtgungen muss der Server intern Emails an ausgewählte lokale Adressen versenden können. Dazu muss ein SMTP Server konfiguriert werden.
