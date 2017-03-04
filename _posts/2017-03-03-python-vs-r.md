---
layout: post
title: R vs Python
tags: ['python', 'r', 'comparison']
---

## Introduce

데이터로부터 의미 있는 정보를 추출하는 기술이 빅데이터 및 머신러닝이 부각되면서 매우 주목받고 있습니다. 빅데이터를 다루면서 분석할 데이터의 양이 매우 커지고, 데이터의 입출력 속도가 빨라졌을 뿐 아니라 종류가 다양해져 기존보다 데이터를 분석하는 기술이 더 중요해 졌습니다.

데이터의 양(Velocity), 데이터 입출력의 속도(Velocity), 데이터 종류의 다양성(Variety) 이 세개의 차원을 통틀어 빅데이터를 정의합니다(진실성 및 가변성이 추가되기도 합니다).
분석에는 다양한 프로그래밍 언어가 사용되는데 그 중 Python과 R이 주목을 받고있습니다. 그렇다면 어떤 언어를 선택하는 것이 좋을까요?
아래에 장단점 및 특징을 분석해 보았습니다.

## Pros and Cons

| Category | R | Python |  
|:---:|:---|:---|  
| **Version** | 3.3.2<br>(2016-10-31) | 3.6.0/2.7.10<br>(2016-12-23/2010-07-03) |  
| **목적** | 사용자 친숙성 | 생산성 및 코드 가독성 |
| **사례** | 통계, 연구 및 데이터 분석 | 공학, 개발 |  
| **Community** | Researchers, Data scientists, Statisticians, Quants | Developers, Programmers |  
| **유용성** | 단 몇 줄만으로 통계 모델 작성<br>스타일시트 추가 가능<br>동일한 기능을 여러 방법으로 작성 | 문법(indentation)에 의한 코딩 및 디버깅이 쉬운 편<br>어떠한 기능도 같은 방법으로 작성 |  
| **적응성** | 복잡한 수식을 쉽게 사용가능 | 다른 애플리케이션 및 웹 사이트에도 적용 |  
| **학습** | 쉽게 고급 요소를 배울 수 있음<br>프로그래밍의 경험이 있기만 하면 어렵지 않음 | 비교적 학습 속도는 느림<br>프로그래밍을 처음 배우기에 적합한 언어 |  
| **Repository** | **CRAN** | **PyPi** |  
| **Library** | Data: `dplyr`, `plyr`, `data.table`<br>String: `stringr`<br>Time series: `zoo`<br>Machine learning: `caret` | Data: `pandas`<br>Scientific computing: `SciPy`, `NumPy`<br>Machine learning: `sckikit-learn`, `TensorFlow`<br>Graphic: `matplotlib`, `seaborn`<br>Statistical: `statsmodels`|  
| **IDE** | [RStudio](//www.rstudio.com/) | IPython Notebook, [PyCharm](//www.jetbrains.com/pycharm/) ... |  
| **Miscellaneous** | rPython: Python → R | RPy2: R → Python |  
| **Help** | StackOverflow, Rdocumentation, examples(), help()<br>Mailing list: R-help | StackOverflow, help()<br>Mailing list: pydata, pystatsmodels, numpy-discussion, sci-py user |

## Hello Data!

분석의 방법은 여러가지가 있지만 가장 기본적으로 배우는 그래픽을 이용한 가시적인 분석의 간단한 예제를 다루어 보겠습니다. 가시적인 자료의 분석만으로는 R이 Python보다 적합하기 때문에 이 예제에서는 장점이 R에 치우친 느낌이 날 수 있습니다.

일단 기본적으로 자료구조와 그래픽 요소로 나뉩니다.

#### R

R은 뚜렷한 명시적인 데이터 타입이 없습니다. 함수 `c`로 이루어진 벡터들이 자료구조의 기본이 되며 변수를 보통 `<-` 연산자로 할당합니다.
`=` 대입 연산자도 동작합니다. 이는 R 언어의 동일한 기능을 여러 방법으로 작성한다는 특징입니다.

R에서는 그래픽을 표시하기 위한 장치를 나눕니다. `plot`과 관련된 함수를 호출할 경우 그래픽 장치가 자동으로 런칭됩니다.

R에서는 다양한 예제를 `example` 키워드로 소개하고 있습니다. 많은 예제를 여기서 확인하실 수 있습니다.

```r
example("points")
```

#### Python

Python이 데이터 분석 분야에서 주목 받는 이유는 여러가지가 있지만 pandas 라이브러리의 역할이 큰 것 같습니다.

Python에서 데이터 분석을 위해 데이터 구조로 pandas, 그래픽으로 matplotlib 기반인 seaborn을 많이 사용합니다.

pandas는 데이터 구조에 가까운 라이브러리이며 1차원 데이터를 다루는데 효과적인 `Series`와 2차원 데이터를 다루는데 효과적인 `DataFrame`이 있습니다.

출력을 해보면 R과 비슷한 데이터 구조가 되는 것을 알 수 있습니다.

그래픽으로는 seaborn의 plotting이 R의 ggplot과 비슷한 편입니다.

아래 사이트에 대표적인 예제가 소개되어 있습니다.

[Using Seaborn To Visualize A Pandas Dataframe](//chrisalbon.com/python/pandas_with_seaborn.html)

## Winner?

어느 언어가 더 좋은지 단정하기는 어렵습니다.
다만 고려해야 할 요소들로 결정을 내리는데 도움을 줄 수는 있겠습니다.

1. 문제가 정확히 무엇인가요?  
통계적인 분석을 하려면 R이 적합하며 무언가 만들어 내려면 Python이 적합합니다.

1. 언어를 어느 정도 기간으로 배울 생각인가요?  
Python 보다는 R이 배우는 속도는 빠릅니다. 하지만 프로그래밍의 경험이 있다면 Python이 적합한 것 같습니다.

1. 주로 사용하는 도구가 무엇이며 위 언어들과 어느 정도 연관되나요?  

## Reference

[Should you teach Python or R for data science?](//www.dataschool.io/python-or-r-for-data-science/)  
[Choosing R or Python for data analysis? An infographic](//www.datacamp.com/community/tutorials/r-or-python-for-data-analysis#gs.FhKPRRw)  
[An Introduction to R](//cran.r-project.org/doc/manuals/R-intro.html)  
[pandas 0.19.2 documentation](//pandas.pydata.org/pandas-docs/stable/visualization.html)
[Using Seaborn To Visualize A Pandas Dataframe](//chrisalbon.com/python/pandas_with_seaborn.html)