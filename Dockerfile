# Arcus Dockerfile
FROM     openjdk:slim

MAINTAINER Bae jiun <maytryark@gmail.com>

# Set work directory
ENV SRC_DIR /opt

# Dependency:
RUN apt-get update && apt-get install -y \
    supervisor openssh-server aptitude net-tools iputils-ping curl \
    build-essential make gcc g++ autoconf automake libtool libextutils-pkgconfig-perl libcppunit-dev \
    git netcat python2.7-dev python-setuptools subversion

# Dependency: ANT
RUN apt-get install -y ant

ENV ANT_HOME /usr/share/ant
ENV PATH $PATH:$ANT_HOME/bin

# Build Arcus
RUN cd $SRC_DIR && git clone https://github.com/naver/arcus.git \
 && cd arcus/scripts && ./build.sh
