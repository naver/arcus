How To Install Dependencies
===========================

- Install JDK & Ant (java >= 1.8)

  ```
  # Make a directory
  mkdir ~/vendor
  pushd ~/vendor

  # Install openjdk (Zookeeper 3.5.x required : 1.8u211 or higher version)
  - CentOS
    // check the installable version
    yum list java*jdk-devel
    // install the required version
    sudo yum install java-1.8.0-openjdk-devel-<version>
  - Ubuntu
    sudo apt-get install openjdk-8-jdk

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

- Install tools for packaging and building (python version 2 that is 2.6 or higher)

  ```
  (CentOS) sudo yum install gcc gcc-c++ make autoconf automake libtool pkgconfig cppunit-devel python-setuptools python-devel perl-Test-Harness perl-Test-Simple
  (Ubuntu) sudo apt-get install build-essential autoconf automake libtool libcppunit-dev python-setuptools python-dev
  ```

  - On CentOS8 system, you need to register the PowerTools repository to install cppunit-devel
  ```
  sudo yum install dnf-plugins-core
  sudo yum config-manager --set-enabled PowerTools
  sudo yum install cppunit-devel
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
