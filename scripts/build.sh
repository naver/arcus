#!/bin/bash
############################################
# Arcus builder
############################################

## arcus directory
pushd $(dirname $0)/.. > /dev/null
arcus_directory=$(pwd)
popd > /dev/null

## Set trap for catching error
trap "stop_build" ERR

## Stop build when error is occurred
stop_build() {
    echo "Error has occurred. $0 has failed."
    echo "Check $arcus_directory/scripts/build.log"
    exit -1
}

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

## Common build script
##
## @param $1 source directory
## @param $2 target directory
## @param $3 module
## @param $4 configure options
build_and_install() {
  local source_dir=$1
  local target_dir=$2
  local module_dir=$3
  local configure_options=$4

  if [ -z "$source_dir/$module_dir" ] || [ ! -d "$source_dir/$module_dir" ]; then
    echo "invalid module dir : $source_dir/$module_dir" | tee -a $arcus_directory/scripts/build.log
    exit 1
  fi

  pushd $source_dir/$module_dir >> $arcus_directory/scripts/build.log

  echo "configure options : $configure_options" >> $arcus_directory/scripts/build.log
  ./configure --prefix="$target_dir" $configure_options 1>> $arcus_directory/scripts/build.log 2>&1
  printf "[$module_dir make clean] .. START"
  make clean 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r[$module_dir make clean] .. SUCCEED\n"
  printf "[$module_dir make] .. START"
  make 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r[$module_dir make] .. SUCCEED\n"
  printf "[$module_dir make install] .. START"
  make install 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r[$module_dir make install] .. SUCCEED\n"

  popd >> $arcus_directory/scripts/build.log
}

## Bulid all components
##
## @param $1 source directory
## @param $2 target directory
build_all() {
  local source_dir=$1
  local target_dir=$2

  if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
    echo "invalid target dir : $target_dir" | tee -a $arcus_directory/scripts/build.log
    exit 1
  fi

  if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
    echo "invalid source dir : $source_dir" | tee -a $arcus_directory/scripts/build.log
    exit 1
  fi

  build_and_install "$source_dir" "$target_dir" "deps/libevent" ""
  build_and_install "$source_dir" "$target_dir" "zookeeper/src/c" ""
  build_and_install "$source_dir" "$target_dir" "server" "--enable-zk-integration --with-libevent=$target_dir --with-zookeeper=$target_dir"

  if [ "$source_dir" != "$target_dir" ]; then
    # copy others
    cp "$source_dir/README.md" "$target_dir"
    cp "$source_dir/AUTHORS" "$target_dir"
    cp "$source_dir/LICENSE" "$target_dir"
    cp -R "$source_dir/docs" "$target_dir"
    cp -R "$source_dir/zookeeper" "$target_dir"
    cp -R "$source_dir/scripts" "$target_dir"
    rm "$target_dir/scripts/build.sh"
  fi

  # install python-kazoo, python-fabric
  local pythonmajorversion=$(python -c 'import sys; print(sys.version_info[0])')
  local pythonpath=$target_dir/lib/python/site-packages
  local pythonsimpleindex=https://pypi.python.org/simple
  mkdir -p $pythonpath
  export PYTHONPATH=$pythonpath:$PYTHONPATH
  printf "[python kazoo library install] .. START"
  easy_install -a -d $pythonpath -i $pythonsimpleindex kazoo==2.6.1 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r[python kazoo library install] .. SUCCEED\n"
  printf "[python markupsafe library install] .. START"
  easy_install -a -d $pythonpath -i $pythonsimpleindex markupsafe==1.1.1 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r[python markupsafe library install] .. SUCCEED\n"
  printf "[python jinja2 library install] .. START"
  easy_install -a -d $pythonpath -i $pythonsimpleindex jinja2==2.10 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r[python jinja2 library install] .. SUCCEED\n"
  printf "[python fabric library install] .. START"
  if [ "$pythonmajorversion" == "3" ]; then
    ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future easy_install -a -d $pythonpath -i $pythonsimpleindex pycryptodome==3.9.7 1>> $arcus_directory/scripts/build.log 2>&1
    easy_install -a -d $pythonpath -i $pythonsimpleindex fabric==2.5.0 1>> $arcus_directory/scripts/build.log 2>&1
  else
    # FIXME pycrypto-2.6 is really really slow.. So let's downgrade it.
    ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future easy_install -a -d $pythonpath -i $pythonsimpleindex pycrypto==2.4.1 1>> $arcus_directory/scripts/build.log 2>&1
    easy_install -a -d $pythonpath -i $pythonsimpleindex fabric==1.8.3 1>> $arcus_directory/scripts/build.log 2>&1
  fi
  printf "\r[python fabric library install] .. SUCCEED\n"
  pushd $target_dir/scripts >> $arcus_directory/scripts/build.log
  if [ ! -f fab ]; then
    ln -s ../lib/python/site-packages/fab fab 1>> $arcus_directory/scripts/build.log 2>&1
  fi
  popd >> $arcus_directory/scripts/build.log
}

## MAIN ##

if [ -f "$arcus_directory/scripts/build.log" ]; then
  rm $arcus_directory/scripts/build.log
fi

SOURCE_DIR=$(get_working_directory $0)
if [ ! -z "$1" ]; then
  TARGET_DIR=$(readlink -f $1)
fi

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR=$SOURCE_DIR
else
  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p $TARGET_DIR
    echo "created a working directory $TARGET_DIR." >> $arcus_directory/scripts/build.log
  fi
fi

echo "ARCUS BUILD PROCESS: START"
echo "--------------------------"
echo "Working directory is $TARGET_DIR." | tee -a $arcus_directory/scripts/build.log
echo "Detailed build log is recorded to scripts/build.log."
echo "--------------------------"

/bin/bash $SOURCE_DIR/scripts/etc/autorun.sh
build_all $SOURCE_DIR $TARGET_DIR

echo "--------------------------"
echo "ARCUS BUILD PROCESS: END"
