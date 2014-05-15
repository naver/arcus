#!/bin/bash
############################################
# Arcus builder
############################################

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
    echo "invalid module dir : $source_dir/$module_dir"
    exit 1
  fi

  pushd $source_dir/$module_dir #> /dev/null

  echo "configure options : $configure_options"
  ./configure --prefix="$target_dir" $configure_options
  make clean
  make
  make install

  popd > /dev/null
}

## Bulid all components
## 
## @param $1 source directory
## @param $2 target directory
build_all() {
  local source_dir=$1
  local target_dir=$2

  if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
    echo "invalid target dir : $target_dir"
    exit 1
  fi

  if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
    echo "invalid source dir : $source_dir"
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
  easy_install -a -d $pythonpath kazoo
  easy_install -a -d $pythonpath jinja2
  # FIXME pycrypto-2.6 is really really slow.. So let's downgrade it.
  ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future easy_install -a -d $pythonpath pycrypto==2.4.1
  easy_install -a -d $pythonpath fabric==1.8.3
  pushd $target_dir/scripts
  ln -s ../lib/python/site-packages/fab fab
  popd
}

## MAIN ##

SOURCE_DIR=$(get_working_directory $0)
if [ ! -z "$1" ]; then
  TARGET_DIR=$(readlink -f $1)
fi

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR=$SOURCE_DIR
else
  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p $TARGET_DIR
    echo "created a working directory $TARGET_DIR."
  fi
fi

echo "working directory is $TARGET_DIR."

/bin/bash $SOURCE_DIR/scripts/etc/autorun.sh
build_all $SOURCE_DIR $TARGET_DIR
