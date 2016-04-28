rem
rem	Script:		trans_close_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	A commoner example of transitive closure.
rem
rem	The predicate on t1 can also be applied to t2 because of 
rem	the join condition. But as the constant predicate is 
rem	created on t2, the join predicate is eliminated, and 
rem	the join becomes a cartesian join - which is given a hugely
rem	exaggerated cost.
rem
rem	Again, if you change query_rewrite_enabled to true, the
rem	join predicate is not eliminated, and in this case the 
rem	execution plan for the first query changes (to match 
rem	the plan of the second query).
rem

	
start setenv
set feedback off

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
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
	rpad('x',100)		padding
from
	all_objects
where
	rownum <= 1000
;


create table t2
as
select
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
	rpad('x',100)		padding
from
	all_objects
where
	rownum <= 1000
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

spool trans_close_02

rem	alter session set query_rewrite_enabled = true;
set autotrace traceonly explain

prompt
prompt	With transitive closure the cost is huge even
prompt	though the cardinality of 10,000 is correct
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1
;

prompt
prompt	Duplicate the JOIN clause so that one copy
prompt	of it 'survives' the closure. But the 
prompt	cardinality is wrong
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1
and	t2.n1 = t1.n1
;

prompt
prompt	Create the predicate that would have been
prompt	generated, and closure does not take place
prompt	But the cardinality is wrong.
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1
and	t2.n1 = 5
;

prompt
prompt	Use a method that Oracle can't do transitive
prompt	closure on and suddenly everything looks good
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1 + 0
;

set autotrace off

spool off

set doc off
doc

Execution plans for the first query:
====================================
The same effect appears for 9i but NOT for 10g

Execution Plan (8.1.7.4 - query_rewrite_enabled = false)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=303 Card=1 Bytes=6)
   1    0   SORT (AGGREGATE)
   2    1     MERGE JOIN (CARTESIAN) (Cost=303 Card=10000 Bytes=60000)
   3    2       TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=100 Bytes=300)
   4    2       SORT (JOIN) (Cost=300 Card=100 Bytes=300)
   5    4         TABLE ACCESS (FULL) OF 'T2' (Cost=3 Card=100 Bytes=300)


Execution Plan (8.1.7.4 - query_rewrite_enabled = true)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=7 Card=1 Bytes=6)
   1    0   SORT (AGGREGATE)
   2    1     HASH JOIN (Cost=7 Card=1000 Bytes=6000)
   3    2       TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=100 Bytes=300)
   4    2       TABLE ACCESS (FULL) OF 'T2' (Cost=3 Card=100 Bytes=300)

#

