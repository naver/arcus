#!/bin/bash

## arcus folder
pushd `dirname $0`/../.. > /dev/null
arcus_folder=`pwd`
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

pushd $WORKDIR >> $arcus_folder/build_log
printf "cloning arcus_memcached && arcus_zookeeper"
git submodule init &>> $arcus_folder/build_log
git submodule update &>> $arcus_folder/build_log
printf "\rclone arcus_memcached && arcus_zookeeper succeed\n"
popd >> $arcus_folder/build_log

# server
echo "===== server ======" >> $arcus_folder/build_log
printf "configure arcus_memcached start"
pushd $WORKDIR/server >> $arcus_folder/build_log
/bin/bash config/autorun.sh &>> $arcus_folder/build_log
printf "\rconfigure arcus_memcached succeed\n"
popd >> $arcus_folder/build_log

# clients/c
echo "===== c client ======" >> $arcus_folder/build_log
pushd $WORKDIR/clients/c >> $arcus_folder/build_log
printf "configure arcus_zookeeper start"
/bin/bash config/autorun.sh &>> $arcus_folder/build_log
printf "\rconfigure arcus_zookeeper succeed\n"
popd >> $arcus_folder/build_log

# deps/libevent -- uncomment below if you got libevent from the source
#echo "===== libevent ======"
#pushd $WORKDIR/deps/libevent
#./autogen.sh
#popd

# zookeeper
echo "===== zookeeper ======" >> $arcus_folder/build_log
pushd $WORKDIR/zookeeper >> $arcus_folder/build_log
sed -i -e s/,api-report//g build.xml &>> $arcus_folder/build_log # FIXME it looks like that api-report does not work properly (causing NPE)
ant clean compile_jute bin-package &>> $arcus_folder/build_log
popd >> $arcus_folder/build_log
pushd $WORKDIR/zookeeper/src/c >> $arcus_folder/build_log
printf "auto re-configure arcus_zookeeper start"
autoreconf -if &>> $arcus_folder/build_log
printf "\rauto re-configure arcus_zookeeper succeed\n"
popd >> $arcus_folder/build_log

