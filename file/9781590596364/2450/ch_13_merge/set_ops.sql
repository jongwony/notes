rem
rem	Script:		set_ops.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem

start setenv

execute dbms_random.seed(0)

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

create table t1 
as
select	
	rownum id,
	ao.*
from
	all_objects ao
where	rownum <= 25000
;

create table t2
as
select	
	rownum id,
	ao.*
from
	all_objects ao
where	rownum <= 20000
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


spool set_ops

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever, level 2';

prompt	Union with distinct

select distinct owner, object_type from t1
union
select distinct owner, object_type from t2
;


prompt	Union without distinct

select         owner, object_type from t1
union
select         owner, object_type from t2
;



prompt	Interesct with distinct

select distinct owner, object_type from t1
intersect
select distinct owner, object_type from t2
;

prompt	Intersect without distinct

select         owner, object_type from t1
intersect
select         owner, object_type from t2
;



prompt	Minus with distinct

select distinct owner, object_type from t1
minus
select distinct owner, object_type from t2
;


prompt	Minus without distinct

select         owner, object_type from t1
minus
select         owner, object_type from t2
;

rem	alter session set events '10053 trace name context off';
set autotrace off

rem
rem	The next examples will fail in 8i as the
rem	dbms_xplan package does not exist until 9i
rem

delete from plan_table;
explain plan for
create table t_union
as
select distinct * 
from (
	select owner, object_type from t1
	union
	select owner, object_type from t2
)
;

select * from table(dbms_xplan.display);


delete from plan_table;
explain plan for
create table t_intersect
as
select distinct * 
from (
	select owner, object_type from t1
	intersect
	select owner, object_type from t2
)
;

select * from table(dbms_xplan.display);

delete from plan_table;
explain plan for
create table t_minus
as
select distinct * 
from (
	select owner, object_type from t1
	minus
	select owner, object_type from t2
)
;

select * from table(dbms_xplan.display);

spool off
