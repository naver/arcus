#!/bin/bash

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

pushd $WORKDIR
git submodule init
git submodule update
popd

# server
echo "===== server ======"
pushd $WORKDIR/server
/bin/bash config/autorun.sh
popd

# clients/c
echo "===== c client ======"
pushd $WORKDIR/clients/c
/bin/bash config/autorun.sh
popd

# deps/libevent -- uncomment below if you got libevent from the source
#echo "===== libevent ======"
#pushd $WORKDIR/deps/libevent
#./autogen.sh
#popd

# zookeeper
echo "===== zookeeper ======"
pushd $WORKDIR/zookeeper
sed -i -e s/,api-report//g build.xml # FIXME it looks like that api-report does not work properly (causing NPE)
ant clean compile_jute bin-package
popd
pushd $WORKDIR/zookeeper/src/c
autoreconf -if
popd

