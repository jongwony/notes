---
layout: post
title: OCR 한글 학습
tags: ['ocr', 'tesseract', 'python', 'opencv', '한글']
---

[Tesseract, OpenCV 설치](/2017/04/25/tesseract-ocr.html)

Tesseract-OCR을 사용했지만 특히 한글의 인식율이 기대에 미치지 않아 크게 실망하고 다른 엔진을 찾아다닐 수 있습니다.

하지만 생각해 보면 OCR 엔진 하나가 모든 생활에서의 인식 문제를 해결할 수 없다는 것은 당연한 일입니다. 

Tesseract 4.0 버전으로 접어들면서 신경망 기술을 사용하여 다양한 상황에 접근하는 학습 능력을 갖추었다고는 하지만 사실 OCR을 사용하는 주된 이유는 스캐닝을 하거나 간단한 자동화를 위한 경우가 많을 것이라고 생각합니다.

빅데이터가 아닌 이상 어느 정도 규칙적인 이미지에서 필요한 글자만 학습하면 된다면 굳이 신경망 기술을 사용할 만큼 복잡한 케이스를 다룰 필요가 없을 뿐더러 이에 맞는 컴퓨팅 파워도 충족해야 합니다.

정리하자면 문제 인식을 다음과 같이 하여 OCR 한글 학습을 시도해 보겠습니다.

- 목적이 분명하며 제대로 학습 해야만 하는 글자가 있다.
- Input으로 비슷비슷한 이미지가 제공된다.
- 신경망을 사용할만큼 컴퓨팅 파워가 충분하지 않다(특히 라즈베리파이를 사용할 경우).

위와 같은 상황이라면 OCR을 목적에 맞게 사용할 수 있으며 학습한 글자에 대해서는 꽤나 정확하게 인식할 수 있습니다.

Tesseract 3.03 버전 이상부터는 위와 같은 상황에 대한 간단한 학습을 진행할 수 있습니다.

<div class='warn'>
Tesseract 4.x 버전과 3.x 버전은 학습하는 방법이 다릅니다.<br>
이 포스팅은 3.03 이상에서의 클러스터링 방법입니다.<br>
Tesseract를 설치할 때 <code>git checkout 3.04.01</code> 등의 명령으로 해당 버전을 설치하셔야 합니다. <a href='//github.com/tesseract-ocr/tesseract/releases'>Release</a>
</div>

