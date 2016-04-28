rem
rem	Script:		join_cost_03b.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration of NL join costing for "Cost Based Oracle"
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Based on join_cost_03.sql, bur re-arranges the index order,
rem	and then does not join on the ind_pad column (which has only
rem	one distinct value anyway).
rem
rem	This is to show that Oracle will change the calculation of
rem	cost if the index on the second table is not fully utilised
rem	in the join.
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
	trunc(dbms_random.value(0,25))	n1,
	trunc(dbms_random.value(0,25))	n2,
	rpad('x',40)			ind_pad,
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

create index t1_i1 on t1(n1,n2,ind_pad) 
nologging
pctfree 91
;


create table driver
as
select 
	n1, 
	n2,
	ind_pad, 
	trunc((rownum-1)/2)	double,
	rownum n3
from	(
	select distinct n1, n2, ind_pad
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

spool join_cost_03b

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';

select
	t1.small_vc
from 
	t1
where 
	t1.n1 = &m_n1
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
and	t1.n1 = d.n1
and	t1.n2 = d.n2
;

alter session set events '10053 trace name context off';
set autotrace off

spool off

