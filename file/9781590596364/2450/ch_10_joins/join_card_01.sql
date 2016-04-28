rem
rem	Script:		join_card_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
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
	trunc(dbms_random.value(0, &t1f0 ))	filter,
	trunc(dbms_random.value(0, &t1j1 ))	join1,
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
	trunc(dbms_random.value(0, &t2f0 ))	filter,
	trunc(dbms_random.value(0, &t2j1 ))	join1,
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


spool join_card_01

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

prompt	Join condition: t2.join1 = t1.join1

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t1.filter = 1
and	t2.join1 = t1.join1
and	t2.filter = 1
;

prompt	Join condition: t2.join1 > t1.join1

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t1.filter = 1
and	t2.join1 > t1.join1
and	t2.filter = 1
;

prompt	Join condition: t2.join1 between t1.join1 - 1 and t1.join1 + 1

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t1.filter = 1
and	t2.join1 between t1.join1 - 1 and t1.join1 + 1
and	t2.filter = 1
;


alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit


set doc off
doc


Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=113 Card=2000 Bytes=68000)
   1    0   HASH JOIN (Cost=113 Card=2000 Bytes=68000)
   2    1     TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=56 Card=200 Bytes=3400)
   3    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=56 Card=400 Bytes=6800)


Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=57 Card=2000 Bytes=68000)
   1    0   HASH JOIN (Cost=57 Card=2000 Bytes=68000)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=200 Bytes=3400)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=400 Bytes=6800)


Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=53 Card=2000 Bytes=68000)
   1    0   HASH JOIN (Cost=53 Card=2000 Bytes=68000)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=200 Bytes=3400)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=400 Bytes=6800)

=================================================================


The following plans are unchanged (in cardinality) whether you
run 8i, 9i, or 10g.

If you change the join predicate to 
	t2.join1 > t1.join1

Note that the cardinality has doubled - the selectivity of 1/40 
(from the t2.join1 end of the join) has been replaced by 1 flat
5% (1/20).

Note, in passing, that the join can no longer be a hash join - 
hash joins can work ONLY for col1 = col2, they cannot work for 
range-based joins.

Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=60 Card=4000 Bytes=136000)
   1    0   MERGE JOIN (Cost=60 Card=4000 Bytes=136000)
   2    1     SORT (JOIN) (Cost=30 Card=200 Bytes=3400)
   3    2       TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=200 Bytes=3400)
   4    1     SORT (JOIN) (Cost=31 Card=400 Bytes=6800)
   5    4       TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=400 Bytes=6800)


If we further modify the join predicate to
	t2.join1 between t1.join1 - 1 and t1.join1 + 1

We have (in effect) two disjoint predicates on a single column)
	t2.join1 >= t1.join1 - 1 
and	t2.join1 <= t1.join1 + 1
The selectivity becomes 1/20 * 1/20 = 1/400 (0.0025)

Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=60 Card=200 Bytes=6800)
   1    0   MERGE JOIN (Cost=60 Card=200 Bytes=6800)
   2    1     SORT (JOIN) (Cost=30 Card=200 Bytes=3400)
   3    2       TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=200 Bytes=3400)
   4    1     FILTER
   5    4       SORT (JOIN)
   6    5         TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=400 Bytes=6800)	



#
