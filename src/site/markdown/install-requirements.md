<h3><u>Manuelle Installation des Betriebssystems für den AKTIN-Applikationsserver</u></h3>
Grundsätzlich ist die Software auf allen Linux-Systemen verwendbar. Für eine manuelle Installation anderer Linux-Distributionen empfehlen wir eine Anpassung der gelieferten Skripte. Sollten Sie dazu Fragen haben, wenden Sie sich gerne an uns unter [it-support@aktin.org](mailto:it-support@aktin.org).

Für Ubuntu Server 20.04 LTS werden Skripte für eine automatische Installation und Konfiguration bereitgestellt. Es wird an dieser Stelle explizit darauf verwiesen, dass das Installationsskript aktuell nur mit Ubuntu Server 20.04 LTS getestet wurde.
<br></br>

<h4>Nachfolgende Hinweise zur Installation</h4>

<!--  MACRO{toc|section=0|fromDepth=3|toDepth=6} -->
<br></br>

<h5>1. Download der Installationsdatei</h5>

Für eine Neuinstallation wird [Ubuntu Server 20.04 LTS](https://releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso) empfohlen. Dabei handelt es sich um eine minimalistische Ubuntu-Version, optimiert für das Betreiben von Servern. Unter dem angegebenen Link finden Sie die Möglichkeit, eine `.iso`-Datei herunterzuladen. Diese Datei muss anschließend auf ein Installationsmedium (CD oder bootfähiger USB-Stick) kopiert werden und kann dann genutzt werden, um auf einem gegebenen System Ubuntu zu installieren.
<br></br>

<h5>2. Welcome!</h5>

Zum Start der Installation werden Sie aufgefordert, eine Sprache für die Installation und das zu installierende Betriebssystem zu wählen. Die hier gewählte Einstellung ist unabhängig von der Sprache des AKTIN Data Warehouse.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_1.png" alt="img1" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>3. Installer update</h5>

In manchen Fällen ist bereits eine aktuellere Version der Installationssoftware vorhanden. Bestätigen Sie in diesem Fall die Eingabe, um die neuste Version herunterzuladen. Dieser Vorgang dauert nur wenige Minuten.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_2.png" alt="img2" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>4. Keyboard configuration</h5>

Das Schema Ihrer Tastatur können Sie aus den beiden angezeigten Reitern auswählen. Alternativ lässt sich über _Identify keyboard_ das Schema auch automatisch ermitteln. Dafür werden Sie aufgefordert, einzelne Buchstaben und Zeichen einzutippen.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_3.png" alt="img3" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>5. Network connections</h5>

In diesem Dialogfeld werden Ihnen sämtliche detektierte Netzwerkschnittstellen aufgezeigt. Wählen Sie eine der Schnittstellen aus, um einen Zugang zum Internet festzulegen.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_4.png" alt="img4" style="width:600px;height:450px;"></img>
</div>
<br></br>

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_4_1.png" alt="img4_1" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>6. Configure proxy</h5>

Optional ist es möglich, eine Proxy für die Installation einzurichten, sollte Ihr System keinen direkten Zugriff auf das Internet haben. Geben Sie dabei die Adresse der Proxy wie angezeigt in der Form von `http://[[user][:pass]@]host[:port]/` in das Feld ein. Nach Abschluss der Installation kann der Proxyzugang auch wieder deaktiviert werden.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_5.png" alt="img5" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>7. Configure Ubuntu archive mirror</h5>

In diesem Feld ist es möglich, einen alternativen Download-Mirror für das Herunterladen von Ubuntu-Pakaten anzugeben. Grundsätzlich ist es empfehlenswert, hier die Standardeinstellungen beizubehalten.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_6.png" alt="img6" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>8. Storage configuration</h5>

Bei der Zuteilung des Speicherplatzes bzw. der Partitionierung ist es empfehlenswert, den gesamten Speicherplatz in einer Partition zu verwenden. Behalten Sie dafür die Standardeinstellungen einfach bei. Beachten Sie jedoch, dass alle vorhandenen Daten auf dieser Partition dabei gelöscht werden. Sie können die Partitionierung auch individuell vornehmen, sollten dann aber berücksichtigen, dass der Speicherplatz der Partition mindestens 50 Gigabyte beträgt.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_7.png" alt="img7" style="width:600px;height:450px;"></img>
</div>
<br></br>

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_8.png" alt="img8" style="width:600px;height:450px;"></img>
</div>
<br></br>

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_9.png" alt="img9" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>9. Profile setup</h5>

Anschließend müssen Sie einen Benutzer für das Betriebssystem erstellen. Für das Passwort empfehlen wir, eine Kombination aus Buchstaben (Ausnahme „y“, „z“ sowie Umlaute) und Zahlen zu verwenden. Somit können sich bei einer möglicher Fehl-Konfiguration des Tastaturschemas dennoch problemlos anmelden. Sowohl Benutzer als auch Server können Sie beliebig benennen. Name und Passwort des Benutzers sollten hier dennoch notiert werden. Der Benutzer wird zwar nicht auf das AKTIN Data Warehouse zugreifen, aber benötigt, um den Nutzer `root` freizuschalten.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_10.png" alt="img10" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>10. SSH Setup + Featured Server Snaps</h5>

Im Dialogfeld für die Softwareauswahl ist darauf zu achten, dass NUR “SSH server” zusätzlich installiert wird. Alle anderen Häkchen sollten entfernt werden. Auf diese Weise wird sichergestellt, dass keine unnötige Software oder Internetdienste auf dem Server installiert werden.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_11.png" alt="img11" style="width:600px;height:450px;"></img>
</div>
<br></br>

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_12.png" alt="img12" style="width:600px;height:450px;"></img>
</div>
<br></br>

<h5>11. Installation complete!</h5>

Nach Abschluss aller Einstellungen beginnt die eigentliche Installation des Betriebssystems. Sie müssen hier keine weiteren Eingriffe mehr vornehmen. Sofern vorhanden, werden am Ende der Installation noch Sicherheitsupdates installiert. Lassen Sie auch diese einfach durchlaufen. Anschließend müssen Sie das System neustarten. Die Installation ist somit abgeschlossen und das AKTIN Data Warehouse kann im nächsten Schritt von dem [AKTIN-Installationsskript](install-script.html) installiert werden.

<div style="text-align:center">
<img src="screens_ubuntu/ubuntu_13.png" alt="img13" style="width:600px;height:450px;"></img>
</div>
