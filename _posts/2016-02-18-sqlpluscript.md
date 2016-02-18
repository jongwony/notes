---
title: SQL*Plus 콘솔 환경설정
layout: post
---

Oracle 데이터베이스를 이용할 때 주로 SQL Developer를 많이 씁니다.

하지만 따로 설치해야 한다는 단점이 있으며 만약 다른 서버에 설치된 오라클을 다룰 때 해당 서버에 설치가 되지 않은 경우에는 콘솔 환경에서의 최후의 툴 SQL*Plus 만 남게 됩니다.

콘솔 환경에서의 SQL이란 적막하기 그지없습니다.

 ```
 SQL>
 ```

SPOOL이라는 SQL*Plus 명령어는 이 명령을 내린 시점부터 콘솔에 쓰여진 모든 내용을 로그로 저장하는데

명령을 내리는 시각을 알 수 있게 프롬프트를 변경하는 방법이 있습니다.

```sql
SET TIME ON
SET SQLPROMPT "_user> "
```

이를 적용하면 다음과 같이 프롬프트가 변경됩니다.

```
11:24:32 HR>
```

SET 명령어로 변경할 수 있는 파라미터는 다음 명령어로 모두 보실 수 있습니다.

```
SHOW ALL
```

주로 linesize(가로), pagesize(세로)를 자주 변경하게 됩니다.

하지만 매번 접속할 때마다 변경하기 힘들 경우가 있기 때문에 이 때 리눅스의 .bash_profile과 같이 환경변수 처럼 지정할 수 있는 **glogin.sql** 이라는 파일이 있습니다.

이 파일은 보통 $ORACLE_HOME/sqlplus/admin에 위치하며

SQL*Plus 스키마에 접속할 때 한번만 실행됩니다.

콘솔 환경의 설정을 어느정도 해봤지만 각 칼럼은 제어가 힘들 수도 있습니다.

다음과 같은 현상으로 나타날 수 있습니다.

![before_script](/image/database/before_script.png)

이런 경우를 해결하기 위해 간단히 [스크립트](/file/col_resize.sql)를 만들어 보았습니다.

```sql
-- Query clean display
set pagesize 0
set feedback off

-- SPOOL concatenation string in temp file
spool result.sql

-- col department_id format a20
SELECT DISTINCT('col '||COLUMN_NAME||' format a'||DATA_LENGTH) "--"
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME IN (SELECT TABLE_NAME FROM USER_TABLES)
AND DATA_TYPE LIKE 'VARCHAR2';

spool off

-- result.sql read/write access
!chmod -R 770 result.sql

-- append glogin.sql
!cat result.sql >> $ORACLE_HOME/sqlplus/admin/glogin.sql

-- remove temp file
!rm -rf result.sql

!echo $ORACLE_HOME/sqlplus/admin/glogin.sql is UPDATED.
!read -p " Press the Enter key SQL PLUS will be terminated."
!echo -----------------------------------\
!echo -- Please reconnect with SQLPlus.--\
!echo -----------------------------------\

-- session exit
exit
```

<div class="def">

위 스크립트가 저장된 파일을 SQL*Plus가 처음 실행되는 경로로 복사합니다.

!pwd로 확인 할 수 있습니다.

sqlplus로 적용할 세션에 접속한 후
위 스크립트를 실행해 주면 됩니다.

</div>

예를들어 위 스크립트를 col_resize.sql로 저장하여 HR 샘플 스키마에서 적용시켜 본다고 하면

col_resize.sql 파일을 /u01 디렉토리에 저장 후

```
sqlplus hr
11:24:32 HR> @col_resize
```

위 스크립트는 현재 **세션 연결된** 스키마 내에 있는 모든 테이블의 **VARCHAR2** 자료형을 가진 칼럼을 검색해서 그 칼럼이 제한한 길이만큼 사이즈를 조절하는 스크립트입니다.

예를들어 HR스키마에 접속했다면 HR내의 모든 테이블의 VARCHAR2 칼럼의 크기를 조절해서 디스플레이 해주는 것입니다.

스크립트를 실행하면 glogin.sql에 HR의 모든 컬럼들이 등록되고 자동으로 종료됩니다.

<div class="warn">

sqlplus /nolog 로 접속할 때는 실행되지 않습니다.

위 스크립트는 SPOOL작업을 한 쿼리결과를 단순히 glogin.sql에 APPEND 작업만 한 것입니다. 중복실행에 유의하세요.

</div>

어디까지나 개인 콘솔의 환경설정입니다.

주석을 첨부했으니 자신의 환경에 맞게 바꾸어 사용하시기 바랍니다.
