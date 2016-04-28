rem
rem	Script:		set_ops_a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem	Not relevant
rem		 8.1.7.4
rem
rem	Repeate set_ops.sql with CPU costing enabled

start setenv

execute dbms_random.seed(0)

drop table t2;
drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;
end;
/

begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10.000);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/

create table t1 
as
select	
	rownum id,
	ao.*
from
	all_objects ao
where	rownum <= 2500
;

create table t2
as
select	
	rownum id,
	ao.*
from
	all_objects ao
where	rownum <= 2000
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


spool set_ops_a

set autotrace traceonly explain

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


set autotrace off

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
