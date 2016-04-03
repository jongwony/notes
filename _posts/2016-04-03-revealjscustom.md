---
title: Reveal.js Customize
layout: post
---

제 프레젠테이션 자료는 대부분 자바스크립트인 Reveal.js를 사용하였습니다.

HTML정도만 해보신 분들이라면 어렵지 않게 접근할 수 있습니다.

- - -

## Reveal.js 설치

[Reveal.js GitHub](//github.com/hakimel/reveal.js)

GitHub가 설치되어 있다면 다음과 같이 프로젝트를 clone합니다.

```
git clone https://github.com/hakimel/reveal.js.git
```

설치 되어있지 않으면 Download ZIP을 클릭하여 압축을 풀어서 할 수 있습니다.

- - -

## Usage

사용법은 위 사이트의 README.md에 자세히 나와있습니다.

[index.html](//lab.hakim.se/reveal-js/)을 수정하여 PPT를 바로 만들 수 있습니다!

```html
<section>
  하나의 슬라이드, 오른쪽 방향으로 슬라이드
</section>

<section>
  <section>
    소주제
  </section>
  <section>
    아래 방향으로 슬라이드
  </section>
</section>  
```

- - -

## Customizing

제가 자주 쓰는 기능은

* PDF Export

* Notes.js

* Search.js

* Zoom.js

* Sketch.js

다섯가지 입니다.

Sketch.js를 제외한 모두가 Reveal.js가 제공하는 기능입니다.

더 많은 기능 또는 자세한 내용은 [Reveal.js GitHub](//github.com/hakimel/reveal.js)의 README.md를 참조하세요.

- - -

## PDF Export

index.html을 프레젠테이션할 자료로 만드셨나요?

이제 PDF 파일로 내보낼 수 있습니다.

index.html을 실행한 주소표시줄의 주소를 다음과 같이 변경합니다.

```
.../reveal.js/index.html?print-pdf
```

그럼 약간 깨져보이는 PPT가 보일 것입니다.

Ctrl + P (Windows) 또는 CMD + P(MAC)를 눌러 인쇄 화면으로 들어갑니다.

배경 그래픽 옵션에 체크하고 저장을 누르면 만든 프레젠테이션 그대로 PDF로 내보낼 수 있습니다.

![pdfexport](/image/pdfexport.png)

<div class="warn">
  파일이 index.html이 아닌 이름으로 저장했을 경우는 동작하지 않습니다. <br>
  PDF Export 한 뒤에 이름을 바꾸면 됩니다.
</div>

- - -

## Notes.js

빔 프로젝터를 사용하여 프레젠테이션 할 경우 Notes.js는 다음 슬라이드를 미리 보여주고

발표 시간 경과도 보여주며 슬라이드 노트를 사용할 수 있습니다.

![notes.js](/image/notesjs.png)

슬라이드 노트 사용법

```html
<aside class="notes">
  notes.js의 화면에만 보이는 노트입니다.
</aside>
```

기본적으로 notes.js는 S키를 눌러 띄울 수 있습니다.

하지만 아래의 Search.js와 충돌할 수 있어서 저는 X키로 변경하였습니다.

reveal.js/plugin/notes/notes.js를 수정합니다.

```js
// Open the notes when the 's' key is hit
document.addEventListener( 'keydown', function( event ) {
  // Disregard the event if the target is editable or a
  // modifier is present
  if ( document.querySelector( ':focus' ) !== null || event.shiftKey || event.altKey || event.ctrlKey || event.metaKey ) return;

  // Disregard the event if keyboard is disabled
  if ( Reveal.getConfig().keyboard === false ) return;

  // X(88) 키로 변경합니다.
  if( event.keyCode === 88 ) {
    event.preventDefault();
    openNotes();
  }
}, false );
```

[Unicode value 확인](//www.w3schools.com/jsref/tryit.asp?filename=tryjsref_event_key_keycode)

- - -

## Search.js

프레젠테이션에서 Q&A 시간은 다들 가지실겁니다.

이전 슬라이드로 돌아갈 경우 대부분 일일이 찾아 돌아가야 합니다.

Reveal.js의 Plugin인 Search.js를 이용하여 단어또는 페이지 번호(슬라이드에 기입한 경우)만으로 해당 슬라이드로 갈 수 있습니다.

reveal.js/plugin/search/search.js를 수정합니다.

```js
// 아래에서 작업한 display:none을 해제
function openSearch() {
  var inputbox = document.getElementById("searchinput");
  var icon = document.getElementById("searchbutton");
  inputbox.style.display = "inline";
  icon.style.display = "inline";
  inputbox.focus();
  inputbox.select();
}

// closeSearch()를 추가하여 검색하지 않을 경우 UI 숨기기
function closeSearch() {
	var inputbox = document.getElementById("searchinput");
	var icon = document.getElementById("searchbutton");
	inputbox.style.display = "none";
	icon.style.display = "none";
}

// Search.js UI의 CSS style에 display:none을 추가하여 기본적으로 보이지 않게 함
searchElement.innerHTML = '<span><input type="search" id="searchinput" class="searchinput" style="vertical-align: top; display: none;"/><img src="......" id="searchbutton" class="searchicon" style="vertical-align: top; margin-top: -1px; display: none;"/></span>';


// 주석을 해제합니다.
document.addEventListener( 'keydown', function( event ) {
  if ( document.querySelector( ':focus' ) !== null || event.shiftKey || event.altKey || event.ctrlKey || event.metaKey ) return;

  // S키를 누르면 검색(기존 S키는 notes.js와 중복됨, notes.js를 바꾸거나 다른 키로 변경합니다.)
  if( event.keyCode === 83) {
    event.preventDefault();
    openSearch();
  }
  else{
    // closeSearch()를 추가하여 검색하지 않을 경우 UI 숨기기
    closeSearch();
  }

}, false );
```

S키를 누르면 검색창이 나타나 검색할 수 있습니다!

- - -

## Zoom.js

Reveal.js에서 기본적으로 alt + 마우스 클릭으로 확대가 가능합니다.

Zoom.js를 다음과 같이 **html 태그 단위로 확대** 가능하도록 변경합니다.

reveal.js/plugin/zoom-js/zoom.js를 수정합니다.

```js
// 주석처리
/*
  zoom.to({
    x: ( bounds.left * revealScale ) - zoomPadding,
    y: ( bounds.top * revealScale ) - zoomPadding,
    width: ( bounds.width * revealScale ) - ( zoomPadding * 5 ),
    height: ( bounds.height * revealScale ) - ( zoomPadding * 5 ),
    pan: false
  });
*/

// 이벤트 타겟을 alt + 클릭으로 확대하도록 변경
zoom.to({
  element: event.target
});
```

- - -

## Sketch.js

이 기능은 Reveal.js에서 지원하는 것이 아니라 Sketch.js와 dazzleSketch.js를 추가하여

PPT 위에 Drawing을 할 수 있게됩니다.

reveal.js/plugin/sketch-js 디렉터리를 만들고

다음 두 파일을 추가합니다.

[dazzleSketch.js](//github.com/csev/dazzleSketch)

[sketch.js](//intridea.github.com/sketch.js/lib/sketch.js)

index.html에서 가장 마지막(/body 태그 위)에 다음을 추가합니다.

```html
<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
<script src="plugin/sketch-js/sketch.js">	</script>
<script src="plugin/sketch-js/dazzleSketch.js"></script>
```

Chrome의 컨트롤 키 기능과 충돌하지 않기 위해 dazzleSketch.js를 다음과 같이 변경합니다.

```js
$(document).keypress(function(event)
{
    //var isSpecialKey = event.shiftKey || event.ctrlKey || event.altKey || event.metaKey;
    var w = event.which;

    // 여기다 원하는 색을 추가하셔도 좋습니다.
    var colors = ['#ff0', '#0f0', '#0ff', '#f00', '#fff', '#00f', '#f0f', '#000'];

    // 사이즈도 조절할 수 있습니다.
    var sizes = [1, 2, 3, 5, 8, 10, 15];

    // event.ctrlKey && 을 모두 제거합니다.
    // 1 ~ 8 color pen
    if ( w >=49 && w < 49+colors.length) {
        var newcolor = colors[w-49];
        $('#sketchCanvas').sketch().set('color', newcolor);
        $('#sketchDiv').css( "zIndex", 2);
    } else if ( w == 96 ) {
        clearSketchCanvas();
        $('#sketchDiv').css( "zIndex", -2);
    } else if ( w == 45 ) { // Minus key
        if ( currentSketchSize > 0 ) {
            currentSketchSize--;
            $('#sketchCanvas').sketch().set('size', sizes[currentSketchSize]);
        }
    } else if ( w == 48 ) { // 0 Background Canvas
        var bgcolor = $('#sketchDiv').css('background-color');
        if ( bgcolor === 'transparent' || bgcolor === 'rgba(0, 0, 0, 0)') {
            $('#sketchDiv').css('background-color','white')
        } else {
            $('#sketchDiv').css('background-color','transparent')
        }
    } else if ( w == 61 ) { // Equals key
        if ( currentSketchSize < sizes.length-1 ) {
            currentSketchSize++;
            $('#sketchCanvas').sketch().set('size', sizes[currentSketchSize]);
        }
    }
});
```

이 작업까지 끝나면 숫자를 눌렀을 때 아래와 같이 Drawing이 가능합니다!

![Sketch.js](/image/sketchjs.png)

모두 멋진 프레젠테이션을 해보시길 바랍니다.
