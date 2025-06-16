<h3><u>Installation und Konfiguration des AKTIN Data Warehouse</u></h3>

Diese Anleitung beschreibt die Installation, den Betrieb und die Wartung des **AKTIN Data Warehouse (DWH)** mit i2b2-Backend, WildFly-Applikationsserver und Apache-Webserver auf einem Linux-Host mittels Docker Compose.
Sie richtet sich an **System-AdminstratorInnen einer IT Abteilung.**

## 1. Voraussetzungen

<table>
  <thead style="width:50%;">
    <tr>
      <th>Komponente</th>
      <th>Empfehlung</th>
      <th>Hinweise</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Hardware</td>
      <td>4 CPU, 8 GB RAM, min. 20 GB SSD/HDD</td>
      <td>-</td>
    </tr>
    <tr>
      <td>Linux-Server</td>
      <td>Ubuntu 20.04/22.04/24.04 LTS</td>
      <td>Getestet und empfohlen</td>
    </tr>
    <tr>
      <td>Docker Engine</td>
      <td>≥ 24.0</td>
      <td><a href="https://docs.docker.com/engine/install/ubuntu/">Installationsanleitung</a></td>
    </tr>
    <tr>
      <td>Docker Compose Plugin</td>
      <td>≥ 2.0</td>
      <td><a href="https://docs.docker.com/compose/install/linux/#install-using-the-repository">Installationsanleitung</a></td>
    </tr>
  </tbody>
</table>

### Netzwerk-Anforderungen
- **TCP-Port 80** verfügbar (oder alternativer Port via `HTTP_PORT`)
- Ausgehende Internetverbindung zu `github.com`
- Durchgehende Verbindung zum AKTIN Broker:
	- Server: `aktin-broker.klinikum.rwth-aachen.de`
	- IP-Adresse: `134.130.15.160`
	- Port: `443/tcp `

### Empfohlene Zusatzkonfiguration
- Statische IP-Adresse oder DNS-Alias
- Firewall-Konfiguration mit Beschränkung auf notwendige Ports
- SSL/TLS-Zertifikat für Produktionsumgebung


## 2. Dateien & Verzeichnisstruktur

Erstellen Sie ein dediziertes Verzeichnis für die Docker Compose-Konfiguration:

```bash
sudo -i
mkdir -p /opt/docker-deploy/aktin-dwh/dwh1
cd /opt/docker-deploy/aktin-dwh/dwh1
```

Setzen Sie die entsprechenden Berechtigungen für das Verzeichnis:

```bash
chown -R $USER:$USER /opt/docker-deploy/aktin-dwh/
chmod 750 /opt/docker-deploy/aktin-dwh/dwh1
```

## 3. Anlegen der Compose Datei und Secrets

### 3.1 Docker Compose-Datei herunterladen

```bash
cd /opt/docker-deploy/aktin-dwh/dwh1
curl -LO https://github.com/aktin/docker-aktin-dwh/releases/latest/download/compose.yml
```

### 3.2 Datenbank Password erstellen

Generieren Sie ein sicheres Passwort und speichern Sie es in einer Secret-Datei:

```bash
# Option 1: Automatische Generierung (empfohlen)
openssl rand -base64 32 > secret.txt

# Option 2: Manuelle Eingabe
echo "IhrSicheresPasswort123!" > secret.txt
```

**Sicherheitshinweis:** Verwenden Sie ausschließlich starke Passwörter mit mindestens 16 Zeichen, bestehend aus Groß- und Kleinbuchstaben, Zahlen und Sonderzeichen.

### 3.3 Umgebungsvariablen konfigurieren (Optional)

Für eine benutzerdefinierte Konfiguration für den Port des Web-Interfaces erstellen Sie eine `.env`-Datei:

```bash
echo "HTTP_PORT=8080" > .env
```

## 4. Erstmaliges Starten des AKTIN DWH

### 4.1 Services starten

```bash
cd /opt/docker-deploy/aktin-dwh/dwh1
docker compose up -d
```

Durch das Argument `-d` wird das DWH im Hintergrund gestartet. Wenn das System neu gestartet wird, started das DWH automatisch.

### 4.2 Container verifizieren

Überprüfen Sie den Status der Container:

```bash
docker compose ps
```

**Erwartete Ausgabe:** Alle Services sollten den Status `healthy` oder `running` aufweisen.

### 4.3 Erste Verbindung

Das Web-Interface ist nach erfolgreicher Installation unter folgender Adresse erreichbar:

- `http://[SERVER-IP]/aktin/admin` (bei Standard-Port 80)
- `http://[SERVER-IP]:[HTTP_PORT]/aktin/admin` (bei benutzerdefiniertem Port)

## 5. Systemkonfiguration

Stoppen Sie zunächst die Services für die Konfigurationsänderung:

```bash
cd /opt/docker-deploy/aktin-dwh/dwh1
docker compose down
```

Bearbeiten Sie die Konfigurationsdatei entsprechend der [Anleitung](install-script.html#Konfiguration_und_lokale_Einstellungen):

```bash
nano /var/lib/docker/volumes/dwh1_aktin_config/_data/aktin.properties
```

Starten Sie die Services nach der Konfiguration neu:

```bash
docker compose up -d
```

## 6. Betrieb und Wartung

### 6.1 System-Updates

Führen Sie regelmäßig Updates der Docker-Images durch:

```bash
cd /opt/docker-deploy/aktin-dwh/dwh1

# Services stoppen
docker compose down

# Neue Images laden
docker compose pull

# Services mit aktualisierten Images starten
docker compose up -d

# Ungenutzte Images entfernen (optional)
docker image prune
```

### 6.2 Monitoring und Logs

#### Container-Status überwachen

```bash
# Alle Container anzeigen
docker compose ps

# Detaillierte Informationen
docker stats

# Health-Check-Status
docker compose top
```

#### Log-Analyse

```bash
# Alle Logs anzeigen
docker compose logs

# Logs eines spezifischen Services
docker logs {{CONTAINER_NAME}}

# Live-Logs verfolgen
docker logs -f {{CONTAINER_NAME}}

# Logs mit Pagination
docker logs {{CONTAINER_NAME}} | less
```

Den Namen des entsprechenden Containers entnehmen Sie dem Befehl `docker ps`

### 6.3 Service-Management

```bash
# Einzelnen Service neustarten
# {{SERVICE}} muss durch wildfly, httpd oder database ersetzt werden
docker compose restart {{SERVICE}}

# Alle Services neustarten
docker compose restart

# Services stoppen
docker compose stop
```

## 7. Weiterführende Dokumentation
- **GitHub Repository:** [https://github.com/aktin/docker-aktin-dwh](https://github.com/aktin/docker-aktin-dwh)
- **Docker Dokumentation:** [https://docs.docker.com](https://docs.docker.com)
