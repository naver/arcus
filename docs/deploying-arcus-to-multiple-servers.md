Deploying Arcus To Multiple Servers
===================================

아커스는 한 대의 서버에 설치하여 서비스할 수 있지만
실제 운영 환경에서는 여러 대의 서버에 아커스를 분산 배치하여
보다 많은 요청을 받으면서도 장애에도 대비할 수 있도록 구성해야 합니다.

이 문서에서는 여러 대의 서버에 아커스를 배포하고 관리하고자 하는 사용자를 위해
아커스를 분산 배치하는 몇 가지 예제를 보이고,
어플리케이션 배포 및 시스템 관리를 쉽게 해주는 [Fabric][fabric]을 이용하여
아커스 클러스터를 관리하는 방법을 알려드립니다.

만약 README의 [Quick Start][readme-quick-start] 단계를 아직 진행해보지 않으셨다면
먼저 해보는 것을 추천합니다.

**Table of Contents**

- [배경 지식](#배경-지식)
  - [SSH public key 배포](#ssh-public-key-배포)
  - [Fabric](#fabric)
  - [ZooKeeper](#zookeeper)
- [아커스 클러스터 구성](#아커스-클러스터-구성)
  - [주키퍼와 아커스를 같은 서버에서 실행](#주키퍼와-아커스를-같은-서버에서-실행)
  - [기존에 운영하던 주키퍼를 사용하고 아커스만 설치](#기존에-운영하던-주키퍼를-사용하고-아커스만-설치)


## 배경 지식

여러 대의 서버를 다루는 것은 쉽지 않은 일입니다.
서버 설정을 동일하게 유지하거나 역할 별로 소프트웨어를 설치하고 실행하는 관리작업은
일일히 수작업으로 하기에는 너무 비효율적이고 실수를 유발할 수 있으므로 가능한한 자동화 해야 합니다.

경험 많은 사용자라면 [Puppet][puppet], [Chef][chef], [Ansible][ansible], [SaltStack][saltstack] 등의
도구를 이용한 자동화된 설치/배포 인프라를 이미 구축해두었을 것입니다.

만약 이러한 환경이 준비되어 있지 않다면 아래 내용을 참고하시기 바랍니다.

### SSH public key 배포

SSH를 통해 다른 서버로 접속하기 위해서는 패스워드 입력을 하거나 SSH public key 인증을 사용할 수 있습니다.
일반적으로 캐시 서버는 외부(인터넷)에 노출되지 않고 내부망에서 동작하기 때문에
신뢰할 수 있는 서버를 하나 지정하여 암호 없는 public key를 생성한 뒤 해당 key를 각 서버에 배포하여
이 서버를 게이트웨이로 사용할 수 있습니다.

자세한 내용은 아래 링크를 참고하시기 바라며 이 문서에서는 간단한 절차만 소개합니다.
https://help.ubuntu.com/community/SSH/OpenSSH/Keys (영문)

1. 다른 서버를 관리할 용도의 신뢰할 수 있는 서버를 한 대 결정합니다. 이 서버에 접속하여 SSH key를 생성합니다.
  ```
  $ mkdir -p ~/.ssh
  $ chmod 700 ~/.ssh
  $ ssh-keygen -t rsa
  ```

2. 각 서버에 public key를 전송합니다.
  ```
  # SSH 암호를 입력해야 함. 자신의 환경에 맞게 <username>, <hostname> 변경
  $ ssh-copy-id <username>@<hostname>
  ```

3. 패스워드 없이 접속이 잘 되는지 확인합니다. 잘 안될 경우 [링크][sshkey-manual]를 참조 바랍니다.
  ```
  $ ssh <username>@<hostname>
  ```

### Fabric

[Fabric][fabric]은 시스템 관리와 어플리케이션 설치를 자동화 하기 위한 파이썬 라이브러리이며
[Ansible][ansible]과 같이 별도의 에이전트 프로세스 없이 SSH 접속만으로 동작합니다.

아커스 패키지에는 Fabric과 Fabric이 사용하는 스크립트(fabfile)가 포함되어 있습니다.

### ZooKeeper

[ZooKeeper][zookeeper]는 분산 작업을 제어하기 위한 트리 형태의 신뢰도 높은 저장소입니다.
아커스는 분산된 각 캐시 서버의 설정을 저장하고 유효한 캐시 서버의 리스트를 클라이언트에게 제공하기 위해
ZooKeeper를 사용하고 있습니다.

ZooKeeper에 대한 자세한 내용은 아래 문서를 참고하시기 바랍니다.
- [손쉽게 사용하는 ZooKeeper 스토리지, Zoopiter!][helloworld-zookeeper]

## 아커스 클러스터 구성

아커스 클러스터는 다양한 방식으로 구성할 수 있지만 일반적으로 권장되는 구성을 예제로 보여드립니다.

### 주키퍼와 아커스를 같은 서버에서 실행

사용할 수 있는 서버가 많지 않다면 다음과 같이
한 서버에서 주키퍼 서버와 아커스 서버를 함께 실행시킬 수 있습니다.

```
+--------------------+   +--------------------+   +--------------------+
| cache001.arcus     |   | cache002.arcus     |   | cache003.arcus     |
+--------------------+   +--------------------+   +--------------------+
|                    |   |                    |   |                    |
| ZooKeeper1:2181    |   | ZooKeeper2:2181    |   | ZooKeeper3:2181    |
|                    |   |                    |   |                    |
| Memcached1-1:11211 |   | Memcached2-1:11211 |   | Memcached3-1:11211 |
| Memcached1-2:11212 |   | Memcached2-2:11212 |   | Memcached3-2:11212 |
|                    |   |                    |   |                    |
+--------------------+   +--------------------+   +--------------------+
```

### 기존에 운영하던 주키퍼를 사용하고 아커스만 설치



<!-- Reference Links -->

[readme-quick-start]: ../README.md#quick-start
[zookeeper]: htttp://zookeeper.apache.org/ "ZooKeeper"
[fabric]: http://fabfile.org/ "Fabric"
[puppet]: http://puppetlabs.com/puppet/what-is-puppet/ "Puppet"
[chef]: http://docs.opscode.com/chef_quick_overview.html/ "Chef"
[ansible]: http://docs.ansible.com/ "Ansible"
[saltstack]: https://github.com/saltstack/salt "SaltStack"
[sshkey-manual]: https://help.ubuntu.com/community/SSH/OpenSSH/Keys/
[helloworld-zookeeper]: https://www.google.co.kr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&ved=0CDQQFjAB&url=http%3A%2F%2Fhelloworld.naver.com%2Fhelloworld%2F583580&ei=2e1xU5izDse2lQXnxIDYDA&usg=AFQjCNEBkwOjoEc_eLpdE9q1rCp_U4IcxA&sig2=dTYLKAVJded2Ur_QwPDYHw&bvm=bv.66330100,d.dGI&cad=rjt

