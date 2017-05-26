#!/bin/bash
############################################
# Arcus setup for single node cluster (demo)
############################################

## Get working directory based on the location of this script.
##
## @param $1 location of this script ($0)
## @return working directory
get_working_directory() {
  pushd $(dirname $0)/.. > /dev/null
  local curr_dir=$(pwd)
  popd > /dev/null
  echo $curr_dir
}

## Setup arcus directories
##
## @param location of zkCli.sh
## @param zookeeper's host:port
setup() {
  local zkcli=$1
  local zkaddr=$2

  $zkcli -server $zkaddr create /arcus 0
  $zkcli -server $zkaddr create /arcus/cache_list 0
  $zkcli -server $zkaddr create /arcus/cache_list/test 0
  $zkcli -server $zkaddr create /arcus/client_list 0
  $zkcli -server $zkaddr create /arcus/client_list/test 0
  $zkcli -server $zkaddr create /arcus/cache_server_mapping 0
  $zkcli -server $zkaddr create /arcus/cache_server_mapping/127.0.0.1:11211 '{"threads":"6", "memlimit":"100", "port":"11211", "connections":"1000"}'
  $zkcli -server $zkaddr create /arcus/cache_server_mapping/127.0.0.1:11211/test 0
  $zkcli -server $zkaddr create /arcus/cache_server_mapping/127.0.0.1:11212 '{"threads":"6", "memlimit":"100", "port":"11212", "connections":"1000"}'
  $zkcli -server $zkaddr create /arcus/cache_server_mapping/127.0.0.1:11212/test 0

  $zkcli -server $zkaddr get /arcus
}

## Delete arcus directories
##
## @param location of zkCli.sh
## @param zookeeper's host:port
rollback() {
  local zkcli=$1
  local zkaddr=$2

  $zkcli -server $zkaddr delete /arcus/cache_list/test
  $zkcli -server $zkaddr delete /arcus/cache_list
  $zkcli -server $zkaddr delete /arcus/client_list/test
  $zkcli -server $zkaddr delete /arcus/client_list
  $zkcli -server $zkaddr delete /arcus/cache_server_mapping/127.0.0.1:11211/test
  $zkcli -server $zkaddr delete /arcus/cache_server_mapping/127.0.0.1:11211
  $zkcli -server $zkaddr delete /arcus/cache_server_mapping/127.0.0.1:11212/test
  $zkcli -server $zkaddr delete /arcus/cache_server_mapping/127.0.0.1:11212
  $zkcli -server $zkaddr delete /arcus/cache_server_mapping
  $zkcli -server $zkaddr delete /arcus
}

## Main

if [ "$#" -ne 2 ]; then
  echo "$0 [setup|rollback] <zookeeper ip:port>"
  exit 1
fi

PKG_DIR=$(get_working_directory $0)
ZKCLI=$PKG_DIR/zookeeper/bin/zkCli.sh
ZKIPPORT=$2
OPTION=$1

case $OPTION in
  "setup")
  setup $ZKCLI $ZKIPPORT
  ;;

  "rollback")
  rollback $ZKCLI $ZKIPPORT
  ;;

  *)
  echo "$0 [setup|rollback] <zookeeper ip:port>"
  ;;
esac

