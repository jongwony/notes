rem
rem	Script:		semi_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	The code from filter_cost.sql, rewritten to show
rem	the possible plans for an IN (EXISTS) subquery
rem
rem

start setenv
set timing off

drop table dept;
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
	rownum,
	rownum,
	rpad('x',60)
from
	all_objects
where
	rownum <= 20000
;


create table dept (
	dept_no		number(6),
	dept_group	number
)
;

insert into dept values(0, 1);
insert into dept values(1, 1);
insert into dept values(2, 1);
insert into dept values(3, 2);
insert into dept values(4, 2);
insert into dept values(5, 2);
commit;


alter table dept add constraint d_uk unique (dept_no);
alter table dept modify dept_no not null;

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

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 'DEPT',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/

spool semi_01

set autotrace traceonly explain

prompt
prompt	Original query
prompt

select
	emp.* 
from 
	emp
where 
	emp.dept_no in (
		select
			dept.dept_no
 		from	dept
		where	dept.dept_group = 1
	)
;


prompt
prompt	Without uniqueness
prompt

alter table dept drop constraint d_uk;

select
	emp.* 
from 
	emp
where 
	emp.dept_no in (
		select
			dept.dept_no
 		from	dept
		where	dept.dept_group = 1
	)
;

prompt
prompt	Block unnest query
prompt

select
	emp.* 
from 
	emp
where 
	emp.dept_no in (
		select	/*+ no_unnest */
			dept.dept_no
 		from	dept
		where	dept.dept_group = 1
	)
;


prompt
prompt	Semi - join
prompt

select
	emp.* 
from 
	emp
where 
	emp.dept_no in (
		select	/*+ nl_sj */
			dept.dept_no
 		from	dept
		where	dept.dept_group = 1
	)
;

prompt
prompt	Semi - join
prompt

select
	emp.* 
from 
	emp
where 
	emp.dept_no in (
		select	/*+ merge_sj */
			dept.dept_no
 		from	dept
		where	dept.dept_group = 1
	)
;


prompt
prompt	Semi - join
prompt

select
	emp.* 
from 
	emp
where 
	emp.dept_no in (
		select	/*+ hash_sj */
			dept.dept_no
 		from	dept
		where	dept.dept_group = 1
	)
;

set autotrace off

spool off
