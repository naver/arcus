#!/bin/bash
############################################
# A simple script to manage Arcus
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

## Extract a value from the JSON string
## 
## @param $1 json string
## @param $2 element name
## @return element value
get_json_element_value() {
  local json_string=$1
  local element_name=$2

  echo $json_string | grep -Po '(?<="'$element_name'":")[^"]*'
}

print_usage() {
  echo "Arcus usages:"
  echo "  $0 zookeeper [start|stop|restart]"
  echo "  $0 server list <zookeeper host:port list>"
  echo "  $0 server [start|stop] <zookeeper host:port list> <server ip:port>"
}

## Main

PKG_DIR=$(get_working_directory $0)
ZK_CLI=$PKG_DIR/zookeeper/bin/zkCli.sh
ZK_SERVER=$PKG_DIR/zookeeper/bin/zkServer.sh
ARCUS_SERVER=$PKG_DIR/bin/memcached
ARCUS_SERVER_ENGINE=$PKG_DIR/lib/default_engine.so

MODULE=$1
MODE=$2

case $MODULE in
  "zookeeper")
    case $MODE in
      "start")
      $ZK_SERVER start
      ;;

      "stop")
      $ZK_SERVER stop
      ;;

      "restart")
      $ZK_SERVER restart
      ;;

      *)
      print_usage
      ;;
    esac
  ;;

  "server")
    ZK_HOSTPORT=$3
    HOSTPORT=$4

    case $MODE in
      "list")
      CURR_IP==$(hostname -I)
      LIST=$($ZK_CLI -server $ZK_HOSTPORT ls /arcus/cache_server_mapping | tail -n 4 | grep -e "\[" | sed s/[][]//g | sed s/,\ /\ /g)
      for hostport in $LIST; do
        code=$($ZK_CLI -server $ZK_HOSTPORT ls /arcus/cache_server_mapping/$hostport | tail -n 4 | grep -e "\[" | sed s/[][]//g)
        config=$($ZK_CLI -server $ZK_HOSTPORT get /arcus/cache_server_mapping/$hostport 2> /dev/null | tail -n 1)
        echo "$hostport -> $code $config"
      done
      ;;

      "start")
      # read config from zookeeper
      config_in_json=$($ZK_CLI -server $ZK_HOSTPORT get /arcus/cache_server_mapping/$HOSTPORT 2> /dev/null | tail -n 1)
      invalid=$(echo $config_in_json | grep WatchedEvent)
      if [ -z "$config_in_json" ] || [ ! -z "$invalid" ]; then
        echo "Arcus server for $HOSTPORT does not exist."
        exit 1
      fi

      echo "Arcus server config: $config_in_json"

      # parse config values
          threads=$(get_json_element_value "$config_in_json" "threads")
         memlimit=$(get_json_element_value "$config_in_json" "memlimit")
             port=$(get_json_element_value "$config_in_json" "port")
      connections=$(get_json_element_value "$config_in_json" "connections")

      # start
      $PKG_DIR/bin/memcached -E $PKG_DIR/lib/default_engine.so -X $PKG_DIR/lib/syslog_logger.so $PKG_DIR/lib/ascii_scrub.so -d -v -r -R5 -U 0 -b 8192 -m$memlimit -p $port -c $connections -t $threads -z $ZK_HOSTPORT
      ;;

      "stop")
      port=$(echo $HOSTPORT | awk -F: '{print $2}')
      if [ -z "$port" ]; then
        echo "Invalid option: $HOSTPORT"
        exit 1
      fi
      procnum=$(ps -ef | grep -e memcached | grep -e "-p $port" | awk '{print $2}')
      if [ -z "$procnum" ]; then
        echo "Arcus server for $HOSTPORT is not running."
        exit 1
      fi
      kill -INT $procnum
      ;;

      *)
      print_usage
      ;;
    esac
  ;;

  *)
  print_usage
  ;;
esac

