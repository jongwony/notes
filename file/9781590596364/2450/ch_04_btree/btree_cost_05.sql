rem
rem	Script:		btree_cost_05.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Cost Based Oracle"
rem	Purpose:	Impact of CPU costing on plans
rem
rem	Versions tested 
rem		10.0.1.3
rem		 9.2.0.6
rem
rem	Not relevant
rem		 8.1.7.4
rem

start setenv

alter session set "_optimizer_cost_model" = cpu;

begin
	dbms_stats.set_system_stats('MBRC',8);
	dbms_stats.set_system_stats('MREADTIM',20);	-- millisec
	dbms_stats.set_system_stats('SREADTIM',10);	-- millisec
	dbms_stats.set_system_stats('CPUSPEED',350);	-- "MHz"
end;
/

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
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

spool btree_cost_05

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

select	
	/*+ index(t1) cpu_costing */
	small_vc
from
	t1
where
	ind_pad	= rpad('x',40)
and	n1		= 2
and	n2		in (5,6,7)
;

select	
	/*+ index(t1) nocpu_costing */
	small_vc
from
	t1
where
	ind_pad	= rpad('x',40)
and	n1		= 2
and	n2		in (5,6,7)
;

select	
	/*+ full(t1) cpu_costing */
	small_vc
from
	t1
where
	ind_pad	= rpad('x',40)
and	n1		= 2
and	n2		in (5,6,7)
;

select	
	/*+ full(t1) nocpu_costing */
	small_vc
from
	t1
where
	ind_pad	= rpad('x',40)
and	n1		= 2
and	n2		in (5,6,7)
;

set autotrace off

spool off

