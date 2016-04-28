rem
rem	Script:		bitmap_cost_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Indexing Oracle"
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The purpose of this script is to build a table that
rem	demonstrates the basic principle of bitmap index costing
rem
rem	I have set the index pctfree to 90% to spread the rows across
rem	a larger number of leaf blocks. (pctfree does not apply to the
rem	branch level).
rem
rem	Anomalies -
rem	Increasing the value of db_file_multiblock_read_count increases the 
rem	cost reported against a query using bitmaps indexes
rem
rem	The 10053 trace seems to report a cost for using the index, and then
rem	a cost for the query. 
rem
rem	The cost for the index is calculated the same way as for b-trees, ignore
rem	the blevel if it is one, otherwise it is blevel + fraction of leaf_blocks.
rem	However, the result seems to be multiplied by 1.1 before being added to the
rem	rest of the cost, and the result is then rounded - (not ceiling'ed).
rem
rem	If you factor out the index element of the cost (it is best to look at the
rem	10053 trace and substract 1.1 * index cost from the BEST_CST to get the table 
rem	cost, you get a result which looks as if it was derived by assuming that about
rem	80% of the table rows were packed into a few blocks, and 20% were scattered
rem	as widely as possible, so that table cost is roughly:
rem		0.2 * rows  + 0.8 * rows / (rows per block)
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

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;

end;
/

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

spool bitmap_cost_01

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
rem	alter session set events '10053 trace name context forever';

prompt	Bitmap Index on clustered column with 20 values

select
	/*+ index(t1) */
	small_vc
from	t1
where	n1	= 2
;

prompt	Bitmap Index on scattered column with 20 values

select
	/*+ index(t1) */
	small_vc
from	t1
where	n2	= 2
;

prompt	Bitmap Index on clustered column with 25 values

select
	/*+ index(t1) */
	small_vc
from	t1
where	n3	= 2
;

prompt	Bitmap Index on scattered column with 25 values

select
	/*+ index(t1) */
	small_vc
from	t1
where	n4	= 2
;

prompt	B-tree Index on clustered column with 25 values

select
	small_vc
from	t1
where	n5	= 2
;

prompt	B-tree Index on scattered column with 25 values

select
	small_vc
from	t1
where	n6	= 2
;

alter session set events '10053 trace name context off';
set autotrace off

spool off

