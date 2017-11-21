#!/bin/bash

## arcus directory
pushd $(dirname $0)/../.. > /dev/null
arcus_directory=$(pwd)
popd > /dev/null

## Set trap for catching error
trap "stop_build" ERR

## Stop build when error is occurred
stop_build() {
    echo ""
    echo "Error has occurred. $0 has failed."
    exit -1
}

## Get working directory based on the location of this script.
##
## @param $1 location of this script ($0)
## @return working directory
get_working_directory() {
  pushd $(dirname $0)/../.. > /dev/null
  CURR_DIR=$(pwd)
  popd > /dev/null
  echo $CURR_DIR
}

WORKDIR=$(get_working_directory $0)

if [ -z "$WORKDIR" ]; then
  exit 1
fi

pushd $WORKDIR >> $arcus_directory/scripts/build.log
printf "[git submodule init] .. START"
git submodule init 1>> $arcus_directory/scripts/build.log 2>&1
printf "\r[git submodule init] .. SUCCEED\n"
printf "[git submodule update] .. START"
git submodule update 1>> $arcus_directory/scripts/build.log 2>&1
printf "\r[git submodule update] .. SUCCEED\n"
popd >> $arcus_directory/scripts/build.log

# server
printf "[server/config/autorun.sh] .. START"
echo "===== server ======" >> $arcus_directory/scripts/build.log
pushd $WORKDIR/server >> $arcus_directory/scripts/build.log
/bin/bash config/autorun.sh 1>> $arcus_directory/scripts/build.log 2>&1
popd >> $arcus_directory/scripts/build.log
printf "\r[server/config/autorun.sh] .. SUCCEED\n"

# clients/c
printf "[clients/c/config/autorun.sh] .. START"
echo "===== client ======" >> $arcus_directory/scripts/build.log
pushd $WORKDIR/clients/c >> $arcus_directory/scripts/build.log
/bin/bash config/autorun.sh 1>> $arcus_directory/scripts/build.log 2>&1
popd >> $arcus_directory/scripts/build.log
printf "\r[clients/c/config/autorun.sh] .. SUCCEED\n"

# deps/libevent -- uncomment below if you got libevent from the source
#echo "===== libevent ======"
#pushd $WORKDIR/deps/libevent
#./autogen.sh
#popd

# zookeeper
#echo "===== zookeeper ======" | tee -a $arcus_directory/scripts/build.log
echo "===== zookeeper ======" >> $arcus_directory/scripts/build.log
printf "[zookeeper/ant clean compile_jute bin-package] .. START"
pushd $WORKDIR/zookeeper >> $arcus_directory/scripts/build.log
sed -i -e s/,api-report//g build.xml 1>> $arcus_directory/scripts/build.log 2>&1 # FIXME it looks like that api-report does not work properly (causing NPE)
ant clean compile_jute bin-package 1>> $arcus_directory/scripts/build.log 2>&1
popd >> $arcus_directory/scripts/build.log
printf "\r[zookeeper/ant clean compile_jute bin-package] .. SUCCEED\n"
printf "[zookeeper/src/c/autoreconf -if] .. START"
pushd $WORKDIR/zookeeper/src/c >> $arcus_directory/scripts/build.log
autoreconf -if 1>> $arcus_directory/scripts/build.log 2>&1
popd >> $arcus_directory/scripts/build.log
printf "\r[zookeeper/src/c/autoreconf -if] .. SUCCEED\n"

