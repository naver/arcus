Arcus Directory Structure
=========================

아커스를 빌드하여 설치하면 아래와 같은 디렉토리가 생성된다.
(빌드 옵션에 따라 소스코드 및 일부 스크립트는 없을 수도 있음)

```
arcus
|-- bin
|   `-- memcached  : arcus-memcached 실행파일
|-- server         : arcus-memcached 소스코드
|-- clients
|   |-- c          : arcus-c-client 소스 디렉토리
|   `-- java       : arcus-java-client 소스 디렉토리
|-- deps           : 아커스가 사용하는 외부 라이브러리 모음
|-- docs           : 문서
|-- include
|-- lib
|-- scripts
|   |-- arcus.sh   : 관리 스크립트
|   |-- build.sh   : 빌드 스크립트
|   |-- conf       : 각종 설정 파일
|   |-- etc        : 기타 쉘스크립트
|   |-- fab        : fabric 실행파일(심볼릭링크)
|   |-- fabfile.py : 아커스 설치 및 관리를 위한 fabfile
|   `-- lib        : fabfile에서 사용하는 추가 라이브러리
|-- share
`-- zookeeper      : zookeeper 서버 바이너리 및 소스코드
```

