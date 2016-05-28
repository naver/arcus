#!/bin/bash
############################################
# Arcus builder
############################################

## arcus directory
pushd `dirname $0`/.. > /dev/null
arcus_directory=`pwd`
popd > /dev/null

## Set trap for catching error
trap "stop_build" ERR

## Stop build when error is occured
stop_build() {
    echo "Error has occured. $0 has failed."
    echo "Check $arcus_directory/scripts/build.log"
    exit -1
}

## Get working directory based on the location of this script.
##
## @param $1 location of this script ($0)
## @return working directory
get_working_directory() {
  pushd `dirname $0`/.. > /dev/null
  local curr_dir=`pwd`
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
    echo "invalid module dir : $source_dir/$module_dir" >> $arcus_directory/scripts/build.log
    echo "invalid module dir : $source_dir/$module_dir" 
    exit 1
  fi

  pushd $source_dir/$module_dir >> $arcus_directory/scripts/build.log

  echo "configure options : $configure_options" >> $arcus_directory/scripts/build.log
  ./configure --prefix="$target_dir" $configure_options 1>> $arcus_directory/scripts/build.log 2>&1
  printf "$module_dir make clean start"
  make clean 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r$module_dir make clean succeed\n"
  printf "$module_dir make start"
  make 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r$module_dir make succeed\n"
  printf "$module_dir make install start"
  make install 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\r$module_dir make install succeed\n"

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
    echo "invalid target dir : $target_dir" >> $arcus_directory/scripts/build.log
    echo "invalid target dir : $target_dir"
    exit 1
  fi

  if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
    echo "invalid source dir : $source_dir" >> $arcus_directory/scripts/build.log
    echo "invalid target dir : $target_dir"
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
  local pythonpath=$target_dir/lib/python/site-packages
  mkdir -p $pythonpath
  export PYTHONPATH=$pythonpath:$PYTHONPATH
  printf "python kazoo library install start"
  easy_install -a -d $pythonpath kazoo 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\rpython kazoo library install succeed\n"
  printf "python jinja2 library install start"
  easy_install -a -d $pythonpath jinja2 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\rpython jinja2 library install succeed\n"
  # FIXME pycrypto-2.6 is really really slow.. So let's downgrade it.
  ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future easy_install -a -d $pythonpath pycrypto==2.4.1 1>> $arcus_directory/scripts/build.log 2>&1
  printf "python fabric library install start"
  easy_install -a -d $pythonpath fabric==1.8.3 1>> $arcus_directory/scripts/build.log 2>&1
  printf "\rpython fabric library install succeed\n"
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

echo "working directory is $TARGET_DIR." >> $arcus_directory/scripts/build.log

/bin/bash $SOURCE_DIR/scripts/etc/autorun.sh
build_all $SOURCE_DIR $TARGET_DIR/asdf
