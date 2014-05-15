How To Manage GIT Submodules
============================

Git 서브모듈은 분산된 프로젝트를 하나로 묶을 수 있는 좋은 방법이지만
한번 만들어진 서브모듈을 최신으로 유지하기가 까다로운 단점이 있습니다.

이 문서에서는 아커스 패키지 관리자가 각 서브모듈의 릴리즈에 대응하여
전체 패키지를 최신 또는 특정 버전으로 맞추는 방법을 간략히 기술합니다.

```
# 패키지를 가지고 온다.
git clone ...
cd arcus

# submodule을 초기화 한다.
git submodule init
git submodule update # 이 시점에 현재 참조되고 있는 버전을 가져온다.

# 외부에서 변경된 submodule이 있다면 변경 사항을 가지고 온다.
cd server
git pull origin master # master branch의 HEAD를 가져오고 싶은 경우
git checkout -b 1.7.0-tag remotes/origin/1.7.0 # remote branch의 특정 tag를 기준으로 하고 싶은 경우

# 위 작업이 끝나면 submodule의 포인터가 바뀐다. 다음과 같이 반영하자.
git status
git add server
git commit -m 'updated submodule: server'
git push -u origin master
```

