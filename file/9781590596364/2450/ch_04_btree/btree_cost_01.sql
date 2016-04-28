rem
rem	Script:		btree_cost_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of costing for "Cost Based Oracle"
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Test conditions:
rem		Locally managed tablespace
rem		Uniform extent size 1M
rem		Block size 8K
rem		Segment space management MANUAL
rem
rem	The purpose of this script is to build in a non-ASSM
rem	tablespace an index with blevel = 2 to demonstrate 
rem	the basic Wolfgang Breitling formula.
rem
rem	I have used dbms_random to populate the index with
rem	500 different combinations, and no correlation between
rem	the two columns indexed.
rem
rem	I have included a single-valued column in the middle
rem	of the index to waste space in the branches without 
rem	materially changing the statistics of the distribution.
rem
rem	I have set the index pctfree to 91% to spread the rows across
rem	a larger number of leaf blocks. (pctfree does not apply to the
rem	branch level).
rem
rem	I have used a 3-column index to allow to demonstrate the effect
rem	of incomplete use of indexes in a later test.
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

rem
rem	I used this line to show that the calculations
rem	were NOT based on the individual column statistics
rem	rather than the user_indexes.distinct_keys value
rem

rem	update t1 set n1 = n2 where n2 in (1,3,5,7,11,13,15,17,19);

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

spool btree_cost_01

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

select
	small_vc
from
	t1
where
	n1	= 2
and	ind_pad	= rpad('x',40)
and	n2	= 3
;

rem
rem	Two columns out of three
rem	(Jumping ahead in the book)
rem

select
	/*+ index(t1 t1_i1) */
	small_vc
from
	t1
where
	n1	= 2
and	ind_pad	= rpad('x',40)
;

select
	small_vc
from
	t1
where
	n1	= 2
and	n2	= 3
;

alter session set events '10053 trace name context off';
set autotrace off

spool off

