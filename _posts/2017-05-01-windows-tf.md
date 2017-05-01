---
layout: post
title: Anaconda 없이 Tensorflow 설치
tags: ['windows', 'python', 'tensorflow']
---

설치 시간 **3분**

[Chocolatey 설치](//chocolatey.org/install)

#### PowerShell

Windows에서 Tensorflow 3.5.x 버전만 호환됩니다. 저는 3.6이 설치되어 있기 때문에 강제로 3.5 버전을 설치합니다.

[Installing with native pip](//www.tensorflow.org/install/install_windows#installing_with_native_pip)

```
choco install python -version 3.5.2.20161029 --force
```

보통 `C:\Python35`에 설치가 됩니다. 경로를 알아야 이 버전으로 실행합니다.

#### pip 9.0.1, virtualenv

```
pip install --upgrade pip
pip install virtualenv
```

#### Install tensorflow

```
cd %WORK_DIR%
virtualenv _tf --python=C:\\Python35\\python.exe
.\_tf\Scripts\activate
pip install --upgrade tensorflow
```

`numpy`, `werkzeug`, `protobuf`는 자동 설치됩니다.

#### Success

```python
(_tf) > python
Python 3.5.2
>>> import tensorflow as tf
>>> tf.__version__
'1.1.0'
>>> import numpy as np
>>> np.__version__
'1.12.1'
```

또는 `pip freeze`로 확인