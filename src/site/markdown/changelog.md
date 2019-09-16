Changelog
=========

Version 1.1
-----------
* CDA-Validierung aktualisiert
* Keine Unterstützung mehr für alte CDA-Template-Versionen
* Verteiltes Rechnen mit Rscript vor Datenübertragung
* ENQUIRE-SIC-Erzeugung überspringt nun keine Nummern mehr bei Fehlern


Version 1.0.2
-------------
* Implizite Fall-Merges führen nun nicht mehr zu duplikaten Datenbankeinträgen. Seit 1.0 kam dieses Problem vor wenn das gleiche CDA-Dokument mit unterschiedlicher Patientennummer (aber gleicher Fallnummer) erneut geschickt wird.

Version 1.0.1
-------------
* E-Mail-Benachrichtigungen geben nun eine explizite Absenderadresse (From) an. In bestimmten Fällen wurde vorher ohne Absenderadresse ein Spam-Filter aktiv.

Version 1.0
-----------
* Weboberfläche
  * Integration von Serien-Anfragen und Freigabe-Regeln
  * Anfragen-Einzelansicht: leserlicheres Format des Zeitraum der Daten und des Abfrage-Intervalls
  * Consent-Manager für den Ein- und Ausschluss von Patienten in/aus eine Studie
* neuer Anfrage-Status: Expired (Anfrage auf Broker bereits geschlossen oder gelöscht)
* Zuweisung von Rollen in der i2b2-Oberfläche (admin und study_nurse), um Nutzergruppen nur bestimmte Funktionalitäten zur Verfügung zu stellen

Version 0.10.1
--------------
* CDA-Import
    * Bei der Transformation aus dem CDA in das DWH wurde ein Fehler für "Tetanusschutz unbekannt" behoben - dies wurde als "Tetanusschutz" importiert. Dadurch sind alle Daten, die mit einem früheren Release importiert wurden in diesem Punkt falsch
* Aktualisierung des Monatsbericht auf V01.4
    * Vertauschung in der Berichts-Ausgabe zwischen Geschlecht männlich/weiblich korrigiert
    * Überarbeitung der Berechung in Kapitel 7 (Abweichungen zwischen Tabelle und Grafik)
* Weboberfläche
    * Versionsnummer wird nun in der Weboberfläche angezeigt
    * Behoben: Bei Aufruf über E-mail-Link wurden neue Abfragen manchmal nicht angezeigt.
* Update-Skript/Installation
    * Arbeitsspeicher-Beschränkung für Java (Wildfly) erhöht
    * Logfiles (Wildfly) nun beschränkt auf ca 1GB durch Logfile-Rotation

Version 0.9
-----------
* Weboberfläche
    * Verbesserte Darstellung von Anfragen
    * Automatische Aktualisierung bei Anfrageausführung und Berichtserzeugung
    * Einzelfallansicht eingeführt
* Aktualisierung des Monatsbericht auf V01.3
    * Keine Reportfehler bei ungültigen ICD10-Codes
    * Korrigierte Auswertungen nach Wochentagen (2.1/2.2)
    * Zeitdifferenzen nun korrekt berechnet
    * Datenauswahl nun exakt auf Aufnahme im Zeitraum begrenzt
* CDA-Import: Kompatibilität zu FHIR-Standard sichergestellt
    * OperationOutcome bei Erfolg nicht mehr leer sondern mit Info
* Korrekturen in der Abfragesyntax
    * Deklarierte temporäre Tabellen werden automatisch gelöscht
    * Anonymisierung optional bei aggregierten Ergebnissen
    * Tabellennamen und Dateinamen im Export nun unterschiedlich

Version 0.8.1
-----------
* Weboberfläche zur Verwaltung von Monatsberichten/Datenanfragen
* Funktionalität zur Freigabe und Durchführung von zentralen Datenabfragen
* Aktualisierung des Monatsberichts auf V01.2:
    * Manuelle Berichtserstellung über beliebigen Zeitraum
    * Dateiname für Monatsbericht in Emailbenachrichtigung
    * Altersberechnung korrigiert
    * Verbesserungen bei der Berechnung von Datum/Wochentag
    * Ergänzung der Ausgabe der Gesamtzahl (n) in 2.3/2.4
    * Fehler in der Anteilsberechnung und bei der Ausgabe leerer Tabellen behoben
    * Redaktionelle Überarbeitungen
* Speichermöglichkeit ankommender CDA-Dokumente mit Konfiguration `import.cda.debug.dir=/var/ihr/verzeichnis`

Version 0.7
-----------
* Aktualisierung auf CDA Version v1.26 (2017-03-02)
* Einrichtung der Report-Funktion (Erzeugung eines standardisierten Monatsberichts)
* Einrichtung der E-Mail-Funktion (insbesondere für den Versand des Monatsberichts)
* Einrichtung einer periodischen Statusmeldung an den zentralen AKTIN-Broker (Zeitpunkt der letzten Statusmeldung, Software-Versionsstände, Anzahl importierter Datensätze, letzte Fehlermeldungen)
* Korrektur eines Fehlers beim Import mehrerer IDs in encompassingEncounter
* Korrektur des Imports von CEDIS-UNK bzw. CEDIS-999
* Korrekturen beim Import und der Darstellung im DWH von Multiresistenten Keimen mit NullFlavor OTH _CAVE: "Verdacht auf andere multiresistente Keime" kann in diesem Release noch nicht angegeben werden (Schematron Fehler)_

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