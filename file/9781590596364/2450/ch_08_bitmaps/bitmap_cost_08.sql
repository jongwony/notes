rem
rem	Script:		bitmap_cost_08.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not tested on
rem		 8.1.7.4
rem
rem	You can start with a bitmap index, and get
rem	Oracle to convert it into a b-tree structure
rem	in memory.
rem

start setenv

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'execute dbms_stats.delete_system_stats';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;

end;
/

column today new_value m_today
column future new_value m_future

select 
	to_char(trunc(sysdate),'dd-mon-yyyy') today,
	to_char(trunc(sysdate) + 3,'dd-mon-yyyy') future
from dual;


/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 6000
;

*/


create table t1 (
	n1	not null,
	d1	not null,
	v1,
	padding
)
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 1000
)
select
	mod(rownum, 5),
	trunc(sysdate) + trunc((rownum-1)/1000),
	lpad(rownum,10,'0'),
	rpad('x',200)
from
	generator	v1,
	generator	v2
where
	rownum <= 1000000
;

create bitmap index t1_n1 on t1 (n1);
create bitmap index t1_d1 on t1 (d1);

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


spool bitmap_cost_08

select	
	table_name,
	blocks,
	num_rows
from	user_tables
where	table_name = 'T1'
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
and	column_name != 'FACTS'
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

select 
	d1, 
	count(*)
from 
	t1
where 
	n1 = 2
and	d1 between to_date('&m_today', 'DD-MON-YYYY')
	       and to_date('&m_future','DD-MON-YYYY')
group by
	d1
;

set autotrace off


spool off

