---
layout: post
title: EC2에 Pycharm IDE 동기화
---

이전 포스트에서 EC2에 OpenCV와 Tensorflow를 설치하였습니다.

언제까지 vim 에디터만 사용할 수는 없으므로

Windows 환경에서 SFTP 원격 연결된 Pycharm IDE를 이용하여 코딩을 할 수 있고

나아가 GitHub repository와 동기화 하는 방법입니다.

Windows 10 환경에서 테스트 하였습니다.

---

## Pycharm

Pycharm IDE를 [다운로드](//www.jetbrains.com/pycharm/download/#section=windows) 합니다.

<div class='warn'>
Community 버전은 SSH 또는 SFTP 연결을 지원하지 않습니다.
</div>

오픈소스나 학생인 경우, 또는 교육이나 트레이닝 목적으로 하는 경우에는 [무료로 라이센스 획득](//www.jetbrains.com/pycharm/buy/#edition=discounts)이 가능합니다.


#### Git VCS

GitHub 계정이 있다면 Git Repository와 로컬 디렉터리를 동기화하여 commit과 push를 간편하게 할 수 있습니다.

먼저 [GitHub에 접속](//github.com)하여 Repository를 생성합니다.

![](/image/aws/gitrepo.png)

그러면 본인의 Git Repository를 clone 하기 위한 url이 제공됩니다.

![](/image/aws/giturl.png)

Pycharm 에서 Create New Project > VCS에서 위 과정으로 복사한 url을 붙여넣습니다.

<div class='def'>
이미 프로젝트를 생성한 단계라면 VCS > Checkout from Version Control > Git 항목에서
<br>
같은 과정을 진행 할 수 있습니다.
</div>

<div class='def'>
프로젝트 생성 후에 VCS > Git 또는 VCS > Commit Changes 항목에서 <br>
프로젝트를 commit, push 할 수 있습니다.
</div>

#### Create project

Create New Project > Pure Python에서 경로를 지정하고

Python Interpreter > Add Remote를 선택합니다.

Host에 EC2 Public DNS 주소와 접속할 포트를 지정하고 사용자를 Ubuntu로 한 다음 Keypair 인증 방식으로 pem 파일을 가져옵니다.

![](/image/aws/interpreter.png)

이전 포스팅에서 EC2에 OpenCV와 Tensorflow를 설치한 환경이 Python 2.7.6 버전이었기 때문에

해당 버전이 나타납니다.

Interpreter 업데이트 및 다운로드가 끝나면 Create를 눌러 프로젝트를 생성합니다.


#### Deployment

Ctrl + Alt + S를 누르거나 File > Settings로 이동합니다.

Configure > Setting > Deployment의 Connection 탭으로 이동합니다.

![](/image/aws/deploy.png)

![](/image/aws/sftp.png)

SFTP 연결을 새로 만듭니다.

호스트란에 EC2로 접속하는 Public DNS 주소를 입력합니다.

![](/image/aws/connection.png)

Mapping 탭으로 이동하여 동기화할 프로젝트 경로를 지정합니다.

이때 루트경로(/)는 Connection 탭에서 자동으로 검색된 경로(/home/ubuntu/) 입니다.

![](/image/aws/mapping.png)

<div class='def'>
Tools > Deployment > Sync with Deployed to 항목에서 <br>
SFTP를 이용하여 EC2의 /home/ubuntu/pycharm 경로로 업로드 할 수 있습니다.
</div>
