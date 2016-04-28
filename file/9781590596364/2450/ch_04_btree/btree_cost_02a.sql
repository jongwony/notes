rem
rem	Script:		btree_cost_02a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Cost Based Oracle"
rem	Purpose:	Range scans and missing columns
rem
rem	Versions tested 
rem		10.1.0.4
rem	Not relevant.
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The call to disable skip scans is there to ensure that
rem	we get an index range scan
rem
rem	After finding that hacking user_indexes.num_rows caused
rem	a problem to appear in 10g, the next test sets a few
rem	index entries to all nulls to see if a genuine data 
rem	set has the same problem.
rem
rem	The answer is: Yes, but not consistently.
rem
rem	Running this script a few times in a row, the 
rem	plan for the second query (after setting some
rem	rows to nulls) would sometimes show the same
rem	cost as the first query, and sometimes show
rem	a hugely reduced cost.
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


spool btree_cost_02a

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
alter session set events '10053 trace name context forever';
alter session set events '10132 trace name context forever';

prompt
prompt	No null entries
prompt

select
	/*+ 
		index(t1) 
	*/
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


update t1
set
	n1 = null, ind_pad = null, n2 = null
where
	rownum <= 100
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
alter session set events '10053 trace name context forever';
alter session set events '10132 trace name context forever';


prompt
prompt	With some null entries
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

Execution plans for the query in 10g:

a)	With no nulls
---------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=264 Card=1 Bytes=58)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=264 Card=1 Bytes=58)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=184 Card=1633)



b)	With 100 all-null entries
---------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=90 Card=1 Bytes=58)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=90 Card=1 Bytes=58)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=11 Card=80)


#
