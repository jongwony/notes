rem
rem	Script:		prefetch_test_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2001
rem	Purpose:	Example for Cost Based Oracle.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not  relevant 
rem		8.1.7.4 
rem
rem	You have to supply the number of rows in the 
rem	driving table as the first input parameter to
rem	the script.
rem
rem	Because we don't have cpu costing enabled, this
rem	always gives the classic execution plan, with a
rem	unique scan on the target index.
rem

start setenv

drop table driver;
drop table target;

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


create table driver (
	id,
	xref,
	padding
)
nologging
as
select 
	rownum,
	rownum,
	rpad('x',20)
from
	all_objects
where 
	rownum <= &1
;

alter table driver add constraint d_pk
primary key(id)
;

create table target (
	id,
	small_vc,
	padding
)
as
select
	rownum,
	to_char(rownum),
	rpad('x',20)
from
	all_objects
where 
	rownum <= 3000
;

alter table target add constraint t_pk
primary key (id)
;

begin
	dbms_stats.gather_table_stats(
		user,
		'driver',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'target',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool prefetch_test

set autotrace traceonly explain
rem alter session set events '10053 trace name context forever';

select 
	/*+ ordered use_nl(t) index(t) full(d) */
	d.id, t.small_vc
from
	driver	d,
	target	t
where
	t.id = d.xref
and	t.padding is not null
;

alter session set events '10053 trace name context off';
set autotrace off


spool off

