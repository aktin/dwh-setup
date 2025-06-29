﻿<h3><u>Changelog</u></h3>

<h4>Version 1.6 (04-2025)</h4>
* Komplettes Refactoring der Debian-Maintainer-Skripte
* Update der i2b2-Komponenten auf Version 1.8.1a
* Versionsupdate aller Komponenten aufgrund der neuen Basis (Ubuntu Server 22.04 LTS)
    * Java 11
    * WildFly 22.0.1.Final
    * PostgreSQL 14
    * Apache 2.4.52
    * PHP 8.1
    * Python 3.10.12
    * R 4.1.2
* Rücknahme instabiler Abhängigkeitsänderungen
* UI-Verbesserungen
    * Update-Prüfungen beim ersten Laden der Ansicht
    * Neue Icons und Popups
    * Verbesserte Anzeige des Anfrage-Status
    * Überarbeitete Texte, Layouts und Interaktionen
* Überarbeitung der Update-Logik
    * Zusammenführung redundanter Methoden
    * Trennung von Geschäftslogik und Benutzeroberfläche

<h4>Version 1.5.1 (12-2021)</h4>
* Fehlerbehebungen im Monatsbericht
* Fehlerbehebung beim Löschen von importierten §21-Daten
* Fehlerbehebung im Anzeigen des Popups nach einem erfolgreichen Update des DWH
* Importskript V1.5
    * Architekturelle Überarbeitung des Skriptes zur Verbesserung der Laufzeit
    * Fehlerbehebung beim Löschen von importierten §21-Daten älterer Skripte
    * Behebung der Kollision von ICD-Kodes aus §21-Daten mit AKTIN Monatsberichten
* Anpassung der Abhängigkeit zwischen den Paketen `wildfly` und `postgresql-12`
    * Service `wildfly` ist nun einseitig von `postgresql-12` abhängig
    * Deaktivierung der _unattended upgrades_ für `postgresql-12`

<h4>Version 1.5 (09-2021)</h4>
* Umstellung des Installationpakets von `.tar.gz` zu einem Debian-Paket
    * Automatische Updatemöglichkeit über die Ansicht
    * Elektrische Signatur für jedes Paket
    * Offline Installation möglich
* Neue Felder in der aktin.properties für das Debugging von `rscript`
* Datasource für AKTIN wurde aus der `standalone.xml` in den Ordner `deployments` verschoben
* Engere Abhängigkeit zwischen den Paketen `wildfly` und `postgresql-12`
    * Start/Stop eines Services startet/stoppt automatisch den anderen
* Importskript V1.3
    * Datenverarbeitung nun unabhängig von Groß/Kleinschreibung
    * Spalten für Sekundärdiagnosen werden automatisch umbenannt, wenn notwendig
    * Verbesserte Zusammenfassung in der Konsolenausgabe nach erfolgreicher Verifizierung/erfolgreichem Import

<h4>Version 1.4.1 (05-2021)</h4>
* Importskript V1.1
    * Nur `FALL.csv` ist notwendig für den Import (`FAB.csv`, `OPS.csv` und `ICD.csv` sind nun optional)
    * Invalide Felder, die optional sind, werden nun ignoriert (Fall wird trotzdem importiert)

<h4>Version 1.4 (05-2021)</h4>
* Daten-Import: Ein neues Modul für das Hochladen und Verarbeiten von generischen Daten
    * Importskript V1.0 für den Import stationärer Behandlungsdaten gemäß §21 KHEntgG
* Weboberfläche
    * Neuer Reiter: Daten-Import
    * Möglichkeit zum Löschen von Berichten in der Berichtsübersicht
    * Hinzufügung einer Studie zur Zertifizierung der CDA-Schnittstelle
    * Generelle Überarbeitungen von Design und Animationen
* Aktualisierung des Monatsbericht auf V0.15
    * Fehlerbehebung in der Umwandlung und Darstellung von Datumsformaten

<h4>Version 1.3 (11-2020)</h4>
* Update-Skript/Installation:
	* Wechsel des Betriebssystems von Debian 8/CentOS 7 zu Ubuntu Server 20.04
	* Versionsupdate aller Komponenten:
		* Java 11
		* WildFly 18.0.0.Final
		* Postgres 12
		* Apache 2.4.41
		* PHP 7.4.3
		* Python 3.8.2
		* R 3.6.3-2
* Konfiguration für den Mail-Server wurde aus `email.config` nach `aktin.properties` übertragen (Versand über `email.config` auch weiterhin möglich)

