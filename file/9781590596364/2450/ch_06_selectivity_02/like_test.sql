rem
rem	Script:		like_test.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Check the default selectivity for 
rem		built_in_function(char_column) like 'xx%'
rem
rem	Obviously this is relevant only to character types
rem	The mechanism uses 5% (you might expect it to 
rem	emulate a between clause, and use 0.25%, even though
rem	the function has been applied)
rem
rem	This is another case where the selectivity of
rem		NOT (pred) is not 1 - selectivity of (pred)
rem

start setenv
set timing off

execute dbms_random.seed(0)

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


/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;



create table t1 
nologging		-- adjust as necessary
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	rownum				id,
	dbms_random.string('l',12)	small_vc,
	rpad('x',50)			padding
from
	generator	v1,
	generator	v2
where
	rownum <= 100000
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

spool like_test

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';
rem	alter session set events '10132 trace name context forever';


rem
rem	You could try adding these constraints to see 
rem	if the cardinality estimates change - they do
rem	but not necessarily correctly - Oracle seems to
rem	double count the predicate.
rem
rem	Note - this version of the syntax for adding a check 
rem	constraint is not legal for 8i, but 8i can't generate
rem	predicates from constraints anyway.
rem

rem	alter table t1 modify small_vc not null;
rem	alter table t1 modify small_vc check(small_vc = lower(small_vc));


prompt 	lower(col) like 'wo%'

select 
	* 
from
	t1
where
	lower(small_vc) like 'wo%'
;


prompt 	lower(col) like 'wor%'

select 
	* 
from
	t1
where
	lower(small_vc) like 'wor%'
;


prompt 	lower(col) like 'wora%'

select 
	* 
from
	t1
where
	lower(small_vc) like 'wora%'
;


prompt 	lower(col) not like 'wora%'

select 
	* 
from
	t1
where
	lower(small_vc) not like 'wora%'
;


set autotrace off

spool off
