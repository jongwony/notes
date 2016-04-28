rem
rem	Script:		defaults.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	Demonstrate the effect of using a silly value to represent
rem	a null value when you want to do a range scan.
rem
rem	The fix is to create a histogram so that Oracle can 
rem	'see the gap' between the real data and the silly value.
rem
rem	For generating a large table in 8i, comment
rem	out the "WITH ... AS" section of code in the
rem	create table statement, and re-instate the 
rem	'create table generator' code.
rem

start setenv

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

create table t1 
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 2000
)
*/
select
	/*+ ordered use_nl(v2) */
	decode(
		mod(rownum - 1,1000),
			0,to_date('31-Dec-4000'),
			  to_date('01-Jan-2000') + trunc((rownum - 1)/100) 
	)	date_closed
from
	generator	v1,
	generator	v2
where
	rownum <= 1827 * 100
;


spool defaults

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


prompt	Column stats with no histogram

select	
	column_name, num_distinct, density
from	user_tab_columns
where	table_name = 'T1'
;

set autotrace traceonly explain

prompt
prompt	Cardinality with default dates, no histogram

select
	*
from	t1
where	date_closed between to_date('01-Jan-2003','dd-mon-yyyy')
		    and     to_date('31-Dec-2003','dd-mon-yyyy')
;

set autotrace off

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 11'
	);
end;
/

prompt	Column stats with histogram (very little change in density)

select	
	column_name, num_distinct, density
from	user_tab_columns
where	table_name = 'T1'
;

prompt	Histogram values - note the very large range of bucket 11

select
	endpoint_number,
	endpoint_value
from
	user_tab_histograms
where
	table_name= 'T1'
and	column_name = 'DATE_CLOSED'
order by
	endpoint_number
;


set autotrace traceonly explain

prompt
prompt	Default dates, with histogram

select 
	*
from	t1
where	date_closed between to_date('01-Jan-2003','dd-mon-yyyy')
		    and     to_date('31-Dec-2003','dd-mon-yyyy')
;

set autotrace off

prompt	Change the default date to null

update t1 set 
	date_closed = null
where
	date_closed = to_date('31-dec-4000','dd-mon-yyyy')
;
 
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

set autotrace traceonly explain

prompt
prompt	Real nulls, no histogram

select 
	*
from	t1
where	date_closed between to_date('01-Jan-2003','dd-mon-yyyy')
		    and     to_date('31-Dec-2003','dd-mon-yyyy')
;

set autotrace off



prompt
prompt	Approximate calculation of cardinality with default date

select
	selectivity,
	182700 * selectivity	cardinality
from	(
	select
		(to_date('31-dec-2003') - to_date('01-jan-2003')) /
		(to_date('31-dec-4000') - to_date('01-jan-2000'))	+
		2/1828		selectivity
	from
		dual
)
;


prompt
prompt	Approximate calculation of cardinality with proper nulls
prompt	(Num_rows - Num_nulls) * selectivity

select
	selectivity,
	(182700 - 183) * selectivity	cardinality
from	(
	select
		(to_date('31-dec-2003') - to_date('01-jan-2003')) /
		(to_date('31-dec-2004') - to_date('01-jan-2000'))	+
		2/1827		selectivity
	from
		dual
	)
;


spool off
