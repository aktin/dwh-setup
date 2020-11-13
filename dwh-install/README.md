1. Run `mvn clean install` to create a `tar.gz`-file of the installer with the name `dwh-install-{VERSION}`. The latest version of `dwh-update` is also included in the folder`packages` inside the file. 

2. Copy the file on your server and unzip it with `tar -zxvf dwh-install-{VERSION}`. Inside the newly created folder, run `./aktin_install.sh` to automatically download and install all components. `dwh-update` will also be executed automatically during the installation.

3. After the installation finishes, `wildfly`, `postgresql` and `apache2` will start automatically. The i2b2 webclient can be accessed via `localhost:80/webclient` while the AKTIN webclient can be accessed via `localhost:80/aktin/admin`.
