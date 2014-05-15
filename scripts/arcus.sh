#!/bin/bash
############################################
# arcus.sh
############################################

# default zookeeper list
zklist="127.0.0.1:2181"

## Get working directory based on the location of this script.
##
## @param $1 location of this script ($0)
## @return working directory
get_working_directory() {
  pushd `dirname $0`/.. > /dev/null
  CURR_DIR=`pwd`
  popd > /dev/null
  echo $CURR_DIR
}
 
function usage()
{
    echo "Usage:"
    echo "  $0 -h"
    echo "  $0 [-z <zklist>] deploy <conf_file> | ping <service_code>"
    echo "  $0 [-z <zklist>] zookeeper init"
    echo "  $0 [-z <zklist>] zookeeper start|stop|stat"
    echo "  $0 [-z <zklist>] memcached register <conf_file> | unregister <service_code>"
    echo "  $0 [-z <zklist>] memcached start|stop|list <service_code>"
    echo "  $0 [-z <zklist>] memcached listall"
    echo "  $0 [-z <zklist>] quicksetup <conf_file>"
    exit 1
}
 
function die()
{
    echo "$*"
    exit 1
}
 
function get_opts() {
    argv=()
    while [ $# -gt 0 ]
    do
        opt=$1
        shift
        case ${opt} in
            -z|--zklist)
                if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
                    die "The ${opt} option requires an argument."
                fi
                zklist="$1"
                shift
                ;;
            -h|--help)
                usage;;
            *)
                if [ "${opt:0:1}" = "-" ]; then
                    die "${opt}: unknown option."
                fi
                argv+=(${opt})
                ;;
        esac
    done
}

## MAIN ##

WORK_DIR=$(get_working_directory $0)
export PYTHONPATH=$WORK_DIR/lib/python/site-packages:$PYTHONPATH
 
get_opts $*
#echo "zklist => ${zklist}"
#echo "argv => ${argv[@]}"
 
idx=0;
for str in "${argv[@]}"
do
   idx=`expr $idx + 1`
   #echo "argv[$idx] = $str"
done

zklist=${zklist//,/\\,} # commas must be headed by back-slashes in fabric

case ${argv[0]} in
    memcached)
        if [[ -z "${argv[2]}" && "${argv[1]}" != "listall" ]]; then
            usage
        fi
        case ${argv[1]} in
            register)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}"\,config="${argv[2]}" mc_register
                ;;
            unregister)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" mc_unregister:"${argv[2]}"
                ;;
            start)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" mc_start:"${argv[2]}"
                ;;
            stop)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" mc_stop:"${argv[2]}"
                ;;
            list)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" mc_list:"${argv[2]}"
                ;;
            listall)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" mc_list
                ;;
            *)
                usage
                ;;
        esac
        ;;
    zookeeper)
        case ${argv[1]} in
            init)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" zk_init
                ;;
            start)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" zk_start
                ;;
            stop)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" zk_stop
                ;;
            stat)
                $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" zk_stat
                ;;
            *)
                usage
                ;;
            esac
        ;;
    deploy)
        if [ -z "${argv[1]}" ]; then
            usage
        fi
        $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}"\,config="${argv[1]}" deploy
        ;;
    ping)
        if [ -z "${argv[1]}" ]; then
            usage
        fi
        $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}" ping:"${argv[1]}"
        ;;
    quicksetup)
        if [ -z "${argv[1]}" ]; then
            usage
        fi
        $WORK_DIR/scripts/fab --fabfile=$WORK_DIR/scripts/fabfile.py --set zklist="${zklist}"\,config="${argv[1]}" quicksetup
        ;;
    *)
        usage
        ;;
esac

