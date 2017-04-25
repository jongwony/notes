---
layout: post
title: Tesseract, OpenCV 설치
tags: ['ocr', 'tesseract', 'python', 'opencv', '한글']
---

소스코드로 부터 OpenCV와 Tesseract를 최신 버전으로 빌드하는 과정입니다.

코딩으로 인한 오류나 버그가 잘못된 설치로 발생하지 않도록 제대로 설치해야 합니다.
최신 버전으로 빌드 할 때는 어떤 모듈과 의존성이 연관되는지 알고 있는 것이 시간을 절약하는 지름길이라 생각됩니다.

다음 포스팅에 한글 OCR을 학습 시키기 위해 Tesseract Training 모듈까지 빌드합니다.

## Dependencies

AWS EC2 Ubuntu 16.04에서 테스트하였습니다.

#### Package Update, Upgrade

설치 할 때 최신 패키지를 유지하는 것은 필수입니다.

최근에 이를 진행하지 않을 경우 `libgtk2.0-dev`의 URL을 찾을 수 없다는 에러 메시지가 나타났었습니다.

```
sudo apt update
sudo apt upgrade
```

#### Python Tools

`python-pip`을 통해 여러 의존성 모듈이 함께 설치됩니다.

```
sudo apt install python-pip python-dev python-numpy python-Imaging
```

이렇게 설치된 `pip` 버전은 보통 `8.1.1` 버전입니다. 아래 명령을 통해 `9.0.1`로 업그레이드 합니다.

```
sudo -H pip install --upgrade pip
```

#### Compiler

각 홈페이지 메뉴얼에서는 OpenCV는 `cmake`, Tesseract는 `autotool`을 사용하여 컴파일합니다.

- [OpenCV Python Install](//docs.opencv.org/master/da/df6/tutorial_py_table_of_contents_setup.html)

- [Tesseract Compilation guide](//github.com/tesseract-ocr/tesseract/wiki/Compiling)

```
# Opencv compile
sudo apt install cmake libatlas-base-dev

# Tesseract compile
sudo apt install autoconf automake libtool autoconf-archive

# Compile interface
sudo apt install pkg-config
```

#### GTK 2.0

[GTK](//www.gtk.org/)는 GUI 인터페이스를 위한 멀티플랫폼 도구입니다.

```
sudo apt install libgtk2.0-dev
```

#### Image Extension

`png`, `jpeg`, `tiff` 등의 이미지를 프로세싱하기 위한 확장입니다.

```
sudo apt install libpng12-dev libjpeg8-dev libwebp-dev libtiff5-dev zlib1g-dev
```

#### OpenCV math Optimization(Optional)

`cmake`를 통해 선택할 수 있는 옵션이며 수학적인 계산을 최적화 해주는 도구입니다.

```
sudo apt install libeigen3-dev
```

#### Image convert, processing

Tesseract의 경우 이미지를 `mv`로 확장자만 변경할 경우 DPI가 손실되어 이미지로 부터 글자를 인식할 수 없습니다. `imagemagick` 라이브러리는 이미지 컨버팅과 동시에 DPI를 조절할 수 있게 해줍니다.

```
# image convert, processing
sudo apt install imagemagick graphicsmagick
```


#### Tesseract Training

Tesseract 학습을 위한 라이브러리이며 이 중 하나라도 설치되지 않으면 Tesseract를 build 할 때 `make training`을 통한 트레이닝 도구를 빌드할 수 없습니다.

```
sudo apt install libicu-dev libpango1.0-dev libcairo2-dev
```

## OpenCV Build

```
git clone https://github.com/Itseez/opencv.git
cd opencv
mkdir build
cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_EIGEN=ON ..

make -j4
sudo make install
sudo ldconfig
```

## Leptonica Build

Leptonica는 이미지 프로세싱 및 분석을 위한 도구입니다. Tesseract와 Ubuntu 버전에 따라 요구하는 Leptonica의 버전이 다를 수 있습니다.

**Tesseract** | **Leptonica** | **Ubuntu**
:-------------------: | :---------------------------------------: | :---------
4.00 | 1.74.0 | Must build from source 
3.04 | 1.71 | [Ubuntu 16.04](http://packages.ubuntu.com/xenial/libtesseract3)
3.03 | 1.70 | [Ubuntu 14.04](http://packages.ubuntu.com/trusty/libtesseract3)
3.02 | 1.69 | [Ubuntu 12.04](http://packages.ubuntu.com/precise/libtesseract3)
3.01 | 1.67 |

```
git clone https://github.com/DanBloomberg/leptonica.git
cd leptonica
./autobuild
./configure
make -j4
sudo make install
sudo ldconfig
```

## Tesseract Build

학습을 위한 기본 데이터들을 별도의 Repository로 제공합니다.

`unicharset` 파일 등을 생성하기 위해 필요합니다.

```
git clone https://github.com/tesseract-ocr/langdata.git
```

Ubuntu 버전 및 Laptonica 버전에 따라 오류가 발생할 수 있습니다.

`./configure`에서 오류가 발생할 경우 [설치 문서](//github.com/tesseract-ocr/tesseract/wiki/Compiling#compilation)를 참고하시기 바랍니다.

```
git clone --depth 1 https://github.com/tesseract-ocr/tesseract.git
cd tesseract
./autogen.sh
./configure --enable-debug
LDFLAGS="-L/usr/local/lib" CFLAGS="-I/usr/local/include" make
sudo make install
sudo ldconfig
```

설치 완료 후 학습 도구를 추가로 컴파일합니다.

```
make training
sudo make training-install
```

마지막으로 Python에서 Tesseract-ocr을 사용하기 위해 제공되는 언어 데이터와 `pytesseract`를 설치합니다.

```
sudo apt install tesseract-ocr-eng tesseract-ocr-kor
sudo -H pip install pytesseract
```

## Version Check

클론한 레퍼지토리 및 설치된 버전을 확인하는 방법입니다.

#### OpenCV

```python
# Python OpenCV
import cv2
cv2.__version__
```

#### Tesseract

```
# Tesseract
tesseract --version

# Tesseract repo
cd ~/tesseract
git log
```

#### Leptonica

```
# Leptonica repo
cd ~/leptonica
git describe
```

## Hello World

설치가 완료되었습니다. 간단한 예제를 작성해 보겠습니다.

```python
import os
import cv2
import Image
import pytesseract

os.environ['TESSDATA_PREFIX'] = '/usr/share/tesseract-ocr'

def cv2Threshold(path):
    img = cv2.imread(path)
    dest = 'result.png'

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    ret, thresh = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)

    cv2.imwrite(dest, thr)
    print(pytesseract.image_to_string(Image.open(dest)))

    return dest

if __name__ == '__main__':
    cv2Threshold('test.png')
```
###### hello.py
