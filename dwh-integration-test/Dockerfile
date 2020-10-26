#FROM ubuntu:20.04
# run in console: docker run -it --privileged -p 81:80 -p 9090:9090 <NAME>:<TAG>

FROM jrei/systemd-ubuntu:20.04
#run  in console: docker run -d --privileged -p 81:80 -p 9090:9090 --tmpfs /tmp --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro <NAME>:<TAG>
#after that: docker exec -it <ID> sh

MAINTAINER "Alexander Kombeiz" <akombeiz@ukaachen.de>

# copy everything in the same directory as this dockerfile into CONTAINER:/opt/
COPY /target/dwh-integration-test-*.tar.gz /root/

# add aktin integration test with aktin installation to /root
RUN cd /root/ && tar -xvzf dwh-integration-test-*.tar.gz && cd dwh-integration-test && chmod +x aktin_integration_test.sh

# open ports
EXPOSE 80
EXPOSE 9090
