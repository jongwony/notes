---
title: 애니메이션을 웹으로!
layout: post
---

<script language="javascript" type="text/javascript">

function front(obj){
  obj.style.height = obj.style.width*3/7 + 'px';
}

</script>

<iframe onload="front(this)" style="height:20%" src="//www.youtube.com/embed/8SoKASkCuuw" frameborder="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen=""></iframe>

<span style="text-align:center;">[Tutorial](//www.animatron.com/tutorial)</span>

웹으로 애니메이션을 만들 수 있습니다!

gif파일과 video파일로(무료의 경우 400px, 10fps, 10초 제한, 워터마크의 조건)

만들 수 있고 결제를 하면 HTML소스로도 export가능하다고 합니다.

<small>(그냥 만드는 과정을 반디캠 같은걸로 찍으면 될 거 같은데...)</small>

쓰기 나름이겠죠?

- - -

[Java script와 CSS를 링크로 import !](//cdnjs.com)

<small>저는 [시원]이라 부르는 사이트입니다.</small>

CSS 샘플과 여러 Java script 기능을 단순히 링크로 import하여 사용할 수 있습니다.

제가 쓴 제목 태그 애니메이션은 rubberBand클래스를 적용한 것입니다.

```html
<!--animation-->
<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/animate.css/3.5.1/animate.css">

<!--apply example-->
<h1 class="animated infinite tada">Hello!</h1>
```
<br>

<h1 style="text-align:center;" class="animated infinite tada">Hello!</h1>
