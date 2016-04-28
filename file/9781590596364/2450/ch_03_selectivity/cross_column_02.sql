rem
rem	Script:		cross_column_02.sql
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
rem	With extra predicates - there is no significant
rem	change in strategy
rem
rem	When the extra predicate was mod(col) the CBO
rem	used 1% as the selectivity for the column) -
rem	assume this is standard for function(col) = const.
rem
rem	When the extra predicate was n200 > 250, (half 
rem	the data) then the CBO generated n300 > 250, 
rem	which resulted in the selectivity dropping to 
rem	one quarter of the original. (The same occurred
rem	if the explicit predicate was n300 > 250, the
rem	generated predicate was n200 > 250). This is 
rem	a questionable modelling decision.
rem
rem	If you change a load of data (e.g. set n300 = 250
rem	for every 7th row) and generate a histogram, then
rem	Oracle uses densities, and high/low information from
rem	the histogram to adjust the selectivity.
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
	trunc(dbms_random.value(0,200)) + 150	n200,
	trunc(dbms_random.value(0,300)) + 100	n300,
	trunc(dbms_random.value(0,400)) + 50	n400,
	trunc(dbms_random.value(0,500))		n500,
	lpad(rownum,10)				small_vc,
	rpad('x',100)				padding
from
	generator	v1,
	generator	v2
where
	rownum <= 100000
;


begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null,
		method_opt 		=> 'for table for all columns size 254',
		no_invalidate 		=> false
	);
end;
/

spool cross_column_02

set autotrace traceonly explain

select	count(*)
from	t1
where	n300 = n200
-- and	n200 > 250
;

select	count(*)
from	t1
where	n300 = n200
-- and	n300 > 250
;

set autotrace off

spool off
