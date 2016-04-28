rem
rem	Script:		join_card_02a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Change the simple example to include a significant
rem	number of nulls (more than 5%) on the join columns
rem
rem	Note how the 9i and 10g plans have filtered out
rem	the null rows in the tablescan lines (190 and 380 rows)
rem	whereas 8i has not (200 and 400 rows)
rem
rem	For a two-table join, this doesn't make any difference
rem	to the end result - but (see join_card_09.sql) the
rem	strategy does make a difference on a three-table join.
rem
rem	I have not yet worked out why this method isn't applied
rem	across the board, rather than depending on the 5% limit.
rem

start setenv
set timing off

define t1f0 = 25
define t1j1 = 30

define t2f0 = 50
define t2j1 = 40

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
	trunc(dbms_random.value(0, &t1f0 ))	filter,
	trunc(dbms_random.value(0, &t1j1 ))	join1,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where 
	rownum <= 10000
;

rem
rem	Null out 501 rows (one more than 5% of 10,000)
rem

update t1 set join1 = null
where mod(to_number(v1),7) = 1
and rownum <= 501;

commit;


create table t2
as
select
	trunc(dbms_random.value(0, &t2f0 ))	filter,
	trunc(dbms_random.value(0, &t2j1 ))	join1,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;

rem
rem	Null out 501 rows (one more than 5% of 10,000)
rem

update t2 set join1 = null
where mod(to_number(v1),7) = 5
and rownum <= 501;
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


spool join_card_02a

rem	alter session set events '10053 trace name context forever';

set autotrace traceonly explain

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
and	t1.filter = 1
and	t2.filter = 1
;


set autotrace off

alter session set events '10053 trace name context off';

spool off

rem	exit


set doc off
doc


Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=115 Card=1805 Bytes=61370)
   1    0   HASH JOIN (Cost=115 Card=1805 Bytes=61370)
   2    1     TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=57 Card=190 Bytes=3230)
   3    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=57 Card=380 Bytes=6460)


Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=57 Card=1805 Bytes=61370)
   1    0   HASH JOIN (Cost=57 Card=1805 Bytes=61370)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=190 Bytes=3230)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=380 Bytes=6460)


Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=53 Card=1805 Bytes=61370)
   1    0   HASH JOIN (Cost=53 Card=1805 Bytes=61370)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=200 Bytes=3400)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=400 Bytes=6800)


#
