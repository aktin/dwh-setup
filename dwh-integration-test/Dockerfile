FROM ubuntu:20.04
MAINTAINER "Alexander Kombeiz" <akombeiz@ukaachen.de>

# copy everything in the same directory as this dockerfile into CONTAINER:/opt/
COPY / /opt/

# run aktin installation script
RUN cd /opt/ && ./aktin_install.sh

# run integration test script
RUN cd /opt/integration && ./test_integration.sh

# open ports
EXPOSE 80
EXPOSE 9090
