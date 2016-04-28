rem
rem	Script:		join_card_07.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	What happens when you include predicates
rem	like:  join_column = constant
rem

start setenv
set timing off

define t1j1 = 30
define t1j2 = 50

define t2j1 = 40
define t2j2 = 40

execute dbms_random.seed(0)

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
	trunc(dbms_random.value(0, &t1j1 ))	join1,
	trunc(dbms_random.value(0, &t1j2 ))	join2,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where 
	rownum <= 10000
;


create table t2
as
select
	trunc(dbms_random.value(0, &t2j1 ))	join1,
	trunc(dbms_random.value(0, &t2j2 ))	join2,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;

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


spool join_card_07

rem	alter session set events '10053 trace name context forever';
set autotrace traceonly explain

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t1.join1 = 20
and	t2.join1 = t1.join1
and	t2.join2 = t1.join2
-- and	t2.join1 = 20
;


alter session set events '10053 trace name context off';
set autotrace off

spool off

rem	exit


set doc off
doc


Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=115 Card=1667 Bytes=56678)
   1    0   HASH JOIN (Cost=115 Card=1667 Bytes=56678)
   2    1     TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=57 Card=250 Bytes=4250)
   3    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=57 Card=333 Bytes=5661)


Execution Plan (9.2.0.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=57 Card=1667 Bytes=56678)
   1    0   HASH JOIN (Cost=57 Card=1667 Bytes=56678)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=250 Bytes=4250)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=333 Bytes=5661)


Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=53 Card=1670 Bytes=56780)
   1    0   HASH JOIN (Cost=53 Card=1670 Bytes=56780)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=250 Bytes=4250)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=334 Bytes=5678)
#