<h4>Version 1.1</h4>
* CDA-Validierung aktualisiert
* Keine Unterstützung mehr für alte CDA-Template-Versionen
* Verteiltes Rechnen mit Rscript vor Datenübertragung
* ENQUIRE-SIC-Erzeugung überspringt nun keine Nummern mehr bei Fehlern
* Neue Serveradresse für Umzug des AKTIN-Query-Brokers nach Aachen

<h4>Version 1.0.2</h4>
* Implizite Fall-Merges führen nun nicht mehr zu duplikaten Datenbankeinträgen. Seit 1.0 kam dieses Problem vor wenn das gleiche CDA-Dokument mit unterschiedlicher Patientennummer (aber gleicher Fallnummer) erneut geschickt wird.

<h4>Version 1.0.1</h4>
* E-Mail-Benachrichtigungen geben nun eine explizite Absenderadresse (From) an. In bestimmten Fällen wurde vorher ohne Absenderadresse ein Spam-Filter aktiv.

<h4>Version 1.0</h4>
* Weboberfläche
  * Integration von Serien-Anfragen und Freigabe-Regeln
  * Anfragen-Einzelansicht: leserlicheres Format des Zeitraum der Daten und des Abfrage-Intervalls
  * Consent-Manager für den Ein- und Ausschluss von Patienten in/aus eine Studie
* neuer Anfrage-Status: Expired (Anfrage auf Broker bereits geschlossen oder gelöscht)
* Zuweisung von Rollen in der i2b2-Oberfläche (`admin` und `study_nurse`), um Nutzergruppen nur bestimmte Funktionalitäten zur Verfügung zu stellen

<h4>Version 0.10.1</h4>
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
    * Logfiles (Wildfly) nun beschränkt auf ca. 1GB durch Logfile-Rotation

<h4>Version 0.9</h4>
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

<h4>Version 0.8.1</h4>
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

<h4>Version 0.7</h4>
* Aktualisierung auf CDA Version v1.26 (2017-03-02)
* Einrichtung der Report-Funktion (Erzeugung eines standardisierten Monatsberichts)
* Einrichtung der E-Mail-Funktion (insbesondere für den Versand des Monatsberichts)
* Einrichtung einer periodischen Statusmeldung an den zentralen AKTIN-Broker (Zeitpunkt der letzten Statusmeldung, Software-Versionsstände, Anzahl importierter Datensätze, letzte Fehlermeldungen)
* Korrektur eines Fehlers beim Import mehrerer IDs in encompassingEncounter
* Korrektur des Imports von CEDIS-UNK bzw. CEDIS-999
* Korrekturen beim Import und der Darstellung im DWH von Multiresistenten Keimen mit NullFlavor OTH _CAVE: "Verdacht auf andere multiresistente Keime" kann in diesem Release noch nicht angegeben werden (Schematron Fehler)_

<h4>Version 0.6.3</h4>
* Installer zur direkten Neuinstallation auf Version 0.6.3

<h4>Version 0.6.2</h4>
* Korrektur eines Fehlers beim Import von CDAs mit Todes-Zeitpunkt (`Discharge-Code = 1`) _Fehler neu eingeführt in Version 0.6_

<h4>Version 0.6</h4>
* Aktualisierung auf CDA Version v1.21 (2016-08-04)
* Änderungen bzgl. des Umgangs mit Episoden-IDs (vgl. [Releasenotes](cda-release-v1.21.html))
* Bei der Validierung des CDA werden Schematron-Warnungen nun als solche ausgegeben. Zuvor wurden alle Warnungen als Fehler behandelt
* Validierung beinhaltet nun auch die Prüfung der XSD-Konformität zusätzlich zur Schematron-Validierung
* Erweiterte HL7-FHIR-Implementierung: Conformance resource, Binary resource unterstützt Operationen `$validate`, `$transform`, `$search`
* i2b2-Weboberfläche ohne Vorgabe der "demo"-Anmeldedaten

<h4>Version 0.5</h4>
* Demo clients (FHIR und XDS.b) übermitteln nun auch Zeichensatz (charset)
Wenn kein Zeichensatz erkannt werden kann, wird UTF-8 übermittelt

<h4>Version 0.4.1</h4>
* Ausführlichere Ausgabe beim Start des Demo-Servers
* Dokumentation (web) zum Start des Demo-Servers für externen Netzwerkzugriff

<h4>Version 0.4</h4>
* Aktualisierung auf CDA Version v1.17 (2015-11-18)
