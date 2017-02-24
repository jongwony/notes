---
title: Chocolatey 사용하기
layout: post
tags: ['windows','choco','powershell','git','jekyll']
---

<div class='warn'>
설치에 관한 모든 부분은 관리자 권한으로 실행하여야 합니다.
</div>

Linux를 사용하면서 편한 점은 package 관리자로 설치하는 것입니다.
터미널 부분은 이전 포스팅에서 git-bash를 이용하거나 minGW를 이용하여 어느 정도 흉내는 냈으나
git 자체의 버전도 올라가고, 터미널 인코딩이나 명령어 등 고질적인 윈도우 cmd 문제는 일일이 커스터마이징 하거나
심지어는 레지스트리를 건드리는 일 까지 발생합니다.

Visual Studio Code - PowerShell의 조합을 사용한 후에 비로소 역시 운영 체제에 맞는 환경을 사용하는 것이 가장 좋다는 것을 알게 되었습니다.

위의 조합을 알게 된 데에는 Chocolatey를 통한 윈도우 환경에서의 패키지 설치를 알게 된 후였습니다.

[https://chocolatey.org/install](//chocolatey.org/install)

홈페이지를 통해 설치하려고 하면 관리자 권한의 PowerShell에서 설치하라고 하며 `Get-ExecutionPolicy`의 제한을 풀라고 합니다. 일단 명령어가 무엇인지 알기 위해 `help`부터 쳐 보았습니다.

```powershell
help

Get-Help iwr
Get-Help Get-ExecutionPolicy
Get-Help Set-ExecutionPolicy
```

찾아보면 `iwr`은 `Invoke-WebRequest`의 `alias`로 리눅스의 `wget`과 같은 역할을 하며 `wget` 역시 `alias`로 설정되어 있음을 알 수 있습니다.
PowerShell 스크립트 파일을 `iwr`을 통해 가져오므로 스크립트 실행 권한을 풀어 주는 것이 `ExecutionPolicy`라는 것을 알 수 있습니다.

문서가 Chocolatey 설치 페이지를 통해 제공되었으므로
이름과 구문만 알면 되겠습니다.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
```

앞으로 버전이 업데이트 된다면 `choco upgrade chocolatey`를 실행하면 되겠습니다.
스크립트의 설치가 완료되면 `powershell`을 다시 실행시키거나 `refreshenv`를 입력합니다.
이제 패키지 설치를 할 수 있게 됩니다.
Visual Studio Code 편집기, `git` 및 `NodeJS` 등 다양한 패키지를 설치 할 수 있습니다.

[https://chocolatey.org/packages](//chocolatey.org/packages)

`git`의 최신 버전을 설치해 보겠습니다.

[https://chocolatey.org/packages/git.install](//chocolatey.org/packages/git.install)

이미 설치되어 있다면 `upgrade` 인수를 사용합니다.

```
choco install git.install
```

저는 이 블로그가 [`jekyll`](//jekyllrb.com/docs/windows/) 기반이기에 `ruby` 설치와 함께 설치해 보았습니다.

```
choco install ruby -y
```

[SSL 이슈](//github.com/juthilo/run-jekyll-on-windows/issues/34)가 있어서 오류를 해결한 후 `jekyll`을 설치합니다.

(gem을 업데이트하는 방법이 확실하지만 루비를 블로그 이외에 잘 쓰지 않기 때문에 다음과 같이 간단한 방법으로 해결하였습니다.)

```ruby
gem sources --remove https://rubygems.org/
gem sources -a http://rubygems.org/
gem install jekyll
```

Visual Studio Code 편집기 역시 설치 할 수 있습니다.

```
choco install visualstudiocode
```

이 편집기는 PowerShell 터미널을 지원하므로 이제 `jekyll serve`를 편집기에서 실행할 수 있습니다.

![vscode](/image/vscode.png)

기타 다양한 패키지 역시 설치할 수 있습니다. 자세한 내용은 [GitHub](//github.com/chocolatey/choco)를 참조하시기 바랍니다.