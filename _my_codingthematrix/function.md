---
layout: post
title: 함수
---

## 함수

- - -

Coding the Matrix 책에서 설명하는 함수를 공식적으로 설명하는 문장은 다음과 같습니다.

<div class="def">
함수는 쌍 \( (a,b) \) 들의 집합이며, 이때 각 쌍의 첫 번째 원소는 모두 다르다.
</div>

$$ \frac{d}{dx} x^5 = 5x^4 $$
\begin{center}
\psset{unit=0.75cm}
\begin{pspicture}(-4,-3)(4,6)
\uservariable{alpha}(0.1,0){x}
\psplot[algebraic,linewidth=2pt]{-4}{4}{pow(x,5)}
\psplot[algebraic,linecolor=blue,linewidth=3]{-4}{4}{5*(x-alpha)*pow(alpha,4) + pow(alpha,5)}
\psline{->}(-4,0)(4,0)
\end{pspicture}
\end{center}
\begin{center}
\psset{unit=0.75cm}
\begin{pspicture}(-4,-3)(4,6)
\uservariable{alpha}(0.1,0){x}
\psplot[algebraic,linewidth=2pt]{-4}{4}{pow(x,5)}
\psplot[algebraic,linecolor=blue,linewidth=3]{-4}{4}{5*(x-alpha)*pow(alpha,4) + pow(alpha,5)}
\psplot[algebraic,linecolor=green,linewidth=3]{-4}{4}{5*x*x*x*x}
\psplot[plotstyle=dots, plotpoints=1,dotstyle=*,dotsize=10pt]{alpha-.1}{alpha+.1}{5*pow(alpha,4)}
\psline{->}(-4,0)(4,0)
\end{pspicture}
\end{center}
$a^x$ was a narcissist. He always liked to lean ($\ln$) down to see his reflection in the pool
($a$).

$$f(x) = a^x$$
$$f ’(x) = a^x \ln(a)$$
\begin{center}
\psset{unit=0.75cm}
\begin{pspicture}(-4,-3)(4,6)
\uservariable{alpha}(0.1,0){x}
\psplot[algebraic,linewidth=2pt]{-4}{4}{pow(2,x)}
\psplot[algebraic,linecolor=blue,linewidth=3]{-4}{4}{(x-alpha)*pow(2,alpha)*log(2) + pow(2,alpha)}
\psline{->}(-4,0)(4,0)
\end{pspicture}
\end{center}
\begin{center}
\psset{unit=0.75cm}
\begin{pspicture}(-4,-3)(4,6)
\uservariable{alpha}(0.1,0){x}
\psplot[algebraic,linewidth=2pt]{-4}{4}{pow(2,x)}
\psplot[algebraic,linecolor=blue,linewidth=3]{-4}{4}{(x-alpha)*pow(2,alpha)*log(2) + pow(2,alpha)}
\psplot[algebraic,linecolor=green,linewidth=3]{-4}{4}{pow(2,x)*log(2)}
\psplot[plotstyle=dots, plotpoints=1,dotstyle=*,dotsize=10pt]{alpha-.1}{alpha+.1}{log(2)*pow(2,alpha)}
\psline{->}(-4,0)(4,0)
\end{pspicture}
\end{center}
Apollo and Artemis are a famous pair for their moody behaviors in Mt. Olympus and the mortal world, but no one knows the true mystery behind these two. Apollo ($\sin(x)$) is actually Artemis ($\cos(x)$) when he uses the $\frac{d}{dx}$ potion. When he uses the $\frac{d}{dx}$ potion again as Artemis, he becomes the evil Apollo $–\sin(x)$. And when evil Apollo takes it once more, he becomes evil Artemis. Evil Artemis transforms into good Apollo with another boost of the $\frac{d}{dx}$ potion. Thus, this moody behavior of the divine “twins” continues in an endless cycle.
\begin{center}
\psset{unit=0.75cm}
\begin{pspicture}(-10,-6)(10,6)
\uservariable{alpha}(0.1,0){x}
\psplot[algebraic,linewidth=2pt]{-10}{10}{sin(x)}
\psplot[algebraic,linecolor=blue,linewidth=3]{-10}{10}{(cos(alpha))*(x-alpha) + sin(alpha)}
\psplot[algebraic,linecolor=green,linewidth=3]{-10}{10}{cos(x)}
\psplot[plotstyle=dots, plotpoints=1,dotstyle=*,dotsize=10pt]{alpha-.1}{alpha+.1}{cos(alpha)}
\psline{->}(-10,0)(10,0)
\end{pspicture}
\end{center}
