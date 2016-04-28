rem
rem	Script:		btree_cost_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Cost Based Oracle"
rem	Purpose:	Index Full scans
rem
rem	Versions tested 
rem		10.0.1.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The call to disable skip scans is there to ensure that
rem	we can get an index full scan
rem

start setenv

alter session set "_optimizer_skip_scan_enabled"=false;

drop table t1;

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


spool btree_cost_03

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
prompt	Force Index Full scan with visit to table.
prompt


select
	/*+ index(t1) */
	small_vc
from
	t1
where	n2	= 2
order by n1
;


prompt
prompt	A query that can be resolved in the index
prompt

select
	/*+ index(t1) */
	n2
from
	t1
where	n1	between 6 and 9
order by n1
;


set autotrace off

spool off

