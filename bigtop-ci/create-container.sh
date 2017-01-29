#!/bin/bash

while [[ $# -gt 1 ]]
do
key="$1"
case $key in
    -t|--target)
    TARGET="$2"
    shift
    ;;
    -o|--os)
    OS="$2" 
    shift
    ;;
    -n|--nexus)
    NEXUS="--net=container:nexus"
    CONFIGURE_NEXUS="configure-nexus"
    shift
    ;;
    *)
    echo "usage build.sh --os debian-8|centos-7|... --target hadoop|tez|..."
    exit 1 # unknown option
    ;;
esac
shift
done

# prepare source image
cat >Dockerfile <<EOF
FROM bigtop/slaves:$OS
# copy source to container
COPY . /var/lib/jenkins/bigtop
# make it belong to compile account
# disable gradle daemon
RUN chown -R jenkins /var/lib/jenkins/bigtop && sed -i /GRADLE/d /etc/profile.d/bigtop.sh
# define default user jenkins
USER jenkins
WORKDIR /var/lib/jenkins/bigtop
ENTRYPOINT [ "bigtop-ci/entrypoint.sh" ]
# initialize gradle
RUN bigtop-ci/entrypoint.sh
# make it a volume, performancewise
VOLUME /var/lib/jenkins
EOF

# build source image
docker build -t image-$OS .

# This container collects all the output
# use gradle option "-m" 
docker run --name container-$OS image-$OS -m help

