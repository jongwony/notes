rem
rem	Script:		scalar_sub_02.sql
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
rem	Demonstrate that scalar subqueries use the same
rem	technology as the FILTER operation to minimise
rem	the number of times the subquery has to be executed
rem
rem	Since Deterministic functions have never appeared 
rem	to work as advertised, this may allow you to do
rem	something a little clever instead, viz:
rem	
rem		select 
rem			(select funct(colx) from dual) func
rem		from	...
rem	
rem	instead of
rem		select
rem			func(colx)
rem		from	...
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


create or replace function get_dept_avg(i_dept in number)
return number deterministic
as
	m_av_sal	number;
begin
	select	avg(sal) 
	into	m_av_sal
	from	emp
	where	dept_no = i_dept
	;

	return m_av_sal;

end;
/

spool scalar_sub_02

set timing on
set autotrace on 

prompt
prompt	Calling the function through a scalar subquery
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		dept_no,
		sal,
		emp_no,
		padding,
		(select get_dept_avg(dept_no) from dual) av_sal
	from	emp
)
where
	sal > av_sal
;

prompt
prompt	Calling the function through a scalar subquery
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		dept_no,
		sal,
		emp_no,
		padding,
		(select get_dept_avg(dept_no) from dual) av_sal
	from	emp
)
;


prompt
prompt	Calling the function direct - this will be slow
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		dept_no,
		sal,
		emp_no,
		padding,
		get_dept_avg(dept_no)	av_sal
	from	emp
)
where
	sal > av_sal
;

prompt
prompt	Calling the function direct - this will be slow
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		dept_no,
		sal,
		emp_no,
		padding,
		get_dept_avg(dept_no)	av_sal
	from	emp
)
;

set autotrace off
set timing off


spool off
