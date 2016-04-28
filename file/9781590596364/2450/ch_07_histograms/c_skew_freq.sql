rem
rem	Script:		c_skew_freq.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Demo of histogram affecting access path 
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The algorithm for the table means that the value of skew
rem	will behave as follows if you set m_demo_size = 80
rem		1	will appear once
rem		2	will appear twice
rem		3	will appear three times
rem			...
rem		80	will appear 80 times
rem
rem	Since there only 80 distinct value, we can get a cumulative
rem	frequency histogram by analyzing with more than 80 buckets.
rem	
rem	But in 9i and 10g, we discover that dbms_stats fails to spot
rem	the option for generating a cumulative frequency histogram
rem	until we request 107 buckets. This is bad news for some systems
rem	on the upgrade. If you have more than about 220 buckets in 8i
rem	you may find that you can no longer create a genuine frequency
rem	histogram using gather_table_stats (This bug is fixed in 10.2)
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

prompt	Number of rows in table at m_demo_size = 80 : 3,240
prompt	Number of rows in table at m_demo_size = 10 :    55

select
	count(*)
from
	t1
;

spool c_skew_freq

prompt	The data set

select
	skew, count(*) 
from
	t1 
group by
	skew
order by
	skew
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

prompt
prompt	Without a histogram, the plan will be a tablescan
prompt	First report: density with no histogram
prompt

select
	num_distinct, density, num_Buckets
from
	user_tab_columns
where
	table_name = 'T1'
and	column_name = 'SKEW'
;

set autotrace traceonly explain

select skew, padding 
from t1 
where skew = 5 
;

set autotrace off


begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 120'
	);
end;
/


prompt
prompt	First output: the density with the histogram
prompt	Second output: The histogram 
prompt	Density = 1/(2 * num_rows).
prompt	num_buckets = num_distinct in 10g
prompt	num_buckets = num_distinct - 1 in 8i and 9i
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

prompt
prompt	With column histograms the plan usually will be a range on the
prompt	less frequently used values for skew, and a full scan on the higher
prompt
prompt execution path for skew = 5 with histogram

select 
	skew, padding
from 
	t1 
where 
	skew = 5
;

prompt execution path for skew = 70 with histogram

select 
	skew, padding
from 
	t1 
where 
	skew = 70
;

set autotrace off


prompt
prompt	Using Analytics to turn the histogram
prompt	back into the original data set
prompt

select
	endpoint_value				row_value,
	curr_num - nvl(prev_num, 0)		row_count
from	(
	select
		endpoint_value,
		endpoint_number			curr_num,
		lag(endpoint_number,1) over (
			order by endpoint_number
		)				prev_num
	from
		user_tab_histograms
	where
		column_name = 'SKEW'
	and	table_name = 'T1'
)
order by
	endpoint_value
;


spool off

