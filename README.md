Arcus Cache Cloud
=================

Arcus is a [memcached][memcached]-based cache cloud developed by [NAVER Corp][naver].
[arcus-memcached](https://github.com/naver/arcus-memcached) has been heavily modified
to support functional and performance requirements of NAVER services.
Arcus supports collection data structures (List, Set, B+tree)
for storing/retreiving multiple values as a structrued form
in addition to the basic Key-Value data model of memcached.

Arcus manages multiple clusters of memcached nodes using [ZooKeeper][zookeeper].
Each cluster or cloud is identified by its service code.  Think of the service code as the cloud's name.
The user may add/remove memcached nodes/clouds on the fly.  And, Arcus detects failed nodes and automatically removes them.

The overall architecture is shown below. 
The memcached node is identified by its name (IP address:port number).
ZooKeeper maintains a database of memcached node names and the service code (cloud) that they belong to.
ZooKeeper also maintains a list of alive nodes in each cloud (cache list).

Upon startup, each memcached node contacts ZooKeeper and finds the service code that it belongs to.
Then the node inserts its name on the cache list so Arcus client can see it.
ZooKeeper periodically checks if the cache node is alive, remove failed nodes from the cache cloud, and notifies the updated cache list to cache clients.
With the latest cache list,
Arcus clients do [consistent hashing][consistent hashing] to find the cache node 
for each key-value operation.
Hubble collects and shows the statistics of the cache cloud.

![Arcus Architecture](https://raw.githubusercontent.com/naver/arcus/master/docs/images/arcus-architecture.png)

[naver]: http://www.naver.com "Naver"
[zookeeper]: http://zookeeper.apache.org "ZooKeeper"
[memcached]: http://www.memcached.org "Memcached"
[consistent hashing]: http://en.wikipedia.org/wiki/Consistent_hashing "Consistent Hashing"

## Supported OS Platform

Currently, Arcus only supports 64-bit Linux.
It has been tested on the following OS platfroms.

* CentOS 6.x 64bit
* Ubuntu 12.04 LTS 64bit

If you are interested in supporting other OS platforms, please try building/running Arcus on them.
And let us know of any issues.

## Quick Start

Arcus setup usually follows three steps below.

> 1. Preparation - clone and build this Arcus code, and deploy Arucs code/binary package.
> 2. Zookeeper setup - initialize Zookeeper ensemble for Arcus and start Zookeeper processes.
> 3. Memcached setup - register cache cloud information into Zookeeper and start cache nodes.

To quickly set up and test an Arcus cloud on the local machine, run the commands below.
They build memcached, set up a cloud of two memcached nodes in ZooKeeper, and start them, all on the local machine.
The commands assume RedHat/CentOS environment.

```
# Requirements: JDK & Ant

# Install dependencies
sudo yum install gcc gcc-c++ autoconf automake libtool pkgconfig cppunit-devel python-setuptools python-devel (CentOS)
sudo apt-get install build-essential autoconf automake libtool libcppunit-dev python-setuptools python-dev (Ubuntu)


# Clone & Build
git clone https://github.com/naver/arcus.git
cd arcus/scripts
./build.sh

# Setup a local cache cloud with conf file. (Should be non-root user)
./arcus.sh quicksetup conf/local.sample.json

# Test
echo "stats" | nc localhost 11211 | grep version
STAT version 1.7.0
echo "stats" | nc localhost 11212 | grep version
STAT version 1.7.0
```

To set up Arcus cache clouds on multiple machines, you need following two things.

* [Arcus cloud configuration file](docs/arcus-cloud-configuration-file.md): Arcus cache cloud settings in JSON format
* [Arcus cloud admin script (arcus.sh)](docs/arcus-admin-script-usage.md): A tool to control Arcus cache cloud.

Please see [Arcus cache cloud setup in multiple servers](docs/arcus-cloud-in-multiple-servers.md) for more details.

Once you finish setting up an Arcus cache cloud on multiple machines, you can quickly test Arcus on the command line,
using telnet and ASCII commands.
See [Arcus telnet interface](https://github.com/naver/arcus-memcached/blob/master/doc/arcus-telnet-interface.md).
Details on Arcus ASCII commands are in [Arcus ASCII protocol document](https://github.com/naver/arcus-memcached/blob/master/doc/arcus-ascii-protocol.md).

To develop Arcus application programs, please take a look at Arcus clients.
Arcus currently supports Java and C/C++ clients.  Each module includes a short tutorial
where you can build and test "hello world" programs.
- [Arcus Java client](https://github.com/naver/arcus-java-client)
- [Arcus C/C++ client](https://github.com/naver/arcus-c-client)


## Documents

- [How To Install Dependencies](docs/howto-install-dependencies.md) for beginners
- [Arcus Directory Structure](docs/arcus-directory-structure.md) after building
- [Arcus Cloud Configuration File](docs/arcus-cloud-configuration-file.md)
- [Arcus Admin Script Usage](docs/arcus-admin-script-usage.md)
- [Arcus Cache Cloud Setup in Multiple Servers](docs/arcus-cloud-in-multiple-servers.md) 

