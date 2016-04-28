rem
rem	Script:		bitmap_or.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	An anomaly with bitmap cardinality calculations
rem	when the CBO does a bitmap OR.
rem
rem	It seems to lose track of the num_nulls value in
rem	in user_tab_columns 
rem
rem	The problem does not appear with bitmap AND
rem
rem	The problem appears whether the bitmap is generated 
rem	from a B-tree or whether the index is a genuine bitmap
rem	index to start with
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


rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;

/*
*/


create table t1 
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select
	/*+ ordered use_nl(v2) */
	decode(
		mod(rownum-1,1000), 
			0, rownum - 1,
			   null
	)			n1,
	decode(
		mod(rownum-1,1000), 
			0, rownum - 1,
			   null
	)			n2,
	lpad(rownum-1,10,'0')	small_vc
from
	generator	v1,
	generator	v2
where
	rownum <= 1000000
;

create bitmap index t1_i1 on t1(n1);
create bitmap index t1_i2 on t1(n2);

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

spool bitmap_or

select
	column_name, 
	num_distinct,
	num_nulls,
	density
from
	user_tab_columns
where
	table_name = 'T1'
;

alter session set "_b_tree_bitmap_plans" = true;

set autotrace traceonly explain

select
	small_vc
from
	t1
where
	n1 = 50000
;

select
	small_vc
from
	t1
where
	n2 = 50000
;

select
	small_vc
from
	t1
where
	n1 = 50000
or	n2 = 50000
;

select
	small_vc
from
	t1
where
	n1 = 50000
or	(n2 = 50000 and n2 is not null)
;

select
	small_vc
from
	t1
where
	(n1 = 50000 and n1 is not null)
or	(n2 = 50000 and n2 is not null)
;

set autotrace off

spool off

