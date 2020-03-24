### arcus-memcached make test 수행 실패

아래 에러를 보이며 make test 가 수행되지 않는 경우는
```
Can't locate Test/More.pm in @INC (@INC contains: /usr/local/lib64/perl5 /usr/local/share/perl5 /usr/lib64/perl5/vendor_perl
/usr/share/perl5/vendor_perl /usr/lib64/perl5 /usr/share/perl5 .) at -e line 1.
```
테스트 스크립트에서 필요로 하는 펄 모듈 Test::More.pm 이 시스템에 설치되어 있지 않아서 발생한다.
아래 절차를 따라 Test::More.pm 을 설치한다.
```
# Install CPAN
(CentOS) sudo yum install cpan
(Ubuntu) sudo apt-get install libpath-tiny-perl

# Install Test::More
cpan Test::More
```

### 아이템을 set 했는데 바로 사라지는 현상 또는 expire time 을 30일 이상으로 설정하려는 경우

아이템이 바로 사라지는 현상은 대부분 expire time 을 30일 이상으로 설정했을 때 발생한다.

expire time 은 아래와 같은 기준으로 설정되는데, 30일이 넘을 경우 1970년 이후 절대 시간으로 인식하기 때문에, 일반적으로 현재시간보다 과거의 시간으로 설정되어 바로 invalid 되기 때문이다.

-1 : sticky item으로 설정 (메뉴얼의 sticky 항목 참고: https://github.com/naver/arcus-memcached/blob/master/doc/arcus-basic-concept.md)
0 : never expired item으로 설정, 그러나 메모리 부족 시에 evict될 수 있다.
X <= (606024*30) : 30일 이하의 값이면, 실제 expiration time은 "현재 시간 + X(초)"로 결정된다. -2 이하이면, 그 즉시 expire 된다.
X > (606024*30) : 30일 초과의 값이면, 실제 expiration time은 "X"로 결정된다. 이 경우, X를 unix time으로 인식하여 expiration time으로 설정하는 것이며, X가 현재 시간보다 작으면 그 즉시 expire 된다.

30일이 넘는 값으로 설정하고 싶으면 위의 규칙을 참조하여 "현재 시간 + expire time" 을 unix timestamp 로 환산하여 설정한다.


### 자바 클라이언트 로거 설정

아래 링크의 설정을 참조하여 로거설정을 변경한다.

https://github.com/naver/arcus-java-client/blob/master/docs/02-arcus-java-client.md#arcus-client-%EC%84%A4%EC%A0%95
