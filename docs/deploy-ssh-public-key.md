Deploy SSH Public Key
=====================

SSH를 통해 다른 서버로 접속하기 위해서는 패스워드 입력을 하거나 SSH public key 인증을 사용할 수 있다.
Arcus cache cloud는 일반적으로 외부(인터넷)에 노출되지 않고 내부망에서 동작하기 때문에
신뢰할 수 있는 서버를 하나 지정하여 암호 없는 public key를 생성한 뒤 해당 public key를
접근할 각 서버에 배포해 두고, 현재 서버를 게이트웨이로 사용할 수 있다.

자세한 내용은 아래 링크를 참고하길 바라며 이 문서에서는 간단한 절차만 소개한다.
https://help.ubuntu.com/community/SSH/OpenSSH/Keys (영문)

1. 다른 서버를 관리할 용도의 신뢰할 수 있는 서버를 한 대 결정하고 해당 서버에 접속하여 SSH key를 생성한다.
  ```
  $ mkdir -p ~/.ssh
  $ chmod 700 ~/.ssh
  $ ssh-keygen -t rsa
  ```

2. 각 서버에 public key를 전송한다.
  ```
  # SSH 암호를 입력해야 함. 자신의 환경에 맞게 <username>, <hostname> 변경
  $ ssh-copy-id <username>@<hostname>
  ```

3. 패스워드 없이 접속이 잘 되는지 확인. 잘 안될 경우 [sshkey 매뉴얼][sshkey-manual]를 참조.
  ```
  $ ssh <username>@<hostname>
  ```

<!-- Reference Links -->

[sshkey-manual]: https://help.ubuntu.com/community/SSH/OpenSSH/Keys/

