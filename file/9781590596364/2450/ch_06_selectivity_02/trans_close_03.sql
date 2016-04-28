rem
rem	Script:		trans_close_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	When transitive closure takes place with an EQUALITY as the
rem	non-join predicate, one predicate replaces another. When the 
rem	non-join predicate is not an equality the effect is that new 
rem	predicates appear, but none of the old ones disappear.
rem
rem	The first three versions of the code all end up with predicates
rem		n1 = n2 and n1 > 8 and n2 > 8
rem	so the calculated cardinality is the same, whichever strategy 
rem	we use for writing the code.
rem
rem	The same effect would appear if we had done the non-join 
rem	predicate had been "!= 8" instead of "> 8"
rem
rem	The difference of behaviour between equality and non-equality
rem	predicates is probably the reason underlying the effect imposed
rem	by changing query_rewrite_enabled from false to true.
rem
rem	In this example, cardinalities do not change when we change the 
rem	setting of query_rewrite_enabled.
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

spool trans_close_03

rem	alter session set query_rewrite_enabled = true;
set autotrace traceonly explain

prompt
prompt	The correct count is 10,000
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1
;

prompt
prompt	Duplicate the join clause so that one copy
prompt	of it 'survives' the closure.
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1
and	t2.n1 = t1.n1
;

prompt
prompt	Create the predicate that would have been
prompt	generated.
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1
and	t2.n1 > 8
;

prompt
prompt	Use a method that Oracle can't do transitive
prompt	closure on and Oracle gets a bit better
prompt

select
	count(*)
from
	t1, t2
where
	t1.n1 > 8
and	t2.n1 = t1.n1 + 0
;

prompt
prompt	Now demonstrate a FILTER operation caused
prompt	by a constraint. First note the execution 
prompt	plan and cardinality of the following 
prompt	query without a check constraint on N1
prompt


select
	count(*)
from
	t1
where
	n1 = 13
;


prompt
prompt	Now add the constraint, and note the appearance
prompt	of the FILTER line in the plan. This plan does
prompt	not change the cardinality of the original scan
prompt	against the table, as this would require Oracle
prompt	to scan the table at run time - instead it inserts
prompt	a contradiction in a FILTER line to ensure that
prompt	the child operation (the scan) is not executed
prompt

alter table t1 modify n1 not null;
alter table t1 add constraint t1_n1 check (n1 < 10);

select
	count(*)
from
	t1
where
	n1 = 13
;


set autotrace off

spool of

