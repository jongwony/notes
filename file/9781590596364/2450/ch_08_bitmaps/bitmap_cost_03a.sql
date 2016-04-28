rem
rem	Script:		bitmap_cost_03a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Indexing Oracle"
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Repeat bitmap_cost_03.sql but with the hair_code
rem	sorted so that the index is very small.
rem

start setenv
set timing on

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

drop table generator;

create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 6000
;

*/


create table t1 
nologging
pctfree 0
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 6000
)
select	/*+ ordered use_nl(v2) */
	'x'		facts,
	mod(rownum,2)	sex,
	mod(rownum,3)	eyes,
	trunc(7*(rownum-1)/36000000)	hair,
	mod(rownum,31)	town,
	mod(rownum,47)	age,
	mod(rownum,79)	work
from	
	generator	v1,
	generator	v2
;

create bitmap index i1 on t1(sex) 
nologging pctfree 0;

create bitmap index i2 on t1(eyes)
nologging pctfree 0;

create bitmap index i3 on t1(hair) 
nologging pctfree 0;

create bitmap index i4 on t1(town) 
nologging pctfree 0;

create bitmap index i5 on t1(age) 
nologging pctfree 0;

create bitmap index i6 on t1(work) 
nologging pctfree 0;


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



spool bitmap_cost_03a

select	
	table_name,
	blocks,
	num_rows
from
	user_tables
where
	table_name = 'T1'
;

select 
	column_name,
	num_nulls, 
	num_distinct, 
	density,
	low_value, 
	high_value
from
	user_tab_columns
where
	table_name = 'T1'
and	column_name like 'N_'
order by
	column_name
;

column name format a5

select 
	index_name 		name,
	blevel, 
	leaf_blocks, 
	distinct_keys,
	num_rows, 
	clustering_factor, 
	avg_leaf_blocks_per_key, 
	avg_data_blocks_per_key
from
	user_indexes
where
	table_name = 'T1'
order by 
	index_name
;

set autotrace traceonly explain

prompt
prompt	Base query
prompt

select 	
	count(facts)
from 	
	t1
where 	
	sex	= 1
and	eyes	= 1
and	hair	= 1
and	town	= 15
and	age	= 25
and	work	= 40
;

prompt
prompt	Hinted to disable index i3
prompt	And get a lower cost plan
prompt

select 	/*+ no_index(t1 i3) */
	count(facts)
from 	
	t1
where 	
	sex	= 1
and	eyes	= 1
and	hair	= 1
and	town	= 15
and	age	= 25
and	work	= 40
;

prompt
prompt	Hinted to disable index i4
prompt

select 	/*+ no_index(t1 i4) */
	count(facts)
from 	
	t1
where 	
	sex	= 1
and	eyes	= 1
and	hair	= 1
and	town	= 15
and	age	= 25
and	work	= 40
;

prompt
prompt	Hinted to disable index i5
prompt

select 	/*+ no_index(t1 i5) */
	count(facts)
from 	
	t1
where 	
	sex	= 1
and	eyes	= 1
and	hair	= 1
and	town	= 15
and	age	= 25
and	work	= 40
;

prompt
prompt	Hinted to disable indexes i5 and i1
prompt	The query becomes cheaper than using i1 !
prompt

select 	/*+ no_index(t1 i5 i1) */
	count(facts)
from 	
	t1
where 	
	sex	= 1
and	eyes	= 1
and	hair	= 1
and	town	= 15
and	age	= 25
and	work	= 40
;


set autotrace off

spool off
