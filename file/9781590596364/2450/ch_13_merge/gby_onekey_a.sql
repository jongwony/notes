rem
rem	Script:		gby_onekey_a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem	Not relevant
rem		 8.1.7.4
rem
rem	Repeat gby_onekey.sql with CPU costing
rem

start setenv
set pagesize 60

execute dbms_random.seed(0)

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

end;
/

begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10.000);
	dbms_stats.set_system_stats('CPUSPEED',1000);
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
	rownum <= 50
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


spool gby_onekey_a


column col1 format a4
column col2 format a4

rem	alter session set events '10053 trace name context forever';
set autotrace traceonly explain

select 
	/*+ enabled */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;

select 
	/*+ enabled and ordered */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col1, col2
;


select 
	/*+ enabled and re-ordered */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col2, col1
;

select 
	/*+ enabled and partly re-ordered */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col2
;

alter session set "_gby_onekey_enabled"=false;

select 
	/*+ disabled */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;

select 
	/*+ disabled and ordered */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col1, col2
;

select 
	/*+ disabled and ordered */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col2, col1
;

select 
	/*+ disabled and partly re-ordered */
	col1, col2, count(*)
from
	t1
group by
	col1, col2
order by
	col2
;


set autotrace traceonly explain
alter session set events '10053 trace name context off';

spool off
