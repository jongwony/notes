---
layout: post
title: Data Visualization with Flask
tags: ['python', 'pandas', 'flask', 'd3.js']
---

데이터가 끊임없이 변화하고 방대해지면서 데이터를 잘 분석하고, 표현하는 것이 중요해지고 있습니다.

데이터를 분석하는 이유는 가치를 창출하는 등 여러가지 이유가 있지만 특히 **의사소통을 위해서**라고 생각합니다.  
어떠한 데이터를 분석할 것인지 기획이 필요하며 데이터를 담고, 추출하고, 원하는 데이터를 쿼리를 통해 다듬는 분석 과정으로 다른 사람에게 직관적으로 빠른 이해를 돕기 위해 시각화를 합니다.

그림으로 나타내면 다음과 같습니다.

![workflow](/image/visualization/dataworkflow.gif)
###### Image: [https://www.promptcloud.com/next-generation-of-data-mining/](//www.promptcloud.com/next-generation-of-data-mining/)

우선 데이터를 추출하여 데이터베이스에 저장합니다.
그런 다음 데이터베이스로 부터 데이터를 가져와야 합니다.
그 후 일련의 처리 작업을 통해 데이터를 다듬고, 시각화를 합니다.

위의 프로세스를 통해 간단한 프로젝트를 만들어 보았습니다.

