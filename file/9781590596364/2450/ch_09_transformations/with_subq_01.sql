rem
rem	Script:		with_subq_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not Relevant
rem		 8.1.7.4
rem
rem	Notes:
rem	Possible execution plans for a 'with subquery'
rem

start setenv

drop table emp;
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

rem
rem	Copy a bit of all_objects so that we
rem	can do an explain on the results.
rem

create table t1 
as
select	*
from	all_objects
;

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 'T1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/


spool with_subq_01


prompt
prompt	Hinted to create the temporary table
prompt

explain plan for
with generator as (
	select	--+ materialize
		rownum 		id
	from	t1
	where	rownum <= 1000
)
select
	/*+ ordered use_nl(v2) */
	mod(rownum,6),
	rownum,
	rownum,
	rpad('x',60)
from
	generator	v1,
	generator	v2
where
	rownum <= 20000
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Hinted to fold the subquery into place
prompt

explain plan for
with generator as (
	select	--+ inline
		rownum 		id
	from	t1 
	where	rownum <= 1000
)
select
	/*+ ordered use_nl(v2) */
	mod(rownum,6),
	rownum,
	rownum,
	rpad('x',60)
from
	generator	v1,
	generator	v2
where
	rownum <= 20000
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Unhinted
prompt

explain plan for
with generator as (
	select
		rownum 		id
	from	t1 
	where	rownum <= 1000
)
select
	/*+ ordered use_nl(v2) */
	mod(rownum,6),
	rownum,
	rownum,
	rpad('x',60)
from
	generator	v1,
	generator	v2
where
	rownum <= 20000
;

select * from table(dbms_xplan.display);
delete from plan_table;

spool off
