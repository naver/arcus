#!/bin/bash

## arcus directory
pushd `dirname $0`/../.. > /dev/null
arcus_directory=`pwd`
popd > /dev/null

## Set trap for catching error
trap "stop_build" ERR

## Stop build when error is occured
stop_build() {
    echo ""
    echo "Error has occured. $0 has failed."
    exit -1
}

## Get working directory based on the location of this script.
##
## @param $1 location of this script ($0)
## @return working directory
get_working_directory() {
  pushd `dirname $0`/../.. > /dev/null
  CURR_DIR=`pwd`
  popd > /dev/null
  echo $CURR_DIR
}

WORKDIR=$(get_working_directory $0)

if [ -z "$WORKDIR" ]; then
  exit 1
fi

pushd $WORKDIR >> $arcus_directory/scripts/build.log
printf "clone server, client, zookeeper start"
git submodule init 1>> $arcus_directory/scripts/build.log 2>&1
git submodule update 1>> $arcus_directory/scripts/build.log 2>&1
printf "\rclone server, client, zookeeper succeed\n"
popd >> $arcus_directory/scripts/build.log

# server
echo "===== server ======" | tee -a $arcus_directory/scripts/build.log
printf "configure arcus_memcached start"
pushd $WORKDIR/server >> $arcus_directory/scripts/build.log
/bin/bash config/autorun.sh 1>> $arcus_directory/scripts/build.log 2>&1
printf "\rconfigure arcus_memcached succeed\n"
popd >> $arcus_directory/scripts/build.log

# clients/c
echo "===== client ======" | tee -a $arcus_directory/scripts/build.log
pushd $WORKDIR/clients/c >> $arcus_directory/scripts/build.log
printf "configure client start"
/bin/bash config/autorun.sh 1>> $arcus_directory/scripts/build.log 2>&1
printf "\rconfigure client succeed\n"
popd >> $arcus_directory/scripts/build.log

# deps/libevent -- uncomment below if you got libevent from the source
#echo "===== libevent ======"
#pushd $WORKDIR/deps/libevent
#./autogen.sh
#popd

# zookeeper
echo "===== zookeeper ======" | tee -a $arcus_directory/scripts/build.log
pushd $WORKDIR/zookeeper >> $arcus_directory/scripts/build.log
sed -i -e s/,api-report//g build.xml 1>> $arcus_directory/scripts/build.log 2>&1 # FIXME it looks like that api-report does not work properly (causing NPE)
ant clean compile_jute bin-package 1>> $arcus_directory/scripts/build.log 2>&1
popd >> $arcus_directory/scripts/build.log
pushd $WORKDIR/zookeeper/src/c >> $arcus_directory/scripts/build.log
printf "auto re-configure zookeeper start"
autoreconf -if 1>> $arcus_directory/scripts/build.log 2>&1
printf "\rauto re-configure zookeeper succeed\n"
popd >> $arcus_directory/scripts/build.log

