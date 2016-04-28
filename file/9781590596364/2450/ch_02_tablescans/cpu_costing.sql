rem
rem	Script:		cpu_costing.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Dec 2001
rem	Purpose:	9.2 with CPU_COSTING uses predicate order to minimise CPU
rem
rem	Versions tested 
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4	N/A
rem
rem	AUTOTRACE does not show the substr(filter_predicates,1,60) Filter column,
rem	nor the CPU_COST column from the execution plan.  For the full effect,
rem	you will have to use a full explain plan on each query.
rem
rem	In this script I have chosen to select only the filter_predicates
rem	and CPU_cost columns from the plan table.
rem
rem	Note particularly that we have 3,000 rows, and when we compare
rem	the cost of doing 3,000 comparisons of 
rem		to_number(v1) = 1
rem	against
rem		v1 = '1'
rem	The difference is exactly
rem		1,070,604 - 770,604 = 300,000
rem	We could guess that a call to to_number() costs 100 CPU operations
rem

start setenv
set timing off
set feedback off

begin
	dbms_stats.set_system_stats('MBRC',12);
	dbms_stats.set_system_stats('MREADTIM',30);
	dbms_stats.set_system_stats('SREADTIM',5);
	dbms_stats.set_system_stats('CPUSPEED',500);
end;
/

alter system flush shared_pool;

drop table t1;

create table t1(
	v1,
	n1,
	n2
)
as
select
	to_char(mod(rownum,20)),
	rownum,
	mod(rownum,20)
from
	all_objects
where
	rownum <= 3000
;

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true
	);
end;
/

rem
rem	We use cpu_costing and ordered_predicates to show the
rem	effects of different selectivities of columns on the 
rem	total cost (or at least cpu_cost component) of a query.
rem
rem	Examine the execution plan and cost for the 6 permutations
rem

column cpu 	heading "CPU cost" 		format 999,999,999
column filter	heading "Filter Predicate"
break on row skip 3

spool cpu_costing

explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	v1 = 1
and	n2 = 18
and	n1 = 998
;

prompt	Predicted cost (9.2.0.6): 1070604
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;

explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	n1 = 998
and	n2 = 18
and	v1 = 1
;

prompt	Predicted cost (9.2.0.6): 762787
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;

explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	v1 = 1
and	n1 = 998
and	n2 = 18
;

prompt	Predicted cost (9.2.0.6): 1070232
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;

explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	n1 = 998
and	v1 = 1
and	n2 = 18
;

prompt	Predicted cost (9.2.0.6): 762882
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;

explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	n2 = 18
and	n1 = 998
and	v1 = 1
;

prompt	Predicted cost (9.2.0.6): 770237
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;


explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	n2 = 18
and	v1 = 1
and	n1 = 998
;

prompt	Predicted cost (9.2.0.6): 785604
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;


explain plan for
select /*+ cpu_costing */
	* 
from t1
where
	v1 = 1
and	n2 = 18
and	n1 = 998
;

prompt	Left to its own choice of predicate order
select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;


explain plan for
select /*+ cpu_costing ordered_predicates */
	* 
from t1
where
	v1 = '1'
and	n2 = 18
and	n1 = 998
;

prompt	And one last option where the coercion on v1 is not needed
prompt	Predicted cost (9.2.0.6): 770604

select substr(filter_predicates,1,60) Filter, cpu_cost CPU from plan_table where id = 1;
rollback;


spool off

