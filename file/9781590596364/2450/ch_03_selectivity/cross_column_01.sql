rem
rem	Script:		cross_column_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The call to delete system stats is to allow
rem	for repeatable experiments
rem
rem	The call to purge the recyclebin is to avoid
rem	issues of odd recursive drops taking place
rem	at unpredictable times.
rem
rem	The call to dbms_random.seed(0) ensures a
rem	repeatable test if we generate pseudo-random
rem	data.
rem
rem	For generating a large table in 8i, comment
rem	out the "WITH ... AS" section of code in the
rem	create table statement, and re-instate the 
rem	'create table generator' code.
rem
rem	For a query with:
rem		column1 operator column2
rem	Oracle tests
rem		column1 operator :unknown
rem		:unknown operator column2
rem	and uses whichever gives the LOWER selectivity,
rem	i.e. the lower cardinality (number of row returned)
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

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;

*/


alter session set sql_trace true;

create table t1 
nologging		-- adjust as necessary
pctfree 10		-- adjust as necessary
pctused 90		-- adjust as necessary
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
select
	rownum					id,
	trunc(dbms_random.value(0,200))		n200,
	trunc(dbms_random.value(0,300))		n300,
	trunc(dbms_random.value(0,400))		n400,
	trunc(dbms_random.value(0,500))		n500,
	lpad(rownum,10)				small_vc,
	rpad('x',100)				padding
from
	generator	v1,
	generator	v2
where
	rownum <= 100000
;

alter session set sql_trace false;


begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null,
		method_opt 		=> 'for all columns size 1',
		no_invalidate 		=> false
	);
end;
/

spool cross_column_01

set autotrace traceonly explain

rem
rem	The cardinality matches n300 in the following query:
rem	TABLE ACCESS (FULL) OF 'T1' (Cost=290 Card=333 Bytes=2664)
rem

select	count(*)
from	t1
where	n300 = n200
;

rem
rem	The cardinality matches n400 in the following query:
rem	TABLE ACCESS (FULL) OF 'T1' (Cost=290 Card=250 Bytes=2000)
rem

select	count(*)
from	t1
where	n400 = n300
;

rem
rem	The cardinality matches n500 in the following query:
rem	TABLE ACCESS (FULL) OF 'T1' (Cost=290 Card=200 Bytes=1600)
rem

select	count(*)
from	t1
where	n500 = n400
;

set autotrace off

spool off
