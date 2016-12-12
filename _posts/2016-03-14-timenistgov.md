---
layout: post
title: rdate time sync
tags: ['rdate']
---

해외로 원격접속을 할 일이 있거나
현재 로컬의 시간이 안 맞을 때

특히 가상머신의 **suspend** 기능을 자주 쓰시는 분들은
시간도 그대로 멈춰버려서 다시 설정을 하는 경우가 있습니다.

간단하게 시간을 설정하는 방법을 공유하고자 합니다.

Redhat Linux의 경우이며 루트권한(sudoer)이 있어야 합니다.

```
(yum install rdate        rdate 패키지 설치)
rdate -s time.nist.gov   시간 설정
```

[NIST](http://tf.nist.gov/tf-cgi/servers.cgi) 라는 인터넷으로 시간을 맞춰주는 서비스입니다.
가까운 NIST서버의 IP를 찾아 자동으로 timezone에 따른 시간을 맞추는거 같습니다.
