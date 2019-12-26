Arcus Configuration File
========================

Arcus configuration 파일은 Arcus cache cloud의 구성 및 설정 정보를 저장한다.
Arcus admin script 도구를 사용해,
Arcus configuration 파일을 읽어 원하는 형태의 Arcus cache cloud를 생성 및 운영할 수 있다.

Arcus configuration 파일은 scripts/conf 디렉토리에 위치하며,
그 디렉토리에 있는 test.json 파일의 내용을 하나의 예로 보면 아래와 같다.
해당 Arcus cache cloud는 "test-cloud" 라는 service code(or cloud name)로 식별되고,
cache001.arcus, cache002.arcus, cache003.arcus 서버 3대 각각에 대해
11211, 11212 포트를 가지는 2개 cache node로 구성된다.
결국, 6개의 cache node로 구성되는 cloud 설정이다.

```
{
    "serviceCode": "test-cloud"
  , "servers": [
        { "hostname": "cache001.arcus", "ip": "10.0.0.1",
          "config": {
              "port"   : "11211"
          }
        }
      , { "hostname": "cache001.arcus", "ip": "10.0.0.1",
          "config": {
              "port"   : "11212"
          }
        }
      , { "hostname": "cache002.arcus", "ip": "10.0.0.2",
          "config": {
              "port"   : "11211"
            , "threads": "4"
          }
        }
      , { "hostname": "cache002.arcus", "ip": "10.0.0.2",
          "config": {
              "port"   : "11212"
            , "threads": "4"
          }
        }
      , { "hostname": "cache003.arcus", "ip": "10.0.0.3",
          "config": {
              "port"   : "11211"
          }
        }
      , { "hostname": "cache003.arcus", "ip": "10.0.0.3",
          "config": {
              "port"   : "11212"
          }
        }
    ]
  , "config": {
        "threads"    : "6"
      , "memlimit"   : "100"
      , "connections": "1000"
    }
}
```

Arcus configuration 파일에서 설정하는 내용의 상세 설명은 아래와 같다.

* serviceCode - Arcus service code (or cloud name)
  - Arcus cache cloud들을 관리하는 Zookeeper ensemble에서 각각의 Arcus cache cloud를 유일하게 구분한다.
* servers - Arcus cache node list
  - Arcus cache cloud에 참여하는 각 cache node의 hostname, ip 그리고, port number를 가진다.
  - 각 cache node의 port number를 포함하여 specific configuration을 명시할 수 있다.
* config - General cache node configuration
  - 모든 cache node에 공통으로 적용할 general configuration 정보이다.
  - 각 cache node에 specific configuration 정보가 있다면, specific configuration가 적용된다.

Cache node configuration 항목의 설명은 아래와 같다.

* port : 각 cache node의 port number
* threads : 각 cache node에 생성할 worker thread들의 수
* memlimit : 각 cache node가 사용할 메모리의 용량 (단위: MB)
* connections: 각 cache node가 받아들일 수 있는 최대 연결 수
