---
layout: post
title: PowerShell에서 EC2 인스턴스 접속
tags: ['aws', 'powershell', 'vscode', 'ssh', 'putty']
---

Windows 사용자라면 Visual Studio Code 내부에서 PowerShell 터미널을 이용할 수 있습니다.
그간 편집기와 putty 창을 따로 켜셨던 분들이 생각보다 많을 겁니다.

![putty창](/image/aws/frompowershell.png)

이런 화면 없이 터미널에서 바로 접속하는 방법입니다.

실행 정책을 스크립트를 실행 가능하도록 합니다.

```powershell
# Run Administrator
Set-ExecutionPolicy BYPASS
```

관리자 권한으로 PowerShell을 실행한 후 *Chocolatey*를 사용하여 *putty*를 설치합니다.

```powershell
# Run Administrator
choco install putty
```

터미널에서 `plink` 키워드로 실행할 수 있습니다.  
(개인적으로 이런 터미널 스타트 명령어쯤은 chocolatey 설치 페이지에 같이 소개했으면 하는 바람이...)

```
plink --help
```

간단한 사용 예(ubuntu, 운영체제마다 AWS Connect 참조)

```
plink -ssh -i [puttygen으로 keypair pem -> ppk 변환] ubuntu@[AWS Instance Public DNS]
```

## Trouble?

<div class='warn'>
글자가 깨지고 <code>vim</code> 명령이 되지 않습니다.
</div>

이 경우에는 기존의 레거시 콘솔 설정을 사용하고 있기 떄문입니다. 아래와 같이 체크 해제를 해 주시면 정상적으로 동작합니다.

![legacy check 해제](/image/aws/legacy.png)
