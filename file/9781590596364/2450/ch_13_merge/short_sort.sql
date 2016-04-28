rem
rem	Script:		short_sort.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
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
	rownum 	id,
	substr(dbms_random.string('U',6),1,6)	sortcode
from	all_objects 
where	rownum <= 5000
;

*/

create table t1 
as
with generator as (
	select	--+ materialize
		rownum 	id,
		substr(dbms_random.string('U',6),1,6)	sortcode
	from	all_objects 
	where	rownum <= 5000
)
select
	/*+ ordered use_nl(v2) */
	substr(v2.sortcode,1,4) || substr(v1.sortcode,1,2) sortcode
from
	generator	v1,
	generator	v2
where
	rownum <= 1 * 1048576
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

spool short_sort

set timing on

alter session set events '10032 trace name context forever';

set autotrace traceonly

select 
	sortcode
from	t1
order by sortcode
;

select * from (
	select * from t1 order by sortcode
)
where
	rownum <= 10
;

set autotrace off

alter session set events '10032 trace name context off';

spool off

set doc off
doc


#
