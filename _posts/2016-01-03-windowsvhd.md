---
title: 가상디스크에 운영체제 설치
layout: post
---


* Windows 7 이상의 환경이어야 합니다.
* [부팅 USB](http://www.microsoft.com/en-us/software-download/windows10)를 준비합니다.


저의 경우는 부모 운영체제 하나에 여러개의 vhd파일을 넣어 사용합니다.

장점 : 문제가 생겼을 시 vhd파일만 깔끔하게 지우면 된다.
단점 : 운영체제를 선택해야하므로 부팅시간이 조금 더 걸린다.

USB으로 부팅 한 뒤 [Shift+F10]을 누르면 다음과 같은 화면이 나타납니다.

![Windows_usb_boot](/image/Windows_usb_boot.png)

VHD파일은 DISKPART에서 만듭니다.

```
diskpart
create vdisk file="{PATH}\{custom name}.vhd" maximum={size} [type=expandable]
```

디스크 파일을 원하는 경로{PATH} 에 {custom name}.vhd로 만드시면 됩니다.
size는 MB단위이며 뒤에 [type=expandable]은 디스크를 동적으로 사용할 것인지의 옵션입니다.
저는 동적으로 했다가 본래 용량을 까먹을까봐 옵션을 주지 않았습니다.

디스크 파일을 만든 순간 vhd파일이 선택된 상태가 됩니다.

![vhd_create_inWindows](/image/vhd_create_inWindow.png)

물론 위와 같이 윈도우에서 VHD파일을 만들고 VHD파일을 선택하셔도 됩니다. 이런 경우에는 VHD파일을 따로 선택해주기만 하면 됩니다.

[가상디스크가 미리 만들어진 경우]

```
[select vdisk file="{PATH}\{custom name}.vhd"]  
```

VHD파일이 선택 되었으면 연결(마운트)합니다.

```
attach vdisk
```

exit으로 종료하신 후 윈도우 설치를 진행합니다.
파티션을 나누는 사용자 설정에서 **할당되지 않은 공간에** 꼭 설치를 하셔야 합니다.

![Windows_install](/image/Windows_install.png)

윈도우 설치가 완료되면 운영체제 선택 화면이 뜰 것입니다.

**같은 운영체제일 경우 이름이 같을 수가 있습니다.**

같은 운영체제로 설치를 하면 이름이 같아서 바꾸고 싶을 것입니다.
BCDEDIT명령을 이용하여 바꿀 수 있습니다.

운영체제 선택화면에서 **로고가 아닌 창 모양이** VHD로 부팅될 것입니다.
클릭하시고 해당 운영체제의 설치를 마무리한 후 **관리자 명령프롬프트를** 실행합니다.

```
bcdedit
```

![bcdedit](/image/cmd_bcdedit.png)

**identifier가** VHD환경에서 접속하셨다면 {current}를, 다른 환경이라면 systemroot항목이 \\로 시작하면 해당 항목이 가상디스크입니다.

BCDEDIT명령으로 해당항목의 DESCRIPTION을 변경할 것입니다.

```
bcdedit /set { identifier } description " 변경할 이름 "
```

변경 후 재부팅하시면 결과가 반영된 것을 확인하실 수 있습니다.
