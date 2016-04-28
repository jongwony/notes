rem
rem	Script:		agg_sort.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	How different are the costs for:
rem		sort order by
rem		sort group by
rem		sort aggregate
rem		sort distinct
rem
rem	Note - for group by / distinct, the number of 
rem	distinct values output for a multi-column 
rem	aggregation of N columns is estimates by taking
rem	the product of the N columns num_distincts, and
rem	then dividing N-1 times by the square root of 2.
rem

start setenv

execute dbms_random.seed(0)

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

/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;


create table t1 
nologging
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select
	/*+ ordered use_nl(v2) */
	dbms_random.string('U',trunc(dbms_random.value(1,3)))			col1,
	dbms_random.string('U',trunc(dbms_random.value(1,3)))			col2
from
	generator	v1,
	generator	v2
where
	rownum <= 5000
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


spool agg_sort


column col1 format a4
column col2 format a4

rem	alter session set events '10053 trace name context forever';
set autotrace traceonly explain

prompt	Order by

select 
	col1, col2
from
	t1
order by
	col1, col2
;

prompt	Group by

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;

prompt	Group by with order by

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col2, col1
;

prompt	Distinct

select 
	distinct col1, col2
from
	t1
;

prompt	Max

select 
	max(col1), max(col2)
from
	t1
;

set autotrace off
alter session set events '10053 trace name context off';

spool off
