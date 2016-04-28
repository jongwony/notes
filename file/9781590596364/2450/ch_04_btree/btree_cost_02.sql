rem
rem	Script:		btree_cost_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Cost Based Oracle"
rem	Purpose:	Range scans and missing columns
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The call to disable skip scans is there to ensure that
rem	we get an index range scan
rem
rem	The call to hack_stats.sql is to show that something
rem	odd happens in 10g when you modify the value for the
rem	num_rows directly in user_indexes. 
rem
rem	For values where user_indexes.num_rows > user_tables.num_rows
rem	the INDEX line of the plan has its cardinality scaled up by
rem		user_indexes.num_rows / user_tables.num_rows
rem
rem	If user_indexes.num_rows < user_tables.num_rows, then the
rem	cost and cardinality of the leaf block accesses disappears.
rem	
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

	begin		execute immediate 'alter session set "_optimizer_skip_scan_enabled"=false';
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


spool btree_cost_02

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


@hack_stats

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';
rem	alter session set events '10132 trace name context forever';

prompt
prompt	Range scan at end of index. This one happens
prompt	to default to FTS, so the second attempt is
prompt	hinted to use the index
prompt

select
	small_vc
from
	t1
where
	n1	= 2
and	ind_pad	= rpad('x',40)
and	n2	between 1 and 3
;


select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n1	= 2
and	ind_pad	= rpad('x',40)
and	n2	between 1 and 3
;


prompt
prompt	Range scan at start of index. This one defaults
prompt	to FTS, so has been hinted to use the index
prompt

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n1	between 1 and 3
and	ind_pad	= rpad('x',40)
and	n2	= 2
;

prompt
prompt	To show the three selectivities in action
prompt	Effective index selectivity set by range scan on 1st column
prompt	Effective table selectivity set by n1, ind_pad, n2
prompt	Final table selectivity set by all 4 predicates
prompt

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n1	between 1 and 3
and	ind_pad	= rpad('x',40)
and	n2	= 2
and	small_vc = lpad(100,10)
;

alter session set events '10053 trace name context off';
alter session set events '10132 trace name context off';
set autotrace off

spool off


set doc off
doc

Execution plans for the last query in 10g:

a)	Without hacking: (10,000 rows)
--------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=264 Card=1 Bytes=58)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=264 Card=1 Bytes=58)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=184 Card=1633)



b)	Setting user_indexes.num_rows - 11000
---------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=264 Card=1 Bytes=58)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=264 Card=1 Bytes=58)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=184 Card=1797)



c)	Setting user_indexes.num_rows = 9900
--------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=93 Card=1 Bytes=58)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=93 Card=1 Bytes=58)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=12 Card=82)


#
