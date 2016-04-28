rem
rem	Script:		trans_close_03a.sql
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
rem	Repeat trans_close_03.sql, but using the dbms_xplan package 
rem	which is not available to Oracle 8. In this example with a
rem	non-join predicate that is NOT an equality, the join predicate
rem	is not eliminated as transitive closure takes place. 
rem
rem	This means the stting of query_rewrite_enabled has no impact
rem	on the costs or cardinalities. This is not consistent with
rem	queries where the non-join predicates are equalities, and
rem	may be the reason why Oracle introduced the option for changing
rem	the behaviour through query_rewrite_enabled.
rem

start setenv
set feedback off

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

spool trans_close_03a

prompt
prompt	The correct count is 10,000
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Duplicate the join clause 
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1
and	t2.n1 = t1.n1
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Create the predicate that might have been generated
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1
and	t2.n1 > 8
;

select * from table(dbms_xplan.display);
delete from plan_table;

prompt
prompt	Use a method that Oracle can't do transitive closure on 
prompt

explain plan for
select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1 + 0
;

select * from table(dbms_xplan.display);
delete from plan_table;
commit;



prompt
prompt	Now demonstrate a FILTER operation caused
prompt	by a constraint. First note the execution 
prompt	plan and cardinality of the following 
prompt	query without a check constraint on N1
prompt


explain plan for
select
	count(*)
from
	t1
where
	n1 = 13
;

select * from table(dbms_xplan.display);
delete from plan_table;
commit;


prompt
prompt	Now add the constraint, and note the appearance
prompt	of the FILTER line in the plan. This plan does
prompt	not change the cardinality of the original scan
prompt	against the table, as this would require Oracle
prompt	to scan the table at run time - instead it inserts
prompt	a constradiction in a FILTER line to ensure that
prompt	the child operation (the scan) is not executed
prompt

alter table t1 modify n1 not null;
alter table t1 add constraint t1_n1 check (n1 < 10);

explain plan for
select
	count(*)
from
	t1
where
	n1 = 13
;

select * from table(dbms_xplan.display);
delete from plan_table;
commit;


spool of

