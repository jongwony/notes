rem
rem	Script:		join_card_10.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	If we have extreme differences in the number
rem	(or possibly range) of values for two columns
rem	to be joined, we can get some strange results
rem	that still need to be explained.
rem
rem	One feature that makes things difficult is the
rem	rule about: if there is a filter on just one end
rem	of the join, then the predicates from the other
rem	end apply.
rem
rem	Then various other rules about multi-column selectivities
rem	and index selectivities could have an impact.
rem
rem	Then there are various options regarding predicates on
rem	columns with a small number of distinct values, and 
rem	predicates where values can go out of range. 
rem

start setenv
set timing off

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
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
select
	/*+ ordered use_nl(v2) */
	trunc(dbms_random.value(0,  100 ))		filter,
	trunc(dbms_random.value(0,   30 ))		join1,
	trunc(dbms_random.value(0,   20 ))		join2,
	lpad(rownum,10)					v1,
	rpad('x',100)					padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
;


create table t2
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
select
	/*+ ordered use_nl(v2) */
	trunc(dbms_random.value(0,  100 ))		filter,
	trunc(dbms_random.value(0, 4000 ))		join1,
	trunc(dbms_random.value(0,   50 ))		join2,
	lpad(rownum,10)					v1,
	rpad('x',100)					padding
from
	generator	v1,
	generator	v2
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


spool join_card_10

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever, level 1';

select
	t1.v1, t2.v1
from
	t1, t2
where
	t2.join1 = t1.join1
and	t2.join2 = t1.join2
and	t1.filter = 10
-- and	t2.filter = 10
;

select
	t1.v1, t2.v1
from
	t1, t2
where
	t2.join1 = t1.join1
and	t2.join2 = t1.join2
-- and	t1.filter = 10
and	t2.filter = 10
;

alter session set events '10053 trace name context off';

set autotrace off

spool off

set doc off
doc

Execution Plan (9.2.0.6 autotrace. Filter on t1)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=CHOOSE (Cost=57 Card=7 Bytes=266)
   1    0   HASH JOIN (Cost=57 Card=7 Bytes=266)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=100 Bytes=2000)
   3    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=10000 Bytes=180000)


Execution Plan (9.2.0.6 autotrace. Filter on t2)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=CHOOSE (Cost=57 Card=500 Bytes=19000)
   1    0   HASH JOIN (Cost=57 Card=500 Bytes=19000)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=100 Bytes=2100)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=10000 Bytes=170000)


#
