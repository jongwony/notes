---
layout: post
title: Data Visualization
tags: ['python', 'pandas', 'flask', 'd3.js']
---

데이터가 끊임없이 변화하고 방대해지면서 데이터를 잘 분석하고, 표현하는 것이 중요해지고 있습니다.

데이터를 분석하는 이유는 가치를 창출하는 등 여러가지 이유가 있지만 특히 **의사소통을 위해서**라고 생각합니다.  
어떠한 데이터를 분석할 것인지 기획이 필요하며 데이터를 담고, 추출하고, 원하는 데이터를 쿼리를 통해 다듬는 분석 과정으로 다른 사람에게 직관적으로 빠른 이해를 돕기 위해 시각화를 합니다.

그림으로 나타내면 다음과 같습니다.

![workflow](/image/dataworkflow.gif)  
###### Image: [https://www.promptcloud.com/next-generation-of-data-mining/](//www.promptcloud.com/next-generation-of-data-mining/)

우선 데이터를 추출하여 데이터베이스에 저장합니다.
그런 다음 데이터베이스로 부터 데이터를 가져와야 합니다.
그 후 일련의 처리 작업을 통해 데이터를 다듬고, 시각화를 합니다.

위의 프로세스를 통해 간단한 프로젝트를 만들어 보았습니다.

[laptop_rhythm](//github.com/lastone9182/laptop_rhythm) 프로젝트는 로그온, 로그오프, 절전 시간 등을 분석하여 하루 동안 컴퓨터가 켜져 있는 시간을 웹페이지를 통해 시각화하는 간단한 프로젝트입니다.

![laptop_rhythm](/image/laptop_rhythm.png)

분석보다는 시각화에 중점을 두었기 때문에 데이터 탐색(Exploratory)에 가까울 수 있습니다.

## Process

Python 라이브러리를 통해 로그온 및 절전 시간 데이터를 추출하고 sqlite로 저장하는 방법이 있습니다.  
하지만 OS와 어느정도 연관된 부분이라 각 OS마다 구현이 다를 것으로 예상해서 각 환경에 맞게 스크립트로 데이터를 먼저 추출하는 것을 생각하였습니다.
제 환경은 Windows이므로 *Powershell* 스크립트를 통해 데이터를 XML 또는 CSV로 추출합니다.

데이터 분석은 Python의 *pandas* 패키지를 통해 웹페이지로 시각화를 하겠습니다.  
*Flask* 패키지가 이 중간 역할을 할 것입니다.

데이터 시각화도 Python 패키지를 통해 하는 방법이 있지만, Flask가 서버 웹 애플리케이션임을 감안하여 데이터 시각화는 Javascript를 통해 클라이언트에서 동적으로 생성하도록 하였습니다.

Javascript에서 chart.js, highcharts 등 데이터 시각화를 위한 여러 라이브러리를 제공합니다. 그 중 `svg`, `canvas`를 통해 데이터를 시각화하는 *D3* 라이브러리를 통해 시각화를 시도해 보았습니다.

여기까지 과정을 그림으로 표현하면 아래와 같습니다.

![Process](/image/laptop_rhythm_process.png)

그러면 필요한 구성요소를 먼저 설치하는 것 부터 시작해보겠습니다.

## Installation

#### Powershell

#### Virtualenv

#### Flask

#### Pandas

#### D3

## Background

#### Windows Event File

#### Context Processor

#### Pandas Dataframe

- reverse index

#### SVG

#### D3 Selection

#### D3 Gallery

## Reference



Laptop rhythm
Trace Laptop Logon, Logoff, Hibernation, Sleep time.

Draw rhythm chart & Battery report.

Windows only

How Works:

Filtering event log file(.evt)

Package

virtualenv
flask
pandas
d3.js
Usage

You must ensure Get-ExecutionPolicy is not Restricted. We suggest using Bypass to bypass the policy to get things installed or AllSigned for quite a bit more security.

Set policy

Set-ExecutionPolicy -ExecutionPolicy BYPASS
Virtualenv

Python 3.6, pip 9.0.1

virtualenv name: _rhythm

pip install virtualenv

virtualenv _rhythm
Install flask, pandas package.

pip install pandas, flask
Run script

.\laptop_rhythm.ps1



Reference

windows event file
D3.js 배우는 방법
D3 Gallery
Flask templates
Pandas dataframe
svg


TODO List

static/battery_rhythm.xml file analyze
Specify history time(today yet)

