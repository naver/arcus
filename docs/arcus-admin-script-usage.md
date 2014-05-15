Arcus Admin Script Usage
=========================

`scripts/arcus.sh`는 Arcus cloud를 관리하는 용도로 사용하는 스크립트이며,
사용법은 다음과 같다.

```
Usage: ./arcus.sh -h
       ./arcus.sh [-z <zklist>] deploy <conf_file> | ping <service_code>
       ./arcus.sh [-z <zklist>] zookeeper init
       ./arcus.sh [-z <zklist>] zookeeper start|stop|stat
       ./arcus.sh [-z <zklist>] memcached register <conf_file> | unregister <service_code>
       ./arcus.sh [-z <zklist>] memcached start|stop|list <service_code>
       ./arcus.sh [-z <zklist>] memcached listall
       ./arcus.sh [-z <zklist>] quicksetup <conf_file>
       
  -z, --zklist    zookeeper ensemble ip:port list, The default is "localhost:2181"
                  example) -z 10.0.0.1:2181,10.0.0.2:2181,10.0.0.3:2181
  -h, --help      This small usage guide
  <conf_file>     Arcus cache cloud configuration file, having cache ip:port list and other settings.
                  Refer to scripts/conf/test.json file
  <service_code>  Arcus cache cloud name that identify each cache cloud uniqually.
                  We also call it "service code" as it's a kind of cache cloud service.
```

`scripts/arcus.sh`의 각 명령에서 공통으로 들어가는 인자는 ZooKeeper ensemble list이며 기본값은 "localhost:2181"이다.
각 명령마다 이 인자를 명시적으로 주어도 되며,
인자를 생략하고 싶다면 `scripts/arcus.sh` 파일에 있는 `zklist` 변수의 기본값을 수정하여 사용할 수 있다.


* ./arcus.sh [-z \<zklist\>] **deploy** \<conf_file\>
  - 스크립트가 실행되는 장비의 Arcus 패키지를 ZooKeeper 장비와 Memcached 장비에 설치한다.
    해당 장비에 Arcus 패키지가 이미 존재한다면, 이를 제거한 후 다시 설치한다.
* ./arcus.sh [-z \<zklist\>] **ping** \<service_code\>
  - Arcus의 ZooKeeper 장비와 Memcached 장비에 대해 ping 명령을 수행한다.
  - 참고로, Memcached 관련 정보는 \<service_code\>로 ZooKeeper에서 조회하여 얻는다.
* ./arcus.sh [-z \<zklist\>] **zookeeper init**
  - **init** - 설정 템플릿(conf/zoo.cfg)을 이용하여 ZooKeeper 설정을 생성한 후 각 ZooKeeper 장비에 배포한다. 그리고 Arcus cloud 서비스를 위한 기본 디렉토리를 생성한다.
* ./arcus.sh [-z \<zklist\>] **zookeeper start|stop|stat**
  - **start** - ZooKeeper ensemble의 모든 ZooKeeper process를 구동한다.
  - **stop** - ZooKeeper ensemble의 모든 ZooKeeper process를 중지한다.
  - **stat** - ZooKeeper ensemble의 모든 ZooKeeper process에 대한 상태를 조회한다.
* ./arcus.sh [-z \<zklist\>] **memcached register** \<conf_file\> | **unregister** \<service_code\> 
  - **register** - Arcus cache cloud 정보를 \<conf_file\>에서 읽어 ZooKeeper에 등록한다. ZooKeeper에 \<service_code\>가 이미 존재한다면 새로운 \<conf_file\> 기준으로 업데이트 한다.
  - **unregister** - Arcus cache cloud 정보를 ZooKeeper에서 제거한다. 
* ./arcus.sh [-z \<zklist\>] **memcached start|stop|list** \<service_code\>
  - **start** - Arcus cache cloud의 모든 Memcached process를 구동한다.
  - **stop** - Arcus cache cloud의 모든 Memcached process를 중지한다.
  - **list** - Arcus cache cloud의 모든 Memcached list를 조회한다.
* ./arcus.sh [-z \<zklist\>] **memcached listall**
  - **listall** - 현재 ZooKeeper에 등록된 모든 Arcus cache cloud들의 service code를 조회한다. 
* ./arcus.sh [-z \<zklist\>] **quicksetup** \<conf_file\>
  - deploy, zookeeper init & start, memcached register & start 작업을 한번에 수행한다.

Arcus cache cloud를 동작시키기 위한 `scripts/arcus.sh` 명령의 수행 순서를 도식화하면 다음과 같다.
점선으로 표시한 부분인 `deploy`와 `zookeeper init`은 처음 설치 시에 한번만 수행하면 되는 명령이고,
`memcached register/unregister`는 새로은 cache cloud 사용/제거 시에 한번만 수행하면 되는 명령이다.
(단, `memcached register`를 이미 존재하는 service code에 대해 수행하게 되면
별도의 확인 없이 새로운 설정으로 업데이트 한다)
실선으로 표시한 부분인 `zookeeper start/stop`과 `memcached start/stop`은 
해당 순서에 따라 언제라도 수행할 수 있는 명령이다.

![acrus admin script execution order](https://raw.githubusercontent.com/naver/arcus-cache-cloud/master/docs/images/arcus-admin-script-execution-order.png?token=175927__eyJzY29wZSI6IlJhd0Jsb2I6bmF2ZXIvYXJjdXMtY2FjaGUtY2xvdWQvbWFzdGVyL2RvY3MvaW1hZ2VzL2FyY3VzLWFkbWluLXNjcmlwdC1leGVjdXRpb24tb3JkZXIucG5nIiwiZXhwaXJlcyI6MTQwMDU3NjM3MH0%3D--c0e13252f92543d6b0e54c873272b56237a9f5d3)

