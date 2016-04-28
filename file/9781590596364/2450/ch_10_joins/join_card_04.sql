rem
rem	Script:		join_card_04.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	We forget about filter columns for the moment,
rem	and consider a two-column join predicate with
rem	a conjunct (AND).
rem

start setenv

define t1j1 = 30
define t1j2 = 50

define t2j1 = 40
define t2j2 = 40

execute dbms_random.seed(0)

drop table t2;
drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'begin dbms_stats.delete_system_stats; end;';
	exception 	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;

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


spool join_card_04

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
and	t2.join2 = t1.join2
;


alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit


set doc off
doc


In this case, 10.1.0.3 introduces a 'sanity check', 
reporting in the 10052 trace:
	Using multi-column join key sanity check for table T2
	Revised join selectivity: 6.2500e-004 = 5.0000e-004 * (1/1600) * (1/5.0000e-004)
	Join Card:  62500.00 = outer (10000.00) * inner (10000.00) * sel (6.2500e-004)

This has basically cancelled the current selectivity, and replaced
it with the selectivity from just 'one side' of the join.
We had:
		t1	t2
	join1	30	40
	join2	50	40

In earlier versions of Oracle, we use:
	join1 ... 1/40 (t2)
	join2 ... 1/50 (t1) 
for a net effect of 1/2000

In this version we also check:
	t1 only ... 1/30 * 1/50 = 1/1500
	t2 only ... 1/40 * 1/40 = 1/1600
and choose the smaller value

Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=118 Card=62500 Bytes=2125000)
   1    0   HASH JOIN (Cost=118 Card=62500 Bytes=2125000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=53 Card=10000 Bytes=170000)
   3    1     TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=170000)


Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=60 Card=50000 Bytes=1700000)
   1    0   HASH JOIN (Cost=60 Card=50000 Bytes=1700000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=10000 Bytes=170000)
   3    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=10000 Bytes=170000)


Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=60 Card=50000 Bytes=1700000)
   1    0   HASH JOIN (Cost=60 Card=50000 Bytes=1700000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=10000 Bytes=170000)
   3    1     TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=10000 Bytes=170000)


#
