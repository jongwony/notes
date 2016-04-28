rem
rem	Script:		unnest_cost_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	The code from filter_cost.sql, but rewritten with
rem	a manual unnesting operation to demonstrate the
rem	nominal SQL executed by Oracle when unnesting.
rem
rem	In passing - 10g decides to unnest or filter
rem	based on calculated cost. If you change the 
rem	insert statement to use the constant 1 as the
rem	department number, then the cost of the filter 
rem	drops to 70, and Oracle does not unnest.
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

create table emp (
	dept_no		number	not null,
	sal		number,
	emp_no		number,
	padding		varchar2(60),
	constraint e_pk primary key(emp_no)
);

insert into emp
select
	mod(rownum,6),
--	1,
	rownum,
	rownum,
	rpad('x',60)
from
	all_objects
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


spool unnest_cost_01

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';
rem	alter session set events '10132 trace name context forever';

prompt
prompt	Original query
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
prompt	Manual Unnest
prompt

select
	/* ordered use_hash(outer) */
	outer.* 
from 
	(
		select	
			/*+ no_merge */
			dept_no,		
			avg(inner.sal)	avg_sal
	 	from	emp inner 
		group by
			dept_no
	)	inner,
	emp	outer
where
	outer.dept_no = inner.dept_no 
and	outer.sal > inner.avg_sal
;


alter session set events '10132 trace name context off';
alter session set events '10053 trace name context off';
set autotrace off


spool off
