rem
rem	Script:		join_card_01a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	First special case of breaking the rules
rem	What if we have a filter predicate on just
rem	one side of the join ?
rem

start setenv
set timing off

define t1f0 = 100
define t1j1 = 30

define t2f0 = 100
define t2j1 = 40

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
	trunc(dbms_random.value(0, &t1f0 ))	filter,
	trunc(dbms_random.value(0, &t1j1 ))	join1,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where 
	rownum <= 1000
;


create table t2
as
select
	trunc(dbms_random.value(0, &t2f0 ))	filter,
	trunc(dbms_random.value(0, &t2j1 ))	join1,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 1000
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


spool join_card_01a

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

prompt	Join condition: t2.join1 = t1.join1
prompt	Filter on just T1

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
and	t1.filter = 1
;

prompt	Join condition: t2.join1 = t1.join1
prompt	Filter on just T2

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
and	t2.filter = 1
;

alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit

set doc off
doc


#
