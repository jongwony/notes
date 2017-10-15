---
layout: post
title: AWS Route 53로 GitHub Page 도메인 설정
tags: ['AWS', 'Route 53', 'Github Page']
---

<div class='warn'>
기존 도메인 주소가 있어야 합니다.
</div>

---

## GitHub Pages

GitHub 페이지를 최근까지 방치하고 있다가 예전에 도메인을 연결한 적이 있었는데 다음과 같은 메일을 GitHub로 부터 받은 적이 있습니다.

![github_warning](/image/aws/github_warning.png)

제가 예전에 어떻게(?) GitHub Page를 관리하는 서버의 IP 주소를 알게 되어서 A 레코드를 연결했는지는 모르겠지만 GitHub에서 권장하는 방법대로 CNAME을 제대로 설정하는 방법을 포스팅하게 되었습니다.

기존 명령어를 입력해보니 다음과 같이 순수 A 레코드로 이루어진 연결을 하고 있었습니다.

![a_record](/image/aws/a_record.png)

GitHub Page 프로젝트 이름을 아이디로 설정하여 `<GitHub ID>.github.io`로 설정하는 방법이 있고 저의 경우 `notes`라는 프로젝트에서 CNAME으로 Redirect하는 방법이 있습니다.

![github_pages](/image/aws/github_pages.png)

정리하자면

<div class='center'>

GitHub에서 notes 프로젝트 생성
<br><br>
↓
<br><br>
lastone9182.github.io/notes로 GitHub Page가 설정됨
<br><br>
↓
<br><br>
Custom 주소를 notes.jongwony.com으로 설정
<br><br>
↓
<br><br>
GitHub가 알아서 CNAME 파일을 생성해 줌

</div>

호스트 이름이 정확하게 매치되는 경우 정상적인 결과는 아래와 같습니다.

![cname](/image/aws/cname.png)


## Route 53 Hosting

저는 AWS Route 53을 이용해서 도메인을 연결하였습니다.

AWS쪽에서 설명이 잘 되어있어 아래 Reference를 참고하시는 것이 좋을 것 같습니다.


## Reference

- [OpenTutorials](//opentutorials.org/course/608/3012)
- [Setting up a custom subdomain](//help.github.com/articles/setting-up-a-custom-subdomain/)
- [Custom domain redirects for GitHub Pages sites](//help.github.com/articles/custom-domain-redirects-for-github-pages-sites/)
- [Amazon Route 53을 사용해 도메인 이름 등록하기](//docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/registrar.html)