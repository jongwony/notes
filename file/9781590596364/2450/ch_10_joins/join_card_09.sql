rem
rem	Script:		join_card_09.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	From 9i onwards, the full explain plan will show
rem	that 'column is not null' is added for all the
rem	places where the SQL shows a join. This has some
rem	slightly quirky side effects - the second example
rem	should (intuitively) give the same cardinality as
rem	the first, but doesn't because table t2 has the
rem	predicates:
rem		    n1 is not null
rem		and n2 is not null
rem	as filter predicates. And the usual 'all columns 
rem	are independent' calculation applies.
rem

start setenv
set timing off

execute dbms_random.seed(0)


drop table t3;
drop table t2;
drop table t1;

begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
end;
/


begin
	execute immediate 'execute dbms_stats.delete_system_stats';
exception
	when others then null;
end;
/


create table t1
as
select
	mod(rownum-1,10)	n1,
	mod(rownum-1,10)	n2,
	lpad(rownum,10)		v1,
	rpad('x',100)		padding
from
	all_objects
where 
	rownum <= 100
;

create table t2
as
select
	mod(rownum-1,12)	n1,
	mod(rownum-1,12)	n2,
	lpad(rownum,10)		v1,
	rpad('x',100)		padding
from
	all_objects
where 
	rownum <= 120
;


create table t3
as
select
	mod(rownum-1,15)	n1,
	mod(rownum-1,15)	n2,
	lpad(rownum,10)		v1,
	rpad('x',100)		padding
from
	all_objects
where 
	rownum <= 150
;

update t1 set n1 = null, n2 = null where n1 = 0;
update t2 set n1 = null, n2 = null where n1 = 0;
update t3 set n1 = null, n2 = null where n1 = 0;

commit;

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		't3',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool join_card_09

set autotrace traceonly explain

alter session set events '10053 trace name context forever';

select	
	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.n1 = t1.n1
and	t3.n1 = t2.n1
;

select	
	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.n1 = t1.n1
and	t3.n2 = t2.n2
;


alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit

set doc off
doc

Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=8 Card=9000 Bytes=378000)
   1    0   HASH JOIN (Cost=8 Card=9000 Bytes=378000)
   2    1     TABLE ACCESS (FULL) OF 'T3' (TABLE) (Cost=2 Card=140 Bytes=1960)
   3    1     HASH JOIN (Cost=5 Card=900 Bytes=25200)
   4    3       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=2 Card=90 Bytes=1260)
   5    3       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=2 Card=110 Bytes=1540)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=8 Card=8250 Bytes=371250)
   1    0   HASH JOIN (Cost=8 Card=8250 Bytes=371250)
   2    1     TABLE ACCESS (FULL) OF 'T3' (TABLE) (Cost=2 Card=140 Bytes=1960)
   3    1     HASH JOIN (Cost=5 Card=825 Bytes=25575)
   4    3       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=2 Card=90 Bytes=1260)
   5    3       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=2 Card=101 Bytes=1717)



Execution Plans (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=8 Card=9000 Bytes=378000)
   1    0   HASH JOIN (Cost=8 Card=9000 Bytes=378000)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=2 Card=140 Bytes=1960)
   3    1     HASH JOIN (Cost=5 Card=900 Bytes=25200)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=90 Bytes=1260)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=2 Card=110 Bytes=1540)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=8 Card=8250 Bytes=371250)
   1    0   HASH JOIN (Cost=8 Card=8250 Bytes=371250)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=2 Card=140 Bytes=1960)
   3    1     HASH JOIN (Cost=5 Card=825 Bytes=25575)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=90 Bytes=1260)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=2 Card=101 Bytes=1717)


Execution plan from dbms_xplan (9.2.0.6)
NOTE in particular the 'column is not null' filters.

--------------------------------------------------------------------
| Id  | Operation            |  Name       | Rows  | Bytes | Cost  |
--------------------------------------------------------------------
|   0 | SELECT STATEMENT     |             |  9000 |   369K|     8 |
|*  1 |  HASH JOIN           |             |  9000 |   369K|     8 |
|*  2 |   TABLE ACCESS FULL  | T3          |   140 |  1960 |     2 |
|*  3 |   HASH JOIN          |             |   900 | 25200 |     5 |
|*  4 |    TABLE ACCESS FULL | T1          |    90 |  1260 |     2 |
|*  5 |    TABLE ACCESS FULL | T2          |   110 |  1540 |     2 |
--------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("T3"."N1"="T2"."N1")
   2 - filter("T3"."N1" IS NOT NULL)
   3 - access("T2"."N1"="T1"."N1")
   4 - filter("T1"."N1" IS NOT NULL)
   5 - filter("T2"."N1" IS NOT NULL)




Execution Plans (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=5 Card=8250 Bytes=346500)
   1    0   HASH JOIN (Cost=5 Card=8250 Bytes=346500)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=1 Card=150 Bytes=2100)
   3    1     HASH JOIN (Cost=3 Card=900 Bytes=25200)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=1 Card=100 Bytes=1400)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=1 Card=120 Bytes=1680)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=5 Card=8250 Bytes=371250)
   1    0   HASH JOIN (Cost=5 Card=8250 Bytes=371250)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=1 Card=150 Bytes=2100)
   3    1     HASH JOIN (Cost=3 Card=900 Bytes=27900)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=1 Card=100 Bytes=1400)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=1 Card=120 Bytes=2040)


#
