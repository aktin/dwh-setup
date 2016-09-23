Firewall-Einstellungen
======================

Externer Zugriff
----------------

Der AKTIN Server muss periodisch auf zwei Server
der Universität Oldenburg via HTTPS (Port 443) zugreifen

* `broker.aktin.uni-oldenburg.de`
* `pool.aktin.uni-oldenburg.de`

Interne Regeln
--------------

Port 80 (HTTP) wird verwendet um intern auf das Data
Warehouse sowie Konfigurationoberflächen zuzugreifen.

Zusätzlich werden Datenimport per RESTful oder SOAP-Schnittstelle über HTTP
an /aktin/cda gesendet.

Zum Versenden von Benachrichtgungen muss der Server intern
Emails an ausgewählte lokale Adressen versenden können. Dazu muss
ein SMTP Server konfiguriert werden.
