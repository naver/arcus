How To Install Dependencies
===========================

- Install JDK & Ant (java >= 1.8)

  ```
  # Make a directory
  mkdir ~/vendor
  pushd ~/vendor

  # Install openjdk
  sudo yum install java-1.8.0-openjdk-devel.x86_64 (CentOS)
  sudo apt-get install openjdk-8-jdk (Ubuntu)

  # Install Apache-Ant
  curl -OL http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.3-bin.tar.gz
  tar xvf apache-ant-1.9.3-bin.tar.gz
  ln -s apache-ant-1.9.3 ant

  # Set the paths
  # $HOME/.bashrc or $HOME/.bash_profile
  export JAVA_HOME=<your Java installation path>
  export ANT_HOME=$HOME/vendor/ant
  export PATH=$JAVA_HOME/bin:$ANT_HOME/bin:$PATH

  source ~/.bashrc (or ~/.bash_profile)
  popd 
  ```

- Install tools for packaging and building (python >= 2.6)

  ```
  (CentOS) sudo yum install gcc gcc-c++ autoconf automake libtool pkgconfig cppunit-devel python-setuptools python-devel openssl-devel
  (Ubuntu) sudo apt-get install build-essential autoconf automake libtool libcppunit-dev python-setuptools python-dev libssl-dev
  ```

- For OSX users

  ```
  # install homebrew
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

  # install python easy_install
  python -c "$(curl -O http://python-distribute.org/distribute_setup.py)"

  # install build tools
  brew install autoconf automake libtool pkg-config cppunit
  ```
