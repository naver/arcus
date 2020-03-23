How To Install Dependencies
===========================

- Install JDK & Ant

  ```
  # Make a directory
  mkdir ~/vendor
  pushd ~/vendor

  # Install openjdk
  sudo yum install java-1.7.0-openjdk-devel (CentOS)
  sudo apt-get install openjdk-7-jdk (Ubuntu)

  # Or download it directly from Oracle
  http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html

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

- Install tools for packaging and building

  ```
  (CentOS) sudo yum install gcc gcc-c++ autoconf automake libtool pkgconfig cppunit-devel python-setuptools python-devel
  (Ubuntu) sudo apt-get install build-essential autoconf automake libtool libcppunit-dev python-setuptools python-dev
  ```

- Install test perl module for make test

  ```
  # Make test requires a perl module "Test::More"
  # Check if the module has been installed
  perl -e "use Test::More"

  # If you get error, install "Test::More" using CPAN
  # Install CPAN
  (CentOS) sudo yum install cpan
  (Ubuntu) sudo apt-get install libpath-tiny-perl

  # Install Test::More
  cpan Test::More
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
