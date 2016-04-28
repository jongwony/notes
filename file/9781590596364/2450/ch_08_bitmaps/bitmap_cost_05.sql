rem
rem	Script:		bitmap_cost_05.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Indexing Oracle"
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant to
rem		 8.1.7.4
rem
rem	Demonstrate the impact of CPU costing.
rem
		
start setenv

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'begin dbms_stats.delete_system_stats; end;';
	exception 	when others then null;
	end;

--	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
--	exception	when others then null;
--	end;

end;
/

begin
	dbms_stats.set_system_stats('MBRC',8);
	dbms_stats.set_system_stats('MREADTIM',20);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',350);
exception
	when others then null;
end;
/

alter system flush shared_pool;


create table t1
pctfree 70
pctused 30
nologging
as
select
	mod((rownum-1),20)		n1,		-- 20 values, scattered
	trunc((rownum-1)/500)		n2,		-- 20 values, clustered
--
	mod((rownum-1),25)		n3,		-- 25 values, scattered
	trunc((rownum-1)/400)		n4,		-- 25 values, clustered
--
	mod((rownum-1),25)		n5,		-- 25 values, scattered for btree
	trunc((rownum-1)/400)		n6,		-- 25 values, clustered for btree
--
	lpad(rownum,10,'0')		small_vc,
	rpad('x',220)			padding
from
	all_objects
where
	rownum  <= 10000
;

create bitmap index t1_i1 on t1(n1) 
nologging
pctfree 90
;

create bitmap index t1_i2 on t1(n2) 
nologging
pctfree 90
;

create bitmap index t1_i3 on t1(n3) 
nologging
pctfree 90
;

create bitmap index t1_i4 on t1(n4) 
nologging
pctfree 90
;

create        index t1_i5 on t1(n5) 
nologging
pctfree 90
;

create        index t1_i6 on t1(n6) 
nologging
pctfree 90
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

spool bitmap_cost_05

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
rem	alter session set events '10053 trace name context forever, level 2';

prompt	Bitmap Index on scattered column with 20 values

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n1	= 2
;

prompt	Bitmap Index on clustered column with 20 values

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n2	= 2
;

prompt	Bitmap Index on scattered column with 25 values

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n3	= 2
;

prompt	Bitmap Index on clustered column with 25 values

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n4	= 2
;

prompt	B-tree Index on scattered column with 25 values

select
	small_vc
from
	t1
where
	n5	= 2
;

prompt	B-tree Index on clustered column with 25 values

select
	small_vc
from
	t1
where
	n6	= 2
;

rem	alter session set events '10053 trace name context off';

set autotrace off

spool off

