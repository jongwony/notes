rem
rem	Script:		join_cost_03a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of NL join costing for "Cost Based Oracle"
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Demonstrates that Oracle MAY use the avg_data_blocks_per_key
rem	and avg_leaf_blocks_per_key to work out cost and cardinality on
rem	nested loop joins.
rem
rem	Based on join_cost_03.sql, but modifying the data.
rem
rem	We rig a driving table to select one row, which Oracle calculates
rem	correctly, then join to our standard target table. The cost on the
rem	INDEX line IS controlled by the avg_leaf_blocks_per_key, the cost on 
rem	TABLE line IS controlled by the avg_data_blocks_per_key.
rem
rem	Note, though, that the cardinality still uses the column selectivity
rem	to predict 16 rows returned. 
rem
rem	Because we are using highly correlated columns, the cost using this 
rem	mechanism is much more appropriate than the cost for a simple indexed 
rem	table access using the standard formula.
rem
rem	To demonstrate the special variation in costing, we do a single 
rem	table query with a suitable set of literals, then do the join.
rem

start setenv

execute dbms_random.seed(0);

drop table driver;
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
	rpad('x',40)			ind_pad,
	trunc(dbms_random.value(0,25))	n1,
	trunc(dbms_random.value(0,25))	n2,
	lpad(rownum,10,'0')		small_vc,
	rpad('x',200)			padding
from
	all_objects
where
	rownum  <= 10000
;


rem
rem	After this update, the two columns in our index 
rem	will are going to be the same - so the index stats
rem	will show distinct_key = 25. But the product of 
rem	the num_distinct on the column stats will be 625
rem

update t1 set n2 = n1;
commit;

create index t1_i1 on t1(ind_pad,n1,n2) 
nologging
pctfree 91
;


create table driver
as
select 
	ind_pad, 
	n1, 
	n2,
	trunc((rownum-1)/2)	double,
	rownum n3
from	(
	select distinct ind_pad, n1, n2
	from t1
)
;

alter table driver add constraint d_pk primary key(n3);

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

begin
	dbms_stats.gather_table_stats(
		user,
		'driver',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


column	n1 new_value m_n1
column	n2 new_value m_n2

select
	n1, n2
from
	driver
where
	n3 = 5
;

select
	blevel,
	avg_leaf_blocks_per_key,
	avg_data_blocks_per_key
from
	user_indexes
where
	table_name = 'T1'
and	index_name = 'T1_I1'

spool join_cost_03a

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';

select
	t1.small_vc
from 
	t1
where 
	t1.ind_pad = rpad('x',40)
and	t1.n1 = &m_n1
and	t1.n2 = &m_n2
;

select 
	/*+ ordered use_nl(t1) index(t1 t1_i1) */
	t1.small_vc
from 
	driver d, 
	t1
where 
	d.n3 = 5
and	t1.ind_pad = d.ind_pad
and	t1.n1 = d.n1
and	t1.n2 = d.n2
;

select 
	/*+ ordered use_nl(t1) index(t1 t1_i1) */
	t1.small_vc
from 
	driver d, 
	t1
where 
	d.double = 5
and	t1.ind_pad = d.ind_pad
and	t1.n1 = d.n1
and	t1.n2 = d.n2
;

alter session set events '10053 trace name context off';
set autotrace off

spool off

set doc off
doc



Execution Plans (10.1.0.4)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=14 Card=16 Bytes=928)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=14 Card=16 Bytes=928)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=4 Card=16)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=292 Card=16 Bytes=1712)
   1    0   NESTED LOOPS (Cost=292 Card=16 Bytes=1712)
   2    1     TABLE ACCESS (BY INDEX ROWID) OF 'DRIVER' (TABLE) (Cost=1 Card=1 Bytes=49)
   3    2       INDEX (UNIQUE SCAN) OF 'D_PK' (INDEX (UNIQUE))
   4    1     TABLE ACCESS (BY INDEX ROWID) OF 'T1' (TABLE) (Cost=291 Card=16 Bytes=928)
   5    4       INDEX (RANGE SCAN) OF 'T1_I1' (INDEX) (Cost=45 Card=16)


Execution Plans (9.2.0.6)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=14 Card=16 Bytes=928)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (Cost=14 Card=16 Bytes=928)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (NON-UNIQUE) (Cost=4 Card=16)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=292 Card=16 Bytes=1712)
   1    0   NESTED LOOPS (Cost=292 Card=16 Bytes=1712)
   2    1     TABLE ACCESS (BY INDEX ROWID) OF 'DRIVER' (Cost=1 Card=1 Bytes=49)
   3    2       INDEX (UNIQUE SCAN) OF 'D_PK' (UNIQUE)
   4    1     TABLE ACCESS (BY INDEX ROWID) OF 'T1' (Cost=291 Card=16 Bytes=928)
   5    4       INDEX (RANGE SCAN) OF 'T1_I1' (NON-UNIQUE) (Cost=45 Card=16)


Execution Plans (8.1.7.4)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=14 Card=16 Bytes=928)
   1    0   TABLE ACCESS (BY INDEX ROWID) OF 'T1' (Cost=14 Card=16 Bytes=928)
   2    1     INDEX (RANGE SCAN) OF 'T1_I1' (NON-UNIQUE) (Cost=4 Card=16)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=292 Card=16 Bytes=1712)
   1    0   NESTED LOOPS (Cost=292 Card=16 Bytes=1712)
   2    1     TABLE ACCESS (BY INDEX ROWID) OF 'DRIVER' (Cost=1 Card=1 Bytes=49)
   3    2       INDEX (UNIQUE SCAN) OF 'D_PK' (UNIQUE)
   4    1     TABLE ACCESS (BY INDEX ROWID) OF 'T1' (Cost=291 Card=10000 Bytes=580000)
   5    4       INDEX (RANGE SCAN) OF 'T1_I1' (NON-UNIQUE) (Cost=45 Card=10000)


#
