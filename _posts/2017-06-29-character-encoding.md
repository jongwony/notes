---
layout: post
title: Encoding 문제 찾기
tags: ['encoding', 'web']
---

## Encoding
인코딩은 텍스트를 바이트로 변환하는 작업입니다.

[참조 문서](http://htmlpurifier.org/docs/enduser-utf8.html#whyutf8-forms-urlencoded)에서 정리한 글입니다.

- **ASCII**는 영어 알파벳 기반의 7비트 인코딩입니다.
- é 및 æ와 같은 127개의 비표준 문자를 추가하여 **8비트 인코딩**으로 확장합니다.
- 이후 모든 언어의 표준을 위해 **UTF-8** 인코딩이 등장합니다.
 

## Website Encoding
가장 신뢰할만한 방법은 일단 브라우저 인코딩을 확인하는 것입니다.

Internet Explorer는 문자 인코딩의 MIME을 제공하지 않으므로 Description을 이용해 찾아야 합니다. 다음은 일반적인 것들입니다.

| IE description               | MIME name              |
|:-----------------------------|:-----------------------|
| Windows                      |                        |
| Arabic (Windows)             | Windows-1256           |
| Baltic (Windows)             | Windows-1257           |
| Central European             | (Windows)	Windows-1250 |
| Cyrillic (Windows)           | Windows-1251           |
| Greek (Windows)              | Windows-1253           |
| Hebrew (Windows)             | Windows-1255           |
| Thai (Windows)               | TIS-620                |
| Turkish (Windows)            | Windows-1254           |
| Vietnamese (Windows)         | Windows-1258           |
| Western European (Windows)   | Windows-1252           |
| ISO                          |                        |
| Arabic (ISO)                 | ISO-8859-6             |
| Baltic (ISO)                 | ISO-8859-4             |
| Central European (ISO)       | ISO-8859-2             |
| Cyrillic (ISO)               | ISO-8859-5             |
| Estonian (ISO)               | ISO-8859-13            |
| Greek (ISO)                  | ISO-8859-7             |
| Hebrew (ISO-Logical)         | ISO-8859-8-l           |
| Hebrew (ISO-Visual)          | ISO-8859-8             |
| Latin 9 (ISO)                | ISO-8859-15            |
| Turkish (ISO)                | ISO-8859-9             |
| Western European (ISO)       | ISO-8859-1             |
| Other                        |                        |
| Chinese Simplified (GB18030) | GB18030                |
| Chinese Simplified (GB2312)  | GB2312                 |
| Chinese Simplified (HZ)      | HZ                     |
| Chinese Traditional (Big5)   | Big5                   |
| Japanese (Shift-JIS)         | Shift_JIS              |
| Japanese (EUC)               | EUC-JP                 |
| Korean                       | EUC-KR                 |
| Unicode (UTF-8)              | UTF-8                  |

#### Embedded encoding

웹 개발자가 문자 인코딩을 지정할 곳이 `META` 태그에도 있습니다.

```html
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
```
 
이는 `HEAD` 섹션에서 찾을 수 있으며 `charset`의 텍스트는 **claim** 인코딩입니다. HTML은 이 인코딩이라고 주장하지만 실제 적용되는지의 여부는 다른 요소에 따라 결정됩니다.

- 브라우저의 문자 인코딩과 동일하거나
- 브라우저의 문자 인코딩과 다르거나
- `META` 태그가 전혀 없는 경우…

웹 서버에서 전송되는 `Content-Type` HTTP 헤더에도 다음과 같은 형식으로 포함될 수 있습니다.

```
Content-Type: text/html; charset=ISO-8859-1
```

하지만 헤더와 태그는 결국 실제 웹 페이지의 실제 문자를 설명할 뿐이라는 것을 유념해야 합니다.

웹페이지가 다음과 같은 경우 조치를 취할 수 있습니다.

- 특수문자를 사용하고, 가끔 제대로 보일 경우
	임베디드 인코딩을 서버 인코딩으로 변경합니다.

- 특수문자를 사용하지만 문자가 깨져서 나올 경우
	서버 인코딩을 임베디드 인코딩으로 변경합니다.

`form`을 사용한 양식 제출은 두가지 유형이 있습니다.
- `application/x-www-form-urlencoded` GET과 기본 POST 요청에 사용
- `multipart/form-data` 파일 업로드 같은 POST 요청에 사용

그러나 일단 인코딩 외부에서 문자를 추가하기 시작하면 (예 : Microsoft에서 곱슬 곱슬 한 "스마트"따옴표를 예로들 수 있습니다.) 이상한 일들이 발생하기 시작합니다.
이때는 지원되지 않는 문자를 물음표로 대체하거나 일반 문자 또는 엔티티 참조로 수정하거나 원본 인코딩과 혼합된 다른 문자 인코딩(일반적으로 Windows-1252가 아닌 iso-8859-1 또는 UTF-8이 8 비트로 산재되어 있음)으로 전송합니다.

이러한 행동을 방지하려면 브라우저 `agent`를 스니핑하고 다른 동작의 데이터베이스를 컴파일 후 적절한 변환 조치를 취해야 합니다.
결국 UTF-8이 모든 문자를 지원함으로써 모든 문제를 해결 할 수 있음을 알게 될 것입니다.

POST 요청일 경우 `Accept-Encoding` 헤더를 UTF-8로 설정하는 방법도 있습니다. 이때는 데이터가 UTF-8 형식이 될 것이므로 명시적으로 선호하는 로컬 문자 인코딩으로 변환해야 합니다.

문자를 표시하는 적절한 글꼴이 부족하여 발생하는 문제도 있습니다.
