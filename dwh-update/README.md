1. Run `mvn clean install` to create a `tar.gz`-file of the latest update. During the build, the latest version of the EAR is automatically fetched into the `packages`-folder. 

2. Copy the `tar.gz`-file to your server, unzip it and run `aktin_update.sh` to automatically install the update and deploy the newest EAR.
