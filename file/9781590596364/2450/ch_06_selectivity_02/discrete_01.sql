rem
rem	Script:		discrete_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		May 2005
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	From an example by Wolfgang Breitling
rem
rem	We create a table with 13,000 rows, using
rem	periods 1 to 12 and 99 for one column, and
rem	periods 1 to 12 and 13 for the other.
rem

start setenv

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
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 1000
)
*/
select
	/*+ ordered use_nl(v2) */
	mod(rownum-1,13)	period_01, 
	mod(rownum-1,13)	period_02
from
	generator	v1,
	generator	v2
where
	rownum <= 13000
;


update t1 set 
	period_01 = 99,
	period_02 = 13
where 
	period_01 = 0;
;

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

spool discrete_01

column column_name format a12

select
	column_name, num_distinct, density
from
	user_tab_columns
where	table_name = 't1'
;

select 
	min(period_01), max(period_01), count(distinct period_01), 
	min(period_02), max(period_02), count(distinct period_02), 
	count(*) 
from 
	t1
;

prompt
prompt	The standard cardinality for colX between A and B
prompt	num_rows * ( (B-A)/(high - low) + 2/num_distinct))
prompt
prompt	The first plan gets the wrong cardinality on the scan
prompt	The second plan gets it right.
prompt

select 
	13000 * (2/98 + 2/13)	std_between_card_99,
	13000 * (2/12 + 2/13)	std_between_card_13
from dual;

set autotrace traceonly explain

select count(*) from t1 where period_01 between 4 and 6;
select count(*) from t1 where period_02 between 4 and 6;

set autotrace off

prompt
prompt	Now generate the profile of all the three-period 
prompt	queries that might be relevant against period_01
prompt

declare
	n	number(6);
	m	number(6);
begin
	for r in -103..202 loop

		n := r;
		m := r + 2;

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm0000') || ''' for ' ||
		' select * from t1 where period_01 >= ' || n || '  and period_01 <= ' || m;

	end loop;
end;
/


select
	to_number(substr(statement_id,1,5))		low_val,
	to_number(substr(statement_id,1,5)) + 2		high_val,
	cardinality
from
	plan_table
where
	id = 0
order by
	to_number(substr(statement_id,1,5))
;

delete from plan_table;
commit;

spool off

