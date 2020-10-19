1. Run `mvn clean install` to create a `tar.gz`-file of the integration test with `demo-server` and `dwh-installer` (which also includes `dwh-update`). 

2. After finishing the build, run `docker build --tag {YOUR_NAME}:{YOUR_TAG} .` to create a docker container with the newly created file. The docker container will automatically copy and unzip the file into `/home`. 

3. Run `docker run -it --privileged {YOUR_NAME}:{YOUR_TAG}` to access your docker container.

4. Go into the folder `/home/dwh-integration-test` and run `./aktin_integration_test.sh` to create a development environment for `dwh-installer`. The skript will automatically run `dwh-installer` and `dwh-update` as well as add demo data to the i2b2 database and switch the i2b2 webclient to debug mode. Additionally some integration tests will be run after the installation.
