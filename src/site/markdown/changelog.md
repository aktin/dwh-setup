Changelog
=========

Version 0.7
-----------
* Aktualisierung auf CDA Version v1.26 (2017-03-02)
* Einrichtung der Berichtfunktion
* Einrichtung der E-Mailfunktion
* Einrichtung einer periodischen Statusmeldung an den zentralen AKTIN-Broker
* Korrektur eines Fehlers beim Import mehrerer IDs in encompassingEncounter
* Korrektur des Imports von CEDIS-UNK bzw. CEDIS-999
* Korrekturen beim Import und der Darstellung im DWH von Multiresistenten Keimen mit NullFlavor OTH _CAVE: "Verdacht auf andere multiresistente Keime" kann nicht angegeben werden (Schematron Fehler)"_

Version 0.6.3
-------------
* Installer zur direkten Neuinstallation auf Version 0.6.3

Version 0.6.2
-------------
* Korrektur eines Fehlers beim Import von CDAs mit Todes-Zeitpunkt (Discharge-Code = 1) _Fehler neu eingeführt in Version 0.6_

Version 0.6
-----------
* Aktualisierung auf CDA Version v1.21 (2016-08-04)
* Änderungen bzgl. des Umgangs mit Episoden-IDs (vgl. [Releasenotes](cda-release-v1.21.html))
* Bei der Validierung des CDA werden Schematron-Warnungen werden nun als solche ausgegeben. Zuvor wurden alle Warnungen als Fehler behandelt.
* Validierung beinhaltet nun auch die Prüfung der XSD-Konformität zusätzlich zur Schematron-Validierung.
* Erweiterte HL7-FHIR-Implementierung: Conformance resource, Binary resource unterstützt Operationen $validate, $transform, $search.
* i2b2-Weboberfläche ohne Vorgabe der "demo"-Anmeldedaten.

Version 0.5
-----------
* Demo clients (FHIR und XDS.b) übermitteln nun auch Zeichensatz (charset).
Wenn kein Zeichensatz erkannt werden kann, wird UTF-8 übermittelt.

Version 0.4.1
-------------
* Ausführlichere Ausgabe beim Start des Demo-Servers. 
* Dokumentation (web) zum Start des Demo-Servers für externen Netzwerkzugriff.

Version 0.4
-----------
* Aktualisierung auf CDA Version v1.17 (2015-11-18)