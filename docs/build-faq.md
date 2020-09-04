## cppunit.m4 missing
cppunit.m4 가 없는 경우 Zookeeper build 지점에서 아래 에러가 발생하게 된다.  
autoreconf 명령이 configure.ac을 실행하고, 이 파일은 cppunit.m4을 포함해서 여러 m4 매크로를 필요로 한다.

```
[zookeeper/src/c/autoreconf -if] .. FAILED
configure.ac:37: warning: macro `AM_PATH_CPPUNIT' not found in library
configure.ac:37: warning: macro `AM_PATH_CPPUNIT' not found in library
configure.ac:37: error: possibly undefined macro: AM_PATH_CPPUNIT
If this token and others are legitimate, please use m4_pattern_allow.
See the Autoconf documentation.
```

cppunit version 1.14 이상부터 cppunit.m4가 제거되었다.  
OS 버전에 따라 설치되는 cppunit version이 1.14 이상인 경우(Ubuntu 18.04, CentOS 8 이상), cppunit 1.13.2 를 다운받아 해결하도록 한다.
- cppunit 1.13.2 download & build (https://www.freedesktop.org/wiki/Software/cppunit/)

```
wget http://dev-www.libreoffice.org/src/cppunit-1.13.2.tar.gz
tar -xvzf cppunit-1.13.2.tar.gz
cd cppunit-1.13.2
./configure
make
make install
cp cppunit.m4 /usr/share/aclocal/
```
