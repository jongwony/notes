rem
rem	Script:		constraint_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	We create a constraint on T2, but the optimizer
rem	manages to turn this into a predicate on T1.
rem
rem	This does not happen in 8i, although a trace with
rem	event 10060 shows that simple predicate closure
rem	allows Oracle to generate the predicate t1.n2 = 15
rem

start setenv

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
	trunc((rownum-1)/15)	n1,
	trunc((rownum-1)/15)	n2,
	rpad(rownum,215)	v1
from all_objects 
where rownum <= 3000
;

create table t2
as
select 
	mod(rownum,200)		n1,
	mod(rownum,200)		n2,
	rpad(rownum,215)	v1
from all_objects 
where rownum <= 3000
;

create index t_i1 on t1(n1);
create index t_i2 on t2(n1);

alter table t2 add constraint t2_ck_n1 check (n1 between 0 and 199);

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

spool constraint_02

rem	alter session set events '10053 trace name context forever, level 2';

explain plan for
select
	count(t1.v1)	ct_v1,
	count(t2.v1)	ct_v2
from 	t1, t2
where	t2.n2 = 15
and	t1.n2 = t2.n2 
and	t1.n1 = t2.n1 
;

select * from table(dbms_xplan.display);
rollback;


spool off

set doc off
doc


#
