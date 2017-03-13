---
layout: post
title: Python 콘솔에서 Google 번역
tags: ['python', 'console', 'translate', 'http2', 'project']
---

[Google Translate](//translate.google.com) + HTTP/2

HTTP/2를 통해 Python 콘솔로 구글 번역 페이지를 우회하는 프로그램입니다.

간단한 문장을 번역할 때 구글 번역기를 쓰는 경우가 있습니다.
저는 마크다운으로 포스팅을 하며 글을 작성하는데 번역시 간단한 단어나 문장을 추가로 크롬 브라우저를 켜서 translate.google.com을 쳐서 매번 들어가기 귀찮았습니다.
그래서 Python을 통해 작동하도록 간단하게 기능만 가져왔습니다. 저는 Windows 사용자라 Visual Studio Code를 사용하고, 여기서 터미널을 지원하기에 노트북 사용시 따로 브라우저를 켜지 않는다면 엄청난(?) 배터리 절약도 할 수 있겠습니다.

최근 HTTP/2 표준이 어마어마한 속도를 자랑하고 있다기에 *requests* 라이브러리에 추가해 보았습니다. [관련 블로그 포스트](//www.popit.kr/%EB%82%98%EB%A7%8C-%EB%AA%A8%EB%A5%B4%EA%B3%A0-%EC%9E%88%EB%8D%98-http2/)

## Requirements

**Python 3.6** 버전에서 생성한 프로젝트입니다.

```
hyper==0.7.0
beautifulsoup4==4.5.3
requests==2.13.0
```

#### Virtualenv install

[GitHub](//github.com/lastone9182/hypertrans)

```
pip install virtualenv
virtualenv _hypertrans

(Windows) `.\_hypertrans\Scripts\activate`

pip install requests
pip install hyper
pip install beautifulsoup4

pip freeze
```

## Usage

```
python main.py
```

#### Options

| Option | key |  
|:---|:---|  
| Quit | 'q' |  
| Swap | 's' |  
| Custom | 'c' |

```
en->ko: i am great
나는 잘 지내고있어
en->ko: s
I'm doing well.
ko->en: s
나는 잘하고 있어요.
en->ko: c
Source Language: 
Destination Language: ja
en->ja: i'm doing well
私はうまくやってる
```

## Reference

- [Google Translation API](//cloud.google.com/translate/docs/)  
- [Quickstart requests](//docs.python-requests.org/en/master/user/quickstart/)  
- [Quickstart hyper](//hyper.readthedocs.io/en/latest/quickstart.html)  
- [GitHub: py-googletrans](//github.com/ssut/py-googletrans)