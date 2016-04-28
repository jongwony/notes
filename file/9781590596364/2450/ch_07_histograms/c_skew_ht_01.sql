rem
rem	Script:		c_skew_ht_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Demo of histogram affecting access path 
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	A few examples based on the table from c_skew_ht.sql
rem	Note - the cardinality of the non-popular select 
rem	on  8i is roughly half that of 9i and 10g because
rem	of the different algorithm used to produce the density.
rem

start setenv 

define m_demo_size=80

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
where	rownum <= 2000
;



create table t1 (
	skew		not null,	
	padding
)
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	/*+ ordered use_nl(v2) */
	v1.id,
	rpad('x',400)
from
	generator	v1,
	generator	v2
where
	v1.id <= &m_demo_size
and	v2.id <= &m_demo_size
and	v2.id <= v1.id
order by 
	v2.id,v1.id
;

create index t1_i1 on t1(skew);

spool c_skew_ht_01

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 75'
	);
end;
/

select
	num_distinct, density, num_Buckets
from
	user_tab_columns
where
	table_name = 'T1'
and	column_name = 'SKEW'
;


select
	endpoint_number, endpoint_value
from
	user_tab_histograms
where
	column_name = 'SKEW' 
and	table_name = 'T1'
order by
	endpoint_number
;


set autotrace traceonly explain

prompt	equality on a popular value - uses bucket counts

select 
	count(*)
from	t1
where	skew = 77
;


prompt	equality on a non-popular value - uses density

select 
	count(*)
from	t1
where	skew = 75
;

set autotrace off


spool off
