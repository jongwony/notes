rem
rem	Script:		filter_cost_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	Demonstration of a simple query that uses 
rem	a filter operation (hinted in 9 and 10) to
rem	execute a subquery
rem
rem	We run the query three times:
rem		Allowing the optimizer its choice
rem		Forcing a filter
rem		Forcing an unnest
rem
rem	Even with the INITRANS set to 1, you will find
rem	that each block in the newly created table will
rem	have 3 ITL slots in 9i and 10g
rem
rem	If you want to destroy the performance of the
rem	no_unnest option, then change the first row 
rem	with department zero to be in department 67
rem	for Oracle 8i or 9i, or 432 for 10g.
rem

start setenv

drop table emp;

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
where	rownum <= 1000
;

*/

create table emp(
	dept_no		not null,
	sal,
	emp_no		not null,
	padding,
	constraint e_pk primary key(emp_no)
)
as
with generator as (
	select	--+ materialize
		rownum 		id
	from	all_objects 
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

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 'EMP',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/


spool filter_cost_01

set autotrace traceonly explain

rem	alter session set events '10046 trace name context forever, level 8';
rem	alter session set events '10053 trace name context forever, level 2';

prompt
prompt	Base line query
prompt	Give the optimizer the choice
prompt

select
	outer.* 
from emp outer
where outer.sal >
	(select
		avg(inner.sal) 
 	from	emp inner 
	where	inner.dept_no = outer.dept_no
);

prompt
prompt	UNNEST blocked
prompt

select
	outer.* 
from emp outer
where outer.sal >
	(select /*+ no_unnest */ avg(inner.sal) 
 	from emp inner 
	where inner.dept_no = outer.dept_no
);


prompt
prompt	UNNEST forced 
prompt

select
	outer.* 
from emp outer
where outer.sal >
	(select /*+ unnest */
		avg(inner.sal) 
 	from	emp inner 
	where	inner.dept_no = outer.dept_no
);


alter session set events '10053 trace name context off';
alter session set events '10046 trace name context off';

set autotrace off

spool off
