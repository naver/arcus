#!/bin/bash
############################################
# Arcus deployer
#
# - Generated directory structure
#
# /arcus-<OS>-<ARCH>-<VERSION>
#     /sbin      : scripts
#     /server    : Arcus-memcached
#     /clients
#         /c     : Arcus-c-client
#         /java  : Arcus-java-client
#     /zookeeper : Arcus-zookeeper
#     /deps      : dependencies for Arcus
#
############################################

## Arcus Repositories
REPO_MEMCACHED="https://github.com/naver/arcus-memcached"
REPO_JAVA_CLIENT="https://github.com/naver/arcus-java-client"
REPO_C_CLIENT="https://github.com/naver/arcus-c-client"
REPO_ZOOKEEPER="https://github.com/naver/arcus-zookeeper"

## Dependency Repositories
DEP_LIBEVENT="https://github.com/downloads/libevent/libevent/libevent-1.4.12-stable.tar.gz"
DEP_ZOOKEEPER="https://archive.apache.org/dist/zookeeper/zookeeper-3.4.5/zookeeper-3.4.5.tar.gz"

## @param $1 version string
get_version() {
  if [ -z $1 ]; then
    exit 1
  fi

  echo $1
}

## Get architecture type of the current system.
## We only support x86_64 only now.
##
## @return The architecture type
get_archtype() {
  local arch=$(uname -m)

  if [ "$arch" != "x86_64" ]; then
    exit 1
  fi

  echo $arch
}

## Find running version of the current Linux system.
## We only support CentOS 6 and Ubuntu 12.04LTS now.
##
## @return The name of Linux distribution
get_ostype() {
  local ostype="Unknown"

  # Only supports CentOS6 or Ubuntu
  if [ -f /etc/redhat-release ]; then
    # e.g. CentOS release 6.3 (Final)
    local check=$(grep "CentOS release 6." /etc/redhat-release)
    if [ -z "$check" ]; then
      exit 1
    fi
    ostype="CentOS6"
  elif [ -f /etc/issue.net ]; then
    # e.g. Ubuntu 12.04.4 LTS
    local check=$(grep "Ubuntu 12.04" /etc/issue.net)
    if [ -z "$check" ]; then
      exit 1
    fi
    ostype="Ubuntu12.04"
  fi

  echo $ostype
}

## Make package name.
##
## @param $1 ostype
## @param $2 archtype
## @param $3 version
## @return package name
get_package_name() {
  local ostype=$1
  local archtype=$2
  local version=$3
  echo "arcus-$1-$2-$3"
}

## Clone the given git repository into the specified directory.
##
## @param $1 repository
## @param $2 directory
## @param $3 username (optional)
git_clone() {
  local repo=$1
  local dir=$2
  local username=$3

  if [ -z "$repo" ] || [ -z "$dir" ]; then
    exit 1
  fi

  if [ ! -z "$username" ]; then
    local replacement="//$username@"
    repo=${repo/\/\//$replacement}
  fi
  
  git clone "$repo" "$dir"
}

## Makes directories.
## 
## /arcus-<OS>-<ARCH>-<VERSION>
##     /sbin      : scripts
##     /server    : Arcus-memcached
##     /clients
##         /c     : Arcus-c-client
##         /java  : Arcus-java-client
##     /zookeeper : Arcus-zookeeper
##     /deps      : dependencies for Arcus
##
## @param $1 package name
make_package_directories_and_get_dependencies() {
  local package_name=$1
  if [ -z "$package_name" ]; then
    exit 1
  fi

  mkdir -p "$package_name/sbin"
  mkdir -p "$package_name/clients"
  mkdir -p "$package_name/zookeeper"
  mkdir -p "$package_name/deps/libevent"

  # use git credential helper to avoid typing password continuously.
  git config --global credential.helper cache

  git_clone "$REPO_MEMCACHED" "$package_name/server" "$GIT_USER"
  git_clone "$REPO_JAVA_CLIENT" "$package_name/clients/java" "$GIT_USER"
  git_clone "$REPO_C_CLIENT" "$package_name/clients/c" "$GIT_USER"
  git_clone "$REPO_ZOOKEEPER" "$package_name/deps/arcus-zookeeper" "$GIT_USER"

  # get libevent
  curl -o "$package_name/deps/libevent.tar.gz" -L $DEP_LIBEVENT
  tar xvf "$package_name/deps/libevent.tar.gz" -C "$package_name/deps/libevent" --strip-components 1
  if [ $? -ne 0 ]; then
    echo "Failed to download libevent"
    exit 1
  fi
  rm "$package_name/deps/libevent.tar.gz"

  # get zookeeper
  curl -o "$package_name/deps/zookeeper.tar.gz" -L $DEP_ZOOKEEPER
  tar xvf "$package_name/deps/zookeeper.tar.gz" -C "$package_name/zookeeper" --strip-components 1
  if [ $? -ne 0 ]; then
    echo "Failed to download zookeeper"
    exit 1
  fi
  cp "$package_name/zookeeper/conf/zoo_sample.cfg" "$package_name/zookeeper/conf/zoo.cfg"
  rm "$package_name/deps/zookeeper.tar.gz"

  # copy scripts
  cp arcus.sh $package_name/sbin
  cp build.sh $package_name/sbin
  cp setup-single.sh $package_name/sbin
  cp -R admin $package_name
}

## Makes packages buildable.
##
## @param $1 package_name
make_buildable_packages() {
  local package_name=$1
  if [ -z "$package_name" ]; then
    exit 1
  fi

  # server
  pushd $package_name/server
  config/autorun.sh
  popd

  # c client
  pushd $package_name/clients/c
  config/autorun.sh
  popd
  
  # libevent (uncomment below if you get libevent from the source repository)
  #pushd $package_name/deps/libevent
  #./autogen.sh
  #popd
  
  # libzookeeper
  pushd $package_name/deps/arcus-zookeeper
  ant compile_jute
  popd
  pushd $package_name/deps/arcus-zookeeper/src/c
  autoreconf -if
  popd
}

main() {
  local version=$(get_version $1)
  if [ $? -eq 1 ]; then
    echo "usage: ./package.sh <version> <git_user:optional>"
    exit 1
  fi

  local archtype=$(get_archtype)
  if [ $? -eq 1 ]; then
    echo "Only supports x86_64 architecture"
    exit 1
  fi

  local ostype=$(get_ostype)
  if [ $? -eq 1 ]; then
    echo "Only supports CentOS 6.x or Ubuntu 12.04 LTS"
    exit 1
  fi

  local package_name=$(get_package_name "$ostype" "$archtype" "$version")
  make_package_directories_and_get_dependencies $package_name
  make_buildable_packages $package_name
}

## MAIN

VERSION=$1
GIT_USER=$2

if [ -z "$VERSION" ]; then
  echo "usage: ./package.sh <version> <git_user:optional>"
  exit 1
fi

main $VERSION

