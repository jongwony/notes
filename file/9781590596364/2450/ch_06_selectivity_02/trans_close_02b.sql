rem
rem	Script:		trans_close_02b.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant to 
rem		8.1.7.4
rem
rem	Repeat trans_close_02.sql but using 
rem	the dbms_xplan package that is not 
rem	available to 8i
rem
rem	In this case, set query_rewrite_enabled=true
rem	This changes the rules for transitive closure 
rem	with equality (non-join) predicates
rem	

start setenv
set feedback off

alter session set query_rewrite_enabled = true;

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
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
	rpad('x',100)		padding
from
	all_objects
where
	rownum <= 1000
;


create table t2
as
select
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
	rpad('x',100)		padding
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

spool trans_close_02b


prompt
prompt	With transitive closure - but query_rewrite_enabled = true
prompt	The execution plan matches the next one.
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Duplicate the JOIN clause so that one copy
prompt	of it 'survives' the closure.
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1
and	t2.n1 = t1.n1
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Create the predicate that would have been
prompt	generated, and closure does not take place
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1
and	t2.n1 = 5
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Use a method that Oracle can't do transitive
prompt	closure on and suddenly everything looks good
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 = 5
and	t2.n1 = t1.n1 + 0
;

select * from table(dbms_xplan.display);
delete from plan_table;
commit;


spool of

