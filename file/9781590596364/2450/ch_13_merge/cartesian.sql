rem
rem	Script:		cartesian.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	A special case in costing merge joins.
rem	Cartesian with buffer sort.
rem
rem	Copied from trans_close_02.sql in chapter 6
rem	and modified to make the Cartesian join explicit 
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
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
	rpad('x',100)		padding
from
	generator	v1,
	generator	v2
where
	rownum <= 800
;


create table t2
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
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
	rpad('x',100)		padding
from
	generator	v1,
	generator	v2
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

spool cartesian

set autotrace traceonly explain

select
	count(t1.small_vc), count(t2.small_vc)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = 5
;

set autotrace off

spool off


