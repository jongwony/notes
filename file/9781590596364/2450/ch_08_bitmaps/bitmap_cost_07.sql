rem
rem	Script:		bitmap_cost_07.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem

start setenv

rem	alter session set "_b_tree_bitmap_plans"=true;
rem	alter session set "_b_tree_bitmap_plans"=false;

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



/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;

*/


select

create table t1 (
	id,
	n1		not null,
	n2		not null,
	small_vc,
	padding
)
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
select
	/*+ ordered use_nl(v2) */
	rownum					id,
	trunc(dbms_random.value(0,50))		n1,
	trunc(dbms_random.value(0,50))		n2,
	lpad(rownum,10)				small_vc,
	rpad('x',100)				padding
from
	generator	v1,
	generator	v2
where
	rownum <= 1000000
;

create index t1_i1 on t1(n1);
create index t1_i2 on t1(n2);

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/


spool bitmap_cost_07

select
	num_rows, blocks
from
	user_tables
where
	table_name = 'T1'
;


select
	index_name, 
	blevel, 
	leaf_blocks, 
	distinct_keys, 
	clustering_factor
from
	user_indexes
where
	table_name = 'T1'
;

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';


prompt	Hinted bitmap combine

select
	/*+ index_combine(t1 t1_i1 t1_i2) */
	small_vc
from
	t1
where
	n1 = 33
and	n2 = 21
;

prompt	Unhinted

select
	small_vc
from
	t1
where
	n1 = 33
and	n2 = 21
;


select
	/*+ and_equal(t1 t1_i1 t1_i2) */
	small_vc
from
	t1
where
	n1 = 33
and	n2 = 21
;

alter session set events '10053 trace name context off';
set autotrace off

spool off

