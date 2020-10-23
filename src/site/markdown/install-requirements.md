<h3><u>Manuelle Installation des Betriebssystems für den AKTIN-Applikationsserver</u></h3>
Grundsätzlich ist die Software auf allen Linux-Systemen verwendbar. Für eine manuelle Installation anderer Linux-Distributionen empfehlen wir eine Anpassung der gelieferten Skripte. Sollten Sie dazu Fragen haben, wenden Sie sich gerne an uns unter [it-support@aktin.org](mailto:it-support@aktin.org).

Für Ubuntu 20.04 LTS werden Skripte für eine automatische Installation und Konfiguration bereitgestellt. Es wird an dieser Stelle explizit darauf verwiesen, dass das Installationsskript aktuell nur mit Ubuntu 20.04 LTS und Ubuntu 18.04 LTS getestet wurde.
<br></br>

<h4>Nachfolgende Hinweise zur Installation</h4>

<!--  MACRO{toc|section=0|fromDepth=3|toDepth=6} -->
<br></br>

<h5>1. Download der Installationsdatei</h5>

Für eine Neuinstallation wird [Ubuntu Server 20.04 LTS](https://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso) empfohlen. Dabei handelt es sich um eine minimalistische Ubuntu-Version optimiert für das Betreiben von Servern. Unter dem angegebenen Link finden Sie die Möglichkeit, eine `.iso`-Datei herunterzuladen. Diese Datei muss anschließend auf ein Installationsmedium (CD oder bootfähiger USB-Stick) kopiert werden und kann dann genutzt werden, um auf einem gegebenen System Ubuntu zu installieren. 
<br></br>

<h5>2. Welcome!</h5>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla posuere ipsum ac nulla luctus, sed cursus erat volutpat. Vestibulum ut convallis tortor. Suspendisse commodo enim est, in condimentum enim vulputate a. Duis ut faucibus metus. Praesent tellus lorem, mattis vitae sagittis viverra, iaculis ac mauris. Cras mattis, odio non molestie.

<img src="screens_ubuntu/ubuntu_1.png" alt="img1" style="width:600px;height:450px;"></img>
<br></br>

<h5>3. Installer update</h5>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla posuere ipsum ac nulla luctus, sed cursus erat volutpat. Vestibulum ut convallis tortor. Suspendisse commodo enim est, in condimentum enim vulputate a. Duis ut faucibus metus. Praesent tellus lorem, mattis vitae sagittis viverra, iaculis ac mauris. Cras mattis, odio non molestie.

<img src="screens_ubuntu/ubuntu_2.png" alt="img2" style="width:600px;height:450px;"></img>
<br></br>

<h5>4. Keyboard configuration</h5>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla posuere ipsum ac nulla luctus, sed cursus erat volutpat. Vestibulum ut convallis tortor. Suspendisse commodo enim est, in condimentum enim vulputate a. Duis ut faucibus metus. Praesent tellus lorem, mattis vitae sagittis viverra, iaculis ac mauris. Cras mattis, odio non molestie.

<img src="screens_ubuntu/ubuntu_3.png" alt="img3" style="width:600px;height:450px;"></img>
<br></br>

<h5>5. Network connections</h5>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla posuere ipsum ac nulla luctus, sed cursus erat volutpat. Vestibulum ut convallis tortor. Suspendisse commodo enim est, in condimentum enim vulputate a. Duis ut faucibus metus. Praesent tellus lorem, mattis vitae sagittis viverra, iaculis ac mauris. Cras mattis, odio non molestie.

<img src="screens_ubuntu/ubuntu_4.png" alt="img4" style="width:600px;height:450px;"></img>
<br></br>

<img src="screens_ubuntu/ubuntu_4_1.png" alt="img4_1" style="width:600px;height:450px;"></img>
<br></br>

<h5>6. Configure proxy</h5>

Sollte Ihr System keinen direkten Zugriff auf das Internet haben, ist es empfehlenswert, eine Proxy für die Installation einzurichten, um das Herunterladen von Sicherheitsupdates und zusätzlichen Paketen zu ermöglichen. Nach Abschluss der Installation kann der Proxyzugang wieder deaktiviert werden.

<img src="screens_ubuntu/ubuntu_5.png" alt="img5" style="width:600px;height:450px;"></img>
<br></br>

<h5>7. Ubuntu archive mirror</h5>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla posuere ipsum ac nulla luctus, sed cursus erat volutpat. Vestibulum ut convallis tortor. Suspendisse commodo enim est, in condimentum enim vulputate a. Duis ut faucibus metus. Praesent tellus lorem, mattis vitae sagittis viverra, iaculis ac mauris. Cras mattis, odio non molestie.

<img src="screens_ubuntu/ubuntu_6.png" alt="img6" style="width:600px;height:450px;"></img>
<br></br>

<h5>8. Storage configuration</h5>

Bei der Zuteilung des Speicherplatzes bzw. der Partitionierung ist es empfehlenswert, den gesamten Speicherplatz in einer Partition zu verwenden. Sie können die Verteilung des Speicherplatzes aber auch individuell gestalten. Dabei sollten Sie jedoch berücksichtigen, dass die `/var`-Partition den größten Anteil des Speicherplatzes erhält. Eine separate `/home`-Partition wird nicht benötigt.

<img src="screens_ubuntu/ubuntu_7.png" alt="img7" style="width:600px;height:450px;"></img>
<br></br>

<img src="screens_ubuntu/ubuntu_8.png" alt="img8" style="width:600px;height:450px;"></img>
<br></br>

<img src="screens_ubuntu/ubuntu_9.png" alt="img9" style="width:600px;height:450px;"></img>
<br></br>

<h5>9. Profile setup</h5>

Bei der Eingabe des root-Passworts empfehlen wir eine Kombination aus Buchstaben (Ausnahme „y“, „z“ sowie Umlaute) und Zahlen zu verwenden. Somit können sich bei einer möglicher Fehl-Konfiguration des Tastaturlayouts dennoch problemlos einloggen. Anschließend muss ein weiterer Benutzer angelegt werden. Diesen Benutzer können Sie benennen wie Sie möchten. Name und Passwort sollten hier dennoch notiert werden. Dieser Benutzer wird nicht auf AKTIN zugreifen.

<img src="screens_ubuntu/ubuntu_10.png" alt="img10" style="width:600px;height:450px;"></img>
<br></br>

<h5>10. SSH Setup + Featured Server Snaps</h5>

Im Dialogfeld für die Softwareauswahl ist darauf zu achten, dass NUR “SSH server” zusätzlich installiert wird. Alle anderen Häkchen sollten entfernt werden. Auf diese Weise wird sichergestellt, dass keine unnötige Software oder Internetdienste auf dem Server installiert werden.

<img src="screens_ubuntu/ubuntu_11.png" alt="img11" style="width:600px;height:450px;"></img>

<img src="screens_ubuntu/ubuntu_12.png" alt="img12" style="width:600px;height:450px;"></img>
<br></br>

<h5>11. Bootloader</h5>

Nach Abschluss des Installationsassistenten muss der Boot-Loader auf die Festplatte geschrieben werden. Dies müssen Sie explizit bestätigen. Anschließend startet das System neu. Die Installation ist somit abgeschlossen und AKTIN kann im nächsten Schritt von dem [AKTIN-Installationsskript](install-script.html) installiert werden.

<img src="screens_ubuntu/ubuntu_13.png" alt="img13" style="width:600px;height:450px;"></img>
