rem
rem	Script:		join_card_09a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem

start setenv
set timing off

execute dbms_random.seed(0)


drop table t3;
drop table t2;
drop table t1;

begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
end;
/


begin
	execute immediate 'execute dbms_stats.delete_system_stats';
exception
	when others then null;
end;
/


create table t1
as
select
	mod(rownum-1,24)	n1,
	mod(rownum-1,24)	n2,
	lpad(rownum,10)		v1,
	rpad('x',100)		padding
from
	all_objects
where 
	rownum <= 1000
;

create table t2
as
select
	mod(rownum-1,28)	n1,
	mod(rownum-1,28)	n2,
	lpad(rownum,10)		v1,
	rpad('x',100)		padding
from
	all_objects
where 
	rownum <= 1000
;


create table t3
as
select
	mod(rownum-1,32)	n1,
	mod(rownum-1,32)	n2,
	lpad(rownum,10)		v1,
	rpad('x',100)		padding
from
	all_objects
where 
	rownum <= 1000
;

update t1 set n1 = null, n2 = null where n1 = 0;
update t2 set n1 = null, n2 = null where n1 = 0;
update t3 set n1 = null, n2 = null where n1 = 0;

commit;

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

begin
	dbms_stats.gather_table_stats(
		user,
		't3',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool join_card_09a

alter session set events '10053 trace name context forever';

set autotrace traceonly explain

select	
	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.n1 = t1.n1
and	t3.n1 = t2.n1
;

select	
	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.n1 = t1.n1
and	t3.n2 = t2.n2
;


set autotrace off

alter session set events '10053 trace name context off';

spool off

rem	exit

set doc off
doc


#