[laptop_rhythm](//github.com/lastone9182/laptop_rhythm) 프로젝트는 로그온, 로그오프, 절전 시간 등을 분석하여 하루 동안 컴퓨터가 켜져 있는 시간을 웹페이지를 통해 시각화하는 간단한 프로젝트입니다.

![laptop_rhythm](/image/visualization/laptop_rhythm.png)

분석보다는 시각화에 중점을 두었기 때문에 데이터 탐색(Exploratory)에 가까울 수 있습니다.

## Process

Python 라이브러리를 통해 로그온 및 절전 시간 데이터를 추출하고 sqlite로 저장하는 방법이 있습니다.  
하지만 OS와 어느정도 연관된 부분이라 각 OS마다 구현이 다를 것으로 예상해서 각 환경에 맞게 스크립트로 데이터를 먼저 추출하는 것을 생각하였습니다.
제 환경은 Windows이므로 *PowerShell* 스크립트를 통해 데이터를 XML 또는 CSV로 추출합니다.

데이터 분석은 Python의 *pandas* 패키지를 통해 웹페이지로 시각화를 하겠습니다.  
*Flask* 패키지가 이 중간 역할을 할 것입니다.

데이터 시각화도 Python 패키지를 통해 하는 방법이 있지만, Flask가 서버 웹 애플리케이션임을 감안하여 데이터 시각화는 Javascript를 통해 클라이언트에서 동적으로 생성하도록 하였습니다.

Javascript에서 chart.js, highcharts 등 데이터 시각화를 위한 여러 라이브러리를 제공합니다. 그 중 `svg`, `canvas`를 통해 데이터를 시각화하는 *D3* 라이브러리를 통해 시각화를 시도해 보았습니다.

여기까지 과정을 그림으로 표현하면 아래와 같습니다.

![Process](/image/visualization/laptop_rhythm_process.png)

그러면 필요한 구성요소를 먼저 설치하는 것 부터 시작해보겠습니다.

## Installation

#### PowerShell

*PowerShell* 스크립트에는 실행 정책이 있습니다. 기본적으로 `RESTRICTED`로 설정되어 있으며 명령은 허용하지만 스크립트는 실행하지 않습니다.

스크립트를 실행가능하게 하기 위해 `REMOTESIGNED`, `BYPASS`, `UNRESTRICTED` 중 하나로 변경합니다. 옵션에 대한 자세한 설명은 [about_Execution_Policies](//technet.microsoft.com/ko-KR/library/hh847748.aspx)를 참고하시기 바랍니다.

실행 정책 변경은 **관리자 권한으로 PowerShell을 실행**한 상태에서 진행합니다.

```powershell
# Run Administrator
Set-ExecutionPolicy BYPASS
```

프로젝트에 `ps1` 파일을 생성하여 스크립트를 실행할 수 있게 됩니다.

#### Virtualenv

Python 3.6, pip 9.0.1 버전의 환경입니다.

개발 환경 분리를 위해 Python 가상 환경인 virtualenv는 필수입니다.  
이런 작은 프로젝트가 메인 환경과 충돌을 일으켜서는 안됩니다.  

*PowerShell* 스크립트에 가상환경으로 들어가는 명령을 작성하기 위해 작업 디렉터리의 이름을 기억합니다.

```
# Install
pip install virtualenv

# Create "_rhythm" directory
# [Optional 3.x version]
# If your main project's Python version differs from this project,
# specify a specific Python version.
virtualenv --python=python3.6 _rhythm
```

Windows 환경에서는 `bin`이 아닌 `scripts` 디렉터리 안에 `activate` 스크립트가 있으며 이를 실행하여 가상 환경을 활성화 시킬 수 있습니다.
예를 들면 다음과 같이 스크립트를 작성할 수 있습니다.

```powershell
# virtualenv activate
. $PSScriptRoot\_rhythm\Scripts\activate.ps1

# module running
python $PSScriptRoot\laptop_rhythm.py
```
###### laptop_rhythm.ps1

*PowerShell*에서 `$PSScriptRoot`는 스크립트 파일이 있는 위치를 나타냅니다.

#### Flask

<div class='def'>
지금부터 설치하는 모든 패키지는 virtualenv activate 스크립트를 실행하여 가상 환경 내부로 들어온 상태로 설치합니다.
</div>

*Flask*는 마이크로 프레임워크이며 짧은 시간에 만들 수 있는 작고 강력한 Python의 웹 애플리케이션입니다.

다음 명령으로 패키지를 설치합니다.

```
pip install flask
```

자동으로 `Werkzeug`, `Jinja2` 등의 패키지가 추가로 설치됩니다.

*Flask* 패키지에 대한 문서가 잘 작성되어 있습니다. 자세한 내용은 [Flask docs](//flask.pocoo.org/docs/0.12/)를 참조하시기 바랍니다.

#### Pandas

*Pandas* 패키지는 효과적인 데이터 분석을 위한 고수준의 자료구조와 데이터 분석 도구를 제공합니다.

다음 명령으로 패키지를 설치합니다.

```
pip install pandas
```

자동으로 `numpy`, `python-dateutil` 등의 패키지가 추가로 설치됩니다.

이 패키지를 통해 *Pandas*의 데이터 구조인 *DataFrame*을 사용하였습니다.
*DataFrame* 구조의 사용은 추가로 다루겠습니다.

#### D3

D3(Data-Driven Documents)는 데이터 기반의 문서를 다루기 위한 Javascript 라이브러리입니다. 웹 브라우저를 통해 다른 사람들이 데이터에 보다 쉽게 접근할 수 있도록 시각화하여 이해를 돕는 데에 중점을 둡니다.

사실 *Flask*를 사용한 이유도 *D3*의 웹 서버로 사용하기 위함이었습니다.

간단하게 html 문서에 import 함으로써 라이브러리 사용이 가능합니다.

```html
<script src="//d3js.org/d3.v3.min.js"></script>
```

경우에 따라 `d3-shape`, `d3-path` 라이브러리 등을 추가해야 할 수 있습니다.
이는 추가로 다루겠습니다. 더 자세한 내용은 [D3 GitHub Wiki](//github.com/d3/d3/wiki)을 참고하시기 바랍니다.

## Background

#### Windows Event File

Windows의 로그온오프, 절전 등의 시간의 데이터를 분석하려고 합니다.
Windows의 로그온오프, 절전은 Windows 시스템으로 발생한 이벤트입니다.
이는 로컬 컴퓨터의 이벤트 뷰어로 확인하실 수 있습니다.

![Windows Event](/image/visualization/windows_event.png)

`Windows 로그 - 시스템`에서 로그온, 로그오프, 절전, 절전 해제에 해당되는 이벤트 ID는 각각 7001, 7002, 506, 507이었습니다.
이제 이 4가지 이벤트만 추출하면 됩니다.

*PowerShell*에서는 `Get-EventLog` 명령어를 통하여 시스템에 한해 이벤트 로그를 얻을 수 있으며
`Export-CSV`를 통해 CSV 파일로 내보낼 수 있습니다.

```powershell
# event file Winlogon latest 100 to CSV
Get-EventLog -logname system -newest 100 -instanceid 7001, 7002, 506, 507 | `
Export-CSV -encoding UTF8 -path "$PSScriptRoot\static\logon_rhythm.csv"
```
###### laptop_rhythm.ps1

#### Flask Templates

*Flask*는 기본적으로 다음과 같은 구조를 가집니다.

```
Root
  ├── app.py
  ├── templates/
  └── static/
```

제 프로젝트에서는 `laptop_rhythm.py`가 `app.py`에 해당합니다.  
`app.py`를 실행하면 템플릿 파일과 스태틱 파일을 불러와서 서버를 가동시킵니다.
템플릿은 *Jinja2* 환경이며 템플릿 문법을 통해 렌더링 가능합니다.

```python
# -*- coding: utf-8 -*-

from flask import Flask, render_template

app = Flask(__name__)    

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run()
```
###### laptop_rhythm.py

루트 경로 `/`로 템플릿 디렉터리 내부에 있는 `index.html`을 렌더링합니다.

렌더링 하는 파일은 레이아웃을 따로 두어 템플릿 문법을 통해 블록을 나누었습니다.

```html
<!doctype html>
<html>
    <head>
        <title>RHYTHM</title>
        <meta charset="utf-8">
    </head>
    <body>
        {% raw %}{% block body %}{% endblock %}{% endraw %}
    </body>
</html>
```
###### templates/layout.html


```html
{% raw %}{% extends 'layout.html' %}

{% block body %}
{% endblock %}{% endraw %}
```
###### templates/index.html

`layout.html` 파일을 불러온 상태로 렌더링하게 되므로 필요한 부분만 블록으로 나누어 작성한 후 *Flask*를 통해 경로를 지정한 후 렌더링하면 됩니다.

정적 파일을 보관하는 `static/`에 자바스크립트 파일, CSS 파일 또는 XML, CSV 데이터 파일을 보관하였으며 다음과 같은 템플릿 문법을 통해 참조가 가능합니다.

```html
<script src="{% raw %}{{ url_for('static', filename='js/custom.js') }}{% endraw %}"></script>
```
###### templates/layout.html

만약 템플릿 엔진 자체의 문법에 대한 추가적인 정보를 얻으려면 Jinja2 공식 문서인 [Jinja2 Template Documentation](//jinja.pocoo.org/docs/2.9/templates/)을 참고하시기 바랍니다.

#### Flask Context Processor

*Flask*에서는 Python의 함수를 템플릿에서 주입시키기 위해 컨텍스트 프로세서(Context Processor)가 존재합니다.
이는 템플릿이 렌더링되기 전에 실행되는 함수이며 템플릿에서 함수를 사용할 수 있도록 허용합니다.

템플릿 프로세서는 *dictionary* 객체를 반환합니다. 다음과 같이 *closure* 형태로 반환하면 템플릿에서 함수를 사용할 수 있게 됩니다.

```python
@app.context_processor
def data():
    def wrap():
        from evt_proc import EventProc
        return [i for i in EventProc().today_rhythm()]
    return dict(data=wrap)
```
###### laptop_rhythm.py

*Decorator*를 `@app.context_processor`로 지정하면 *dictionary*의 `data` 이름으로 지정된 함수는 컨텍스트 프로세서로 모든 템플릿에서 사용할 수 있습니다.

```javascript
var arcs = d3.pie()
    .sort(null)
    .value(function(d) { return d.delta; })( {% raw %}{{ data() }}{% endraw %} );
```
###### templates/visualization.js

#### Pandas Dataframe

*Pandas* 패키지의 Dataframe 데이터 구조를 통해 Python에서 2차원 데이터를 효과적으로 처리할 수 있습니다.

프로젝트에서 Pandas를 이용하여 다음 세가지를 주로 처리하였습니다.

- Datetime object in Dataframe  
2차원 데이터 구조 Dataframe 내부에서 날짜를 계산할 수 있게 Datetime 객체로 변환하여 각 행에 추가하였습니다.

- Reverse index  
다음과 같은 코드를 통해 최신 행 순서로 이루어진 Dataframe을 반대로 재정렬 할 수 있습니다.
```python
# loop reverse index in dataframe
for index, element in evt_today.iloc[::-1].iterrows():
    pass
```
###### Reverse index order
`iterrows()`는 Generator를 반환하므로 이를 통해 순서를 보장할 수 있습니다.

- Query  
*Pandas* 패키지의 Dataframe 데이터 구조는 연산자 오버로딩 및 배열 내부에서 비교 연산자로 쉽게 데이터를 쿼리할 수 있습니다. 예를 들어  
```python
evt_today = evt_today[evt_today['TimeWritten'] > today]
```
###### Today query
위와 같이 오늘 날짜 이후로 이벤트가 발생한 데이터를 쉽게 쿼리할 수 있습니다.

#### SVG

*D3*는 차트나 맵 라이브러리가 아닙니다. SVG, HTML 또는 Canvas 자체도 아닙니다. 이를 통해 차트나 맵을 만들어 나가는 것입니다.
SVG, Canvas 같은 새로운 추상화 계층은 아니지만 이를 이용하여 원하는 그림을 Javascript로 그리게 해줍니다. 마치 jQuery가 Javascript를 사용하는 것과 비슷하달까요.

그러므로 *D3*를 제대로 이해하기 위해서는 SVG, Canvas 등의 기초적인 원리를 알아야 합니다. 예를 들어 다음과 같은 SVG 코드는

<svg height="100" width="100">
  <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
</svg>
###### Red-circle_Black-stroke.svg

```html
<svg height="100" width="100">
  <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
</svg>
```

*D3*에서 다음과 같이 나타낼 수 있습니다.

```javascript
var svg = d3.select('body')
    .append('svg')
    .attr({
        width: 100,
        height: 100,
    });

svg.append('circle')
    .attr({
        'cx': 50,
        'cy': 50,
        'r': 40,
        'stroke': 'black',
        'stroke-width': 3,
        'fill': 'red'
    });
```

#### D3 Selection

*D3*에서는 Selection 요소를 `d3.select()`와 `d3.selectAll()` 두가지로 나누며 전자는 일치하는 첫 요소만 선택하고, 후자는 일치하는 모든 요소를 document 순서로 선택합니다.

*D3*는 데이터의 구조와 HTML의 DOM Selector를 잇는 다리 역할을 하며 데이터 조인은 Data Enter Exit으로 나누어 데이터를 DOM 요소에 맞게 바인딩 시킬 수 있습니다.

[How Selections Work](//bost.ocks.org/mike/selection/)([한글](//hanmomhanda.github.io/Docs/d3/How-Selections-Work.html))에 아주 자세하게 원리에 대해 설명이 되어있습니다. 참고하시기 바랍니다.

#### D3 Gallery

생각보다 방대한 양의 학습이 필요한 *D3* 라이브러리는 다행히도 Gallery 및 API를 통해 풍부한 예시를 제공하고 있습니다.

제가 하고자 하는 모델은 [Donut Chart](//bl.ocks.org/mbostock/3887193)로 데이터를 Pandas 패키지를 통해 다듬어서 차트에 맞게 연결만 하면 되는 상황이었습니다.

## Tie up

이렇게 데이터를 처리하는 과정을 배워보면서 프로세스를 익혀볼 수 있었습니다.

이 프로젝트는 아직 끝나지 않았고 배터리 사용량과 함께 그려보고 싶은 것이 많습니다.
그만큼 학습량이 많이 요구되지만, 기본적인 내용을 다시 알게 되면서 앞으로 복잡한 데이터 분석 및 시각화도 충분히 해낼 수 있다고 생각합니다.

## Reference

- [about_Execution_Policies](//technet.microsoft.com/ko-KR/library/hh847748.aspx)
- [D3.js 배우는 방법](//mobicon.tistory.com/275)
- [D3 Gallery](//github.com/d3/d3/wiki/Gallery)
- [How Selections Work](//bost.ocks.org/mike/selection/)
- [Flask quick start](//flask.pocoo.org/docs/0.12/quickstart/)
- [Flask templates](//flask.pocoo.org/docs/0.12/templating/)
- [Pandas dataframe](//pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.html)
- [Pandas dataframe query](//pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.query.html)
- [Jinja2 Template Documentation](//jinja.pocoo.org/docs/2.9/templates/)
- Python Cookbook - By David Beazley and Brian K. Jones
- D3 Tips and Tricks - Malcolm Maclean
