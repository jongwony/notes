rem
rem	Script:		hist_sel.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Examples of selectivity/cardinality with
rem	height-balanced histograms
rem

start setenv
set pagesize 55

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
	rownum 	n1
from	all_objects 
where	rownum <= 2000
;



create table t1 
as
/*
with generator as (
	select	--+ materialize
		rownum 	n1
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	/*+ ordered use_nl(v2) */
	3000 + trunc(2000 * dbms_random.normal)	n1,
	lpad(rownum,10)				small_vc,
	rpad('x',100)				padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
;

insert into t1 
select
	500 * (1 + trunc((rownum-1)/500)),
	lpad(rownum,10),
	rpad('x',100)
from
	t1
;

commit;

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 250'
	);
end;
/

spool hist_sel

select
	num_distinct, density, num_Buckets
from
	user_tab_columns
where
	table_name = 'T1'
and	column_name = 'N1'
;


select
	endpoint_number, endpoint_value
from
	user_tab_histograms
where
	column_name = 'N1' 
and	table_name = 'T1'
order by
	endpoint_number
;


set autotrace traceonly explain

select 
	small_vc
from	t1
where	n1 between 100 and 200
;


select 
	small_vc
from	t1
where	n1 between 400 and 600
;


set autotrace traceonly explain

spool off
