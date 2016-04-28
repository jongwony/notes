rem
rem	Script:		unnest_cost_01a.sql
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
rem	Variations on an unnesting theme.
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
	dept_group	number,
	constraint d_pk primary key(dept_no)
)
;

insert into dept values(0, 1);
insert into dept values(1, 1);
insert into dept values(2, 1);
insert into dept values(3, 2);
insert into dept values(4, 2);
insert into dept values(5, 2);
commit;


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

spool unnest_cost_01a

set autotrace traceonly explain

prompt
prompt	Original query
prompt

select
	outer.* 
from emp outer
where outer.sal >
	(
		select
			avg(inner.sal) 
 		from	emp inner 
		where	inner.dept_no = outer.dept_no
	)
;

prompt
prompt	Single row non-correlated query
prompt

select
	outer.* 
from emp outer
where outer.sal >
	(
		select
			avg(inner.sal) 
 		from	emp inner 
	)
;


prompt
prompt	By department - with subquery to restrict departments
prompt	only on the inner emp table.
prompt

select
	outer.* 
from emp outer
where outer.sal >
	(
		select
			avg(inner.sal) 
	 	from	
			emp inner
		where	inner.dept_no = outer.dept_no
		and	inner.dept_no in (
				select	dept_no
				from	dept
				where	dept_group = 1
	)
);


prompt
prompt	By department - with join to restrict departments
prompt	only on the inner emp table.
prompt

select
	outer.* 
from	emp outer
where 	outer.sal >
	(
		select
			avg(inner.sal) 
 		from
			dept,
			emp inner 
		where	inner.dept_no = outer.dept_no
		and	dept.dept_no = inner.dept_no
		and	dept.dept_group = 1
	)
;


prompt
prompt	By department - with two subqueries to restrict departments
prompt

select
	outer.* 
from	emp outer
where	outer.dept_no in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
and outer.sal >
	(
		select
			avg(inner.sal) 
	 	from	
			emp inner
		where	inner.dept_no = outer.dept_no
		and	inner.dept_no in (
				select	dept_no
				from	dept
				where	dept_group = 1
			)
	)
;



prompt
prompt	By department - with two joins to restrict departments
prompt


select
	outer.* 
from	
	dept,
	emp outer
where
	dept.dept_group = 1
and	outer.dept_no = dept.dept_no
and 	outer.sal >
	(
		select
			avg(inner.sal) 
 		from
			dept,
			emp inner 
		where	inner.dept_no = outer.dept_no
		and	dept.dept_no = inner.dept_no
		and	dept.dept_group = 1
	)
;


set autotrace off

spool off
