## SQLite bug

SQLite에서  `INTEGER` 와 `PRIMARY KEY`를 혼합한 컬럼을 구성하게 되면 해당 컬럼에 데이터를 `INSERT`할 경우 제멋대로 값이 바뀌는 현상이 나타납니다.

예를 들어 다음과 같은 형식의 테이블 들을 구성하게 되면

```sql
CREATE TABLE t(x INTEGER PRIMARY KEY, y, z);
CREATE TABLE t(x INTEGER PRIMARY KEY ASC, y, z);
CREATE TABLE t(x INTEGER, y, z, PRIMARY KEY(x ASC));
CREATE TABLE t(x INTEGER, y, z, PRIMARY KEY(x DESC));
```

예외로 `ROWID`가 나타나지 않는 선언문은 다음과 같습니다.

```sql
CREATE TABLE t(x INTEGER PRIMARY KEY DESC, y, z)
```

예외를 제외하고 `x` 컬럼의 값에 데이터를 `INSERT` 할 경우 본래 값이 아닌 이상한 값이 나타납니다.

이 값은 실제로 `ROWID`이며 SQLite 공식 홈페이지에서 초기 버전의 버그이며 버그를 수정할 경우 이전 버전과 호환 되지 않을 수 있고 호환성을 깨기 보다 기존 동작이 우수하기 때문에 유지되고 문서화 되었다고 합니다.

- [ROWIDs and the INTEGER PRIMARY KEY](https://sqlite.org/lang_createtable.html) 항목 참조.

SQLite 3.8.2 이후 버전부터 `WITHOUT ROWID`를 사용하여 **ROWID 테이블**이라 불리는 것을 생성할 수 있습니다. B-Tree 구조로 저장되어 속도는 빠르지만 기존 버전과 호환되지는 않습니다.

위 버그는 `INTEGER` 타입에서만 발생하므로 `INT`, `BIGINT`, `SHORT INTEGER`, `UNSIGNED INTEGER`등 다른 타입을 설정하는 것이 좋습니다.

다음과 같은 복수 키에 대한 `PRIMARY KEY` 도 버그가 적용되지는 않습니다.

```sql
CREATE TABLE t(x INTEGER y INTEGER, z, CONSTRAINT xy PRIMARY KEY (x, y));
```