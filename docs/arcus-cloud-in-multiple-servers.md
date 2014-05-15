Arcus Cache Cloud Setup in Multiple Servers
===========================================

아커스는 한 대의 서버에 설치하여 서비스할 수 있지만
실제 운영 환경에서는 여러 대의 서버에 아커스를 분산 배치하여
보다 많은 요청을 받으면서도 장애에도 대비할 수 있도록 구성해야 한다.

이 문서에서는 Arcus 관리 스크립트인 `scripts/arcus.sh`를 이용하여
여러 대의 서버에 Arcus cache cloud를 생성하여 관리하는 방법을 가이드한다.
이 작업을 진행하기 전에,
README의 [Quick Start][readme-quick-start] 단계를 먼저 진행해 보고
아래의 Arcus cloud 관리에 필요한 기본 사항을 먼저 읽어보길 권한다.

* [Arucs cloud configuraiton file](arcus-cloud-configuration-file.md)
* [Arcus cloud amdin script usage](arcus-admin-script-usage.md)

본 가이드는 아래와 같이 cache001.arcus, cache002.arcus, cache003.arcus의 3대 서버를 사용하여
"test-cloud'란 service code(or cloud name)을 가진 Arcus cache cloud를 구성한다.
3대 서버 모두에 ZooKeeper를 설치 및 구동하여 이들을 하나의 ZooKeeper ensemble로 구성하고,
3대 서버 각각에 2개씩의 cache node를 구동하여 이들이 하나의 cache cloud를 형성하도록 한다.

```
service code: test-cloud
+--------------------+   +--------------------+   +--------------------+
| cache001.arcus     |   | cache002.arcus     |   | cache003.arcus     |
| IP: 10.0.0.1       |   | IP: 10.0.0.2       |   | IP: 10.0.0.3       |
+--------------------+   +--------------------+   +--------------------+
|                    |   |                    |   |                    |
| ZooKeeper1:2181    |   | ZooKeeper2:2181    |   | ZooKeeper3:2181    |
|                    |   |                    |   |                    |
| Memcached1-1:11211 |   | Memcached2-1:11211 |   | Memcached3-1:11211 |
| Memcached1-2:11212 |   | Memcached2-2:11212 |   | Memcached3-2:11212 |
|                    |   |                    |   |                    |
+--------------------+   +--------------------+   +--------------------+
```

README의 [Quick Start][readme-quick-start]에서 처럼 `quicksetup` 방식을 사용할 수 있지만,
본 가이드에서는 Arcus admin script의 개별 명령을 이용하는 방식으로 소개한다.
Arcus cache cloud를 구성하는 작업은 아래 기술된 순서대로 진행하면 된다.

### Clone & Build

먼저 Arcus 코드를 클론한 뒤 빌드한다.

```
sudo yum install gcc gcc-c++ autoconf automake libtool pkgconfig cppunit-devel python-setuptools

git clone https://github.com/naver/arcus.git

cd arcus/scripts
./build.sh
```

### Arcus Cloud Configuration

scripts/conf 디렉토리에 Arcus cloud 설정 정보를 가지는
[Arcus cloud configuration file](arcus-cloud-configuration-file.md)을 생성한다.
여기서는 `test.json` 파일을 생성하였다고 가정한다.
참고로, `test.json` 파일의 현재 내용은 본 가이드에서 생성할 cloud 설정을 그대로 가지고 있다.

```
# 샘플 설정인 conf/test.json을 복사하여 자신의 환경에 맞도록 수정해야 한다.
cp conf/test.json conf/<conf_file>
vi conf/<conf_file>
```

ZooKeeper 서버들의 ip 정보는 `arcus.sh`를 수행할 때마다 매번 인자(`-z 10.0.0.1:2181,10.0.0.2:2181,10.0.0.3:2181`)로 지정해 주어야 한다.
이를 생략하고 싶다면, `arcus.sh` 파일의 가장 상단에 있는 zklist 변수의 값으로
ZooKeeper ensemble list를 지정해 주면 된다.
아래에서는 `arcus.sh`에 리스트가 이미 지정된 상태라고 가정하고
스크립트 수행 시 `-z zklist` 옵션을 지정하지 않을 것이다.

### Deploy & ZooKeeper Init

`arcus.sh`의 `deploy` 명령으로 ZooKeeper 그리고/또는 Memcached가 구동될 모든 서버로
앞서 빌드한 Arcus 패키지를 설치하고,
`zookeeper init` 명령으로 Arcus에서 사용하는 ZooKeeper ensemble 설정을 완료한다.

```
./arcus.sh deploy conf/test.json
./arcus.sh zookeeper init
```

이 작업은 원격지(remote) 서버에 접근하여 수행할 작업으로 SSH 연결을 필요로 한다.
이 경우, 패스워드를 직접 입력하거나 SSH public key 인증 방식을 사용할 수 있다.
SSH public key 인증 방식을 사용하려면, 패스워드 없는 SSH public key를 생성하여
접근할 각 원격지 서버에 배포해 두어야 한다.
자세한 사항은 [SSH public key 배포](deploy-ssh-public-key.md)를 참고하기 바란다.

### ZooKeeper Start, Memcached Register, Memcached Start

모든 서버에 있는 Zookeeper 프로세스들을 구동하고,
Arcus cache cloud 설정파일을 이용해 ZooKeeper에 해당 Arcus cloud 정보를 등록한다.
그리고 나서, 모든 서버에서 test-cloud의 memcached들을 구동한다.

```
./arcus.sh zookeeper start
./arcus.sh zookeeper stat # ZooKeeper leader가 결정 되었는지 확인.

./arcus.sh memcached register conf/test.json
./arcus.sh memcached start test-cloud
```

위의 명령을 모두 수행하면, 
README의 [Quick Start][readme-quick-start]에서 소개한 `quicksetup` 명령을 수행한 상태와
동일하게 Arcus cache cloud가 구동된 상태가 된다.

작업이 완료되면 `listall`, `list` 명령을 이용하여 캐시 서버가 잘 구동되었는지 확인할 수 있다.

```
./arcus.sh memcached listall
./arcus.sh memcached list test-cloud
```

### Memcached Stop, Memcached Unregister, ZooKeeper Stop

Arcus cache cloud 사용을 중지하고 싶다면, 아래 명령을 조합하여 사용할 수 있다.
예를 들어, "test-cloud"의 Arcus cache node들만 중지하고 싶다면, `memcached stop` 명령을 수행하면  된다.
"test-cloud"의 Arcus cache node들과 zookeeper들도 모두 중지하고 싶다면,
`memcached stop`과 `zookeeper stop` 명령을 차례로 수행하여야 한다.
Zookeeper에 이미 등록된 Arcus cache cloud를 다시 구동하고 싶다면,
`zookeeper start`와 `memcached start` 명령을 차례로 수행하면 된다.
"test-cloud"의 Arcus cache cloud를 더 이상 사용하지 않을 계획이라면,
`memcached unregiser` 명령으로 ZooKeeper에서 해당 cache cloud 정보를 제거하면 된다.
이 명령은 ZooKeeper가 구동된 상태에서 수행해야 한다.

```
# stop all memcached processes
./arcus.sh memcached stop test-cloud

# unregister cache cloud from ZooKeeper
./arcus.sh memcached unregister test-cloud

# stop all ZooKeeepr processes
./arcus.sh zookeeper stop
```

<!-- Reference Links -->

[readme-quick-start]: ../README.md#quick-start