Tesseract 4.0 버전 [Manual](https://github.com/tesseract-ocr/tesseract/wiki/TrainingTesseract-4.00)

## OpenCV를 사용하는 이유

한글 인식은 **인식**에 관한 문제입니다. 이미지로 부터 인식을 하는 과정이 필요한데 Tesseract는 모든 이미지를 상황에 맞게 인식시킬 수 없을 뿐더러 사용하는 필터도 제한적입니다.

글자를 인식하려면 먼저 글자의 가장자리 부분을 알아야 하며 또한 이 각 글자마다 가장자리 영역이 어디까지인지 추출해야 합니다.
한글의 경우 영어와 달리 초성 중성 종성이 합쳐지는 경우가 있으므로 생각보다 쉬운 일이 아닙니다.

결국 제대로 학습해야만 하는 글자가 있다면 전처리 과정을 확실히 하는 것이 중요합니다.
이미지에 따라 다르겠지만 저는 다음과 같은 과정을 진행했습니다.

1. GrayScale로 변환한다.
1. 이미지를 확대한다.
1. 노이즈를 제거한다.
1. 이진화 시킨다.

첫 번째로 글자를 처리하는 데 있어 색이 필요하지 않습니다. GrayScale로 변형하여 나중에 이진화 작업을 합니다.

두 번째로 글자가 작은 경우가 있기 때문에 이미지를 확대합니다. 이 과정은 인식이 불필요한 부분을 잘라내는 것도 포함합니다. 이 과정으로 글자가 어느 정도 깨지게 되거나 안티앨리어싱 부분이 드러날 것입니다.

세 번째로 불필요한 테두리 인식을 방지하기 위해 노이즈를 제거합니다. 

마지막으로 글자와 배경을 완벽하게 흑과 백으로 이진화를 시킵니다. 어느정도 회색의 글자도 있기 때문에 이진화의 정도를 조절합니다. 안티앨리어싱으로 흐려진 글자를 명확하게 할 수 있습니다.

위의 사진은 스크린샷 이미지라 간단한 옵션으로 해결이 가능하지만 원본 이미지가 카메라로 촬영된 이미지일 경우는 [Adaptive Gaussian Thresholding](//docs.opencv.org/trunk/d7/d4d/tutorial_py_thresholding.html) 같은 기술이 필요합니다.

OpenCV의 윤곽(contour) 인식은 기본적으로 검은 바탕에서의 흰색 오브젝트를 찾는 것이라고 합니다[(참조)](//docs.opencv.org/trunk/d4/d73/tutorial_py_contours_begin.html).
따라서 이진화 할 경우 글자를 흰색으로, 배경을 검게 하는 것이 인식율을 높이는 방법이 될 수 있습니다.

아래 이미지로 테스트를 해보겠습니다.

![rawimage](/image/ocr/rawimage.png)

이미지를 자세히 확대해 보시면 다음과 같이 글씨 주위의 노이즈를 발견할 수 있습니다.

![noise](/image/ocr/noise.png)


다음은 예제 코드입니다.

```python
# -*- coding: utf-8 -*-

import cv2
import numpy as np

img = cv2.imread('rawimage.png')
dst = 'result.png'

# Gray Scale
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Enlarge 2x
height, width = gray.shape
gray_enlarge = cv2.resize(gray, (2*width, 2*height), interpolation=cv2.INTER_LINEAR)

# Denoising
denoised = cv2.fastNlMeansDenoising(gray_enlarge, h=10, searchWindowSize=21, templateWindowSize=7)

# Thresholding
gray_pin = 196
ret, thresh = cv2.threshold(denoised, gray_pin, 255, cv2.THRESH_BINARY)

# inverting
thresh[260:2090] = ~thresh[260:2090]

result = np.hstack((gray_enlarge, thresh))

cv2.imwrite(dst, result)
```

`interpolation` 옵션은 어차피 이진화 작업을 할 것이기 때문에 `cv2.INTER_CUBIC` 옵션보다 빠른 `cv2.INTER_LINEAR`를 사용했습니다.

사진에 어느정도 회색의 글자가 있습니다. 이를 인식하기 위해 회색 인식 정도를 `gray_pin`으로 조절했습니다.

검은 바탕에서의 흰색 글자를 만들기 위해 사진을 잘라 인버팅 과정을 거쳤습니다.

아래는 결과 사진입니다.

![result](/image/ocr/result.png)

이로써 글자 인식만을 위한 깔끔한 이미지를 추출할 수 있습니다.

```python
# -*- coding: utf-8 -*-

import os
import Image
import pytesseract

os.environ['TESSDATA_PREFIX'] = '/usr/share/tesseract-ocr'

print(pytesseract.image_to_string(Image.open('result.png')))
```

![pytesseract_basic](/image/ocr/pytesseract_basic.png)

사실 이런 기본적인 이미지 프로세싱 과정만 거쳐도 위와 같이 벌써부터 차이가 나기 시작함을 알 수 있습니다(출력을 위해 `np.vstack`으로 바꾸어 출력했습니다).

하지만 한글만 인식하는 탓인지 기호 및 영어를 구별하지 못합니다. 이를 커스터마이즈하여 타겟에 대한 정확한 학습을 필요로 합니다.

## Tesseract Training

이제 트레이닝의 시작입니다.

OpenCV를 통한 전처리 과정으로 Tesseract Training을 위한 인식도 향상되었을 것입니다.

전체적인 과정은 [Tesseract 3.03-3.05 new language training](//github.com/tesseract-ocr/tesseract/wiki/Training-Tesseract#run-tesseract-for-training)와 같습니다.

#### Data files

필요한 데이터 파일은 다음과 같습니다.

- `<lang>.config`
- `<lang>.unicharset`   (필수)
- `<lang>.unicharambigs`
- `<lang>.inttemp`      (필수)
- `<lang>.pffmtable`    (필수)
- `<lang>.normprotp`    (필수)
- `<lang>.punc-dawg`
- `<lang>.word-dawg`
- `<lang>.number-dawg`
- `<lang>.freq-dawg`

이 데이터 파일들을 클러스터링하고 결합할 것입니다.

#### 학습할 기본 텍스트 파일

위 사진을 통해 학습할 기본 텍스트는 아래와 같이 정리할 수 있습니다.

```
개발제한구역 스터디 예약현황 조회 예약일 회의실 예약하기 오후 년 월 일 1 2 3 4 5 6 7 8 9 0 M A B :
```
###### example.txt

Tesseract는 아래와 같은 명령을 통해 자동화하여 해당 글꼴을 통해 `tif`파일로 자동으로 변환시켜 줍니다.

그러면 먼저 한글 글꼴이 필요한데 저작권에 문제가 없는 Naver의 나눔 글꼴을 사용했습니다.

```
# ./NanumGothic.ttf exist
text2image --text=example.txt --outputbase=mylang.NanumGothic.exp0 --font='NanumGothic' --fonts_dir=.
```

그럼 `mylang.NanumGothic.exp0.tif` 이미지 파일과 `mylang.NanumGothic.exp0.box` 박스 파일 두가지가 자동 생성됩니다.

박스파일은 `cat` 명령으로 조회해 보면 이미지에서 4개의 박스 좌표만 나온다는 것을 알 수 있습니다. 텍스트 파일은 글꼴덕에 비교적 정확하게 글자가 추출되어 교정작업이 필요 없지만, 이제부터 사진으로 학습을 해야 하므로 그래픽 도구를 사용하는 것이 편리합니다.

*jTessBoxEditor.jar* 또는 *ScrollView.jar*를 사용하시는 것을 권장합니다.

![jTessBoxEditor](/image/ocr/jtessboxeditor.png)
###### jTessBoxEditor.jar

사진과 같이 해당 좌표를 수정하거나 새로 추가할 수 있으며 그래픽 도구 없이 그냥 box파일을 편집해도 됩니다...

#### Convert Image

파일 형식은 꼭 `<lang>.<font>.exp<num>.tif` 형식이어야 합니다. 기존 사진을 `tif` 파일로 변경하면 되는데 여기서 문제가 하나 발생합니다.

단순히 `cp` 명령어로 확장자를 바꾸면 DPI가 손실되어 편집을 할 수 없으며 추후에도 오류가 계속 발생합니다.

이때 설치한 `imagemagick` 라이브러리를 사용하여 이미지를 300 DPI를 가진 `tif` 이미지로 변환할 수 있습니다. 

```
convert -units PixelsPerInch result.png -density 300 mylang.NanumGothic.exp1.tif
```

당연한 이야기지만 변환하는 원본 이미지는 OpenCV로 프로세싱 된 것이 좋습니다.

#### Make Box file

이제 새로 만든 `tif` 파일의 `box` 파일을 만듭니다.
Tesseract에서 다음 명령을 통해 지원합니다.

```
tesseract mylang.NanumGothic.exp1.tif mylang.NanumGothic.exp1 -l kor batch.nochop makebox
```

데이터가 아직 학습이 되지 않았기 때문에 교정 작업을 일일이 해주어야 합니다.
그나마 GUI를 이용하여 교정하는 것이 빠릅니다.

#### Training

힘든 교정 과정이 끝나면 이제 데이터로 학습을 진행합니다.

```
tesseract mylang.NanumGothic.exp0.tif mylang.NanumGothic.exp0 box.train
...
```

여러개의 `tif` 파일로 학습하는 것이 좋습니다.
이 과정으로 `mylang.NanumGothic.exp0.tr` 파일이 생성됩니다.


#### unicharset

```
unicharset_extractor mylang.NanumGothic.exp0.box mylang.NanumGothic.exp1.box ...
```

클론한 langdata 레포지토리를 참조하여 이 한글 데이터를 바탕으로 새로운 
unicharset 파일을 만들어 냅니다.

```
set_unicharset_properties -U unicharset -O kor.unicharset --script_dir=../langdata
```

생성된 `kor.unicharset`을 `mylang.unicharset`으로 이름을 변경합니다.

#### font_properties

글꼴과 맞는 파일을 작성합니다.

형식은 `font` `italic` `bold` `fixed` `serif` `fraktur` 입니다.

```
NanumGothic 0 0 0 0 0
```

#### Clustering

클러스터링은 `shapeclustering`, `mftraining` 두가지 명령을 수행할 수 있습니다.
`shapeclustering`은 영어 문자에 추가로 결합되는 문자(ḗ, ɔ̄́, r̥̄)처럼 인도 어 이외에서는 사용해서는 안됩니다. 그래도 `shapetable` 파일은 생성됩니다.

그러므로 아래와 같이 `mftraining` 명령만 진행합니다.


#### mftraining

```
mftraining -F font_properties -U unicharset -O mylang.unicharset mylang.NanumGothic.exp0.tr mylang.NanumGothic.exp1.tr ...
```

`shapetable`, `inttemp`, `pffmtable` 파일이 생성됩니다. 마찬가지로 combine을 위해 앞에 `mylang.`을 추가하여 파일 이름을 바꿉니다.

#### cntraining

```
cntraining mylang.NanumGothic.exp0.tr mylang.NanumGothic.exp1.tr ...
```

`normproto` 파일이 생성됩니다.

#### Combine

`mylang.`으로 이름을 바꾼 데이터 파일을 모두 결합합니다.

```
combine_tessdata mylang.
```

이렇게 최종적으로 `mylang.traineddata` 파일이 만들어지며 이 데이터를 `TESSDATA_PREFIX/tessdata` 경로에 추가함으로써 Tesseract의 새로운 언어로써 사용할 수 있습니다.

```python
# -*- coding: utf-8 -*-

import os
import Image
import pytesseract

os.environ['TESSDATA_PREFIX'] = '/usr/share/tesseract-ocr'

print(pytesseract.image_to_string(Image.open('result.png'), lang='mylang'))
```

- - -

사실 사소한 부분을 제외하고는 매뉴얼과 같습니다. 가장 어려운 것은 처음 접할 때 프로세스를 이해하는 것이며 GUI로 교정하는 것이 힘들 뿐 과정 자체에서의 어려운 점은 없습니다.

학습이 안된 순수한 머신은 갓난 아기와 비슷하다고 생각합니다. 아이도 경험에 따라 성장이 달라지는 것처럼 이를 어떻게 학습시키느냐에 따라 성능 및 결과도 달라질 것입니다.

## Project

이 포스트는 프로토타입이며 현재 node.js로 구현이 되어 있습니다.

- [GitHub](//github.com/RestrictedZone/telegramBot)