## cppunit.m4 missing
cppunit.m4 가 없는 경우 Zookeeper build 지점에서 아래 에러가 발생하게 된다.  
autoreconf 명령이 configure.ac을 실행하고, 이 파일은 cppunit.m4을 포함해서 여러 m4 매크로를 필요로 한다.

```
[zookeeper/zookeeper-client/zookeeper-client-c/autoreconf -if] .. FAILED
acinclude.m4:315: warning: macro 'AM_PATH_CPPUNIT' not found in library
configure.ac:37: error: Missing AM_PATH_CPPUNIT or PKG_CHECK_MODULES m4 macro.
acinclude.m4:317: CHECK_CPPUNIT is expanded from...
configure.ac:37: the top level
...
```

cppunit version 1.14 이상부터 cppunit.m4가 제거되었다.  
일부 상위 OS 버전(Ubuntu 18.04, CentOS 8 이상)에서 설치되는 cppunit version이 1.14 이상이므로 cppunit 1.13 이하를 다운받아 사용하면 해결된다.
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

- cppunit.m4 가 있어도 문제가 발생하는 경우

/usr/share/aclocal/ 경로에 cppunit.m4 가 존재하여도 cppunit.m4 missing 문제가 발생하면 ACLOCAL_PATH를 지정하여 컴파일한다.
```
cd zookeeper-client/zookeeper-client-c
ACLOCAL_PATH="/usr/share/aclocal" autoreconf -if
```

위 방법으로도 안된다면, 프로그램이 시스템 경로를 찾지 못하므로 사용자 경로에 복사하여 지정해준다.
```
cd zookeeper-client/zookeeper-client-c
mkdir m4
cp /usr/share/aclocal/* m4/
ACLOCAL_PATH="m4" autoreconf -if
```



