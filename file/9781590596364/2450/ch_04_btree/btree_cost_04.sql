rem
rem	Script:		btree_cost_04.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Cost Based Oracle"
rem	Purpose:	In lists with indexes
rem
rem	Versions tested 
rem		10.0.1.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Test conditions:
rem		Locally managed tablespace
rem		Uniform extent size 1M
rem		Block size 8K
rem		Segment space management MANUAL
rem

start setenv
set feedback off

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


create table t1 
nologging
as
select
	trunc(dbms_random.value(0,25))	n1,
	rpad('x',40)			ind_pad,
	trunc(dbms_random.value(0,20))	n2,
	lpad(rownum,10,'0')		small_vc,
	rpad('x',200)			padding
from
	all_objects
where
	rownum  <= 10000
;


create index t1_i1 on t1(n1, ind_pad, n2) 
nologging
pctfree 91
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

spool btree_cost_04

select	
	table_name,
	blocks,
	num_rows
from	user_tables
where	table_name = 'T1'
;

select 
	num_rows, distinct_keys,
	blevel, leaf_blocks, clustering_factor, 
	avg_leaf_blocks_per_key, avg_data_blocks_per_key
from
	user_indexes
where	table_name = 'T1'
and	index_name = 'T1_I1'
;

select 
	column_name,
	num_nulls, num_distinct, density,
	low_value, high_value
from
	user_tab_columns
where	table_name = 'T1'
and	column_name in ('N1','N2','IND_PAD')
order by
	column_name
;


set autotrace traceonly explain

prompt
prompt	An in-list on the last column of the index.
prompt	The cost varies from 8i to 9i
prompt


select
	/*+ index(t1) */
	small_vc
from
	t1
where	n1	= 5
and	ind_pad = rpad('x',40)
and	n2 in (1,6,18)
;

rem
rem	Effects of optimizer_index_caching (9.2.0.6)
rem
rem	Selectivity = 1/25 * 1 * (3 * 1/20) = 3/500.
rem	Cardinality = 60
rem
rem	Cost 	= 2 + ceil(1,111 * 3/500) + ceil(9,745 * 3/500)
rem		= 2 + ceil(6.6666) + ceil(58.47)
rem		= 2 + 7 + 59 = 68
rem
rem	Cache		Cost of index
rem	 25		6
rem	 50		4
rem	 75		2
rem	100		0
rem
rem	Try (ceil((1-cache)*root) 
rem

alter session set optimizer_index_caching = 25;
prompt	Caching = 25

select
	/*+ index(t1) */
	small_vc
from
	t1
where	n1	= 5
and	ind_pad = rpad('x',40)
and	n2 in (1,6,18)
;

alter session set optimizer_index_caching = 50;
prompt	Caching = 50

select
	/*+ index(t1) */
	small_vc
from
	t1
where	n1	= 5
and	ind_pad = rpad('x',40)
and	n2 in (1,6,18)
;

alter session set optimizer_index_caching = 75;
prompt	Caching = 75

select
	/*+ index(t1) */
	small_vc
from
	t1
where	n1	= 5
and	ind_pad = rpad('x',40)
and	n2 in (1,6,18)
;

alter session set optimizer_index_caching = 100;
prompt	Caching = 100

select
	/*+ index(t1) */
	small_vc
from
	t1
where	n1	= 5
and	ind_pad = rpad('x',40)
and	n2 in (1,6,18)
;

alter session set optimizer_index_caching = 0;

set autotrace off

spool off

