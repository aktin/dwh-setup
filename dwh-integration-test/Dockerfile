FROM ubuntu:20.04
MAINTAINER "Alexander Kombeiz" <akombeiz@ukaachen.de>

# copy everything in the same directory as this dockerfile into CONTAINER:/opt/
COPY /target/dwh-integration-test-*.tar.gz /root/

# add aktin integration test with aktin installation to /root
RUN cd /root/ && tar -xvzf dwh-integration-test-*.tar.gz && cd dwh-integration-test && chmod +x aktin_integration_test.sh

# open ports
EXPOSE 80
EXPOSE 9090
