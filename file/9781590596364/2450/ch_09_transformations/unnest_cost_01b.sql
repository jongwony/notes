rem
rem	Script:		unnest_cost_01b.sql
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

spool unnest_cost_01b

set autotrace traceonly explain

prompt
prompt	UNIQUE, NOT NULL, IN
prompt

select
	outer.* 
from
	emp outer
where 
	outer.dept_no in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
;


prompt
prompt	UNIQUE, NOT NULL, NOT IN
prompt

select
	outer.* 
from
	emp outer
where 
	outer.dept_no not in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
;


alter table dept drop constraint d_uk;

prompt
prompt	NON-UNIQUE, NOT NULL, IN
prompt

select
	outer.* 
from
	emp outer
where 
	outer.dept_no in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
;


prompt
prompt	NON-UNIQUE, NOT NULL, NOT IN
prompt

select
	outer.* 
from
	emp outer
where 
	outer.dept_no not in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
;


alter table dept modify dept_no null;

prompt
prompt	NON-UNIQUE, NULLABLE, IN
prompt

select
	outer.* 
from
	emp outer
where 
	outer.dept_no in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
;


prompt
prompt	NON-UNIQUE, NULLABLE, NOT IN
prompt

select
	outer.* 
from
	emp outer
where 
	outer.dept_no not in (
		select	dept_no
		from	dept
		where	dept_group = 1
	)
;


set autotrace off

spool off
