rem
rem	Script:		c_skew_freq_01.sql
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
rem	Tests for cardinality correctness
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

spool c_skew_freq_01

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


variable b1 number
variable b2 number

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';

prompt	column = constant (skew = 40)

select	* 
from	t1
where	skew = 40
;

prompt	column = in-range, non-existent constant (skew = 40.5)

select	* 
from	t1
where	skew = 40.5
;

prompt	Between mapped values (skew between 21 and 24)

select	* 
from	t1
where	skew between 21 and 24 
;

prompt	Between unmapped values (skew between 20.5 and 24.5)

select	* 
from	t1
where	skew between 20.5 and 24.5
;

prompt	Between extreme range (skew between 1 and 2)

select	* 
from	t1
where	skew between 1 and 2
;

prompt	Between extreme range (skew between 79 and 80)

select	* 
from	t1
where	skew between 79 and 80
;

prompt	greater than / less than (skew > 4 and skew < 8)

select	* 
from	t1
where	skew > 4 and skew < 8
;

prompt	Above high value (skew = 100)

select	* 
from	t1
where	skew = 100
;

prompt	Below low value (skew = -10)

select	* 
from	t1
where	skew = -10
;

prompt	Range below low (skew between -5 and -3)

select	* 
from	t1
where	skew between -5 and -3
;


prompt	Range above high (skew between 92 and 94)

select	* 
from	t1
where	skew between 92 and 94
;


prompt	Range above high (skew between 79 an 82)

select	* 
from	t1
where	skew between 79 and 82
;

prompt	column = bind 

select	* 
from	t1
where	skew = :b1
;

prompt	column between bind1 and bind2 

select	* 
from	t1
where	skew between :b1 and :b2
;

alter session set events '10053 trace name context off';
set autotrace off

spool off
