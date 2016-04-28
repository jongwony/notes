rem
rem	Script:		char_stats.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2003
rem	Purpose:	Demo of how character columns have limited statistics
rem
rem	Last tested 
rem		 9.2.0.4 
rem		 8.1.7.4
rem
rem	Oracle takes the first 15 characters of the string, padding
rem	if necessary, and converts to decimal, reducing to 15 digits
rem	of precision.  If there is information loss in this fifteen 
rem	digits, the EAV (endpoint_actual_value) holds the first 32 
rem	bytes of the string.
rem

start setenv

drop table t1;

create table t1
nologging
as
select
	lpad(rownum, 35, '0')	v1
from
	all_objects
;

create index i1 on t1(v1)
nologging
;

analyze table t1 compute statistics;

spool char_stats

rem
rem	Note how low/high hold only 32 characters.
rem	Num_distinct is 22 under 8.1.7.4, dbms_stats correctly gets 22,000 
rem	Density matches the error.
rem	The same error occurs in 9.2.0.4
rem

prompt	After a call to Analyze

select
	num_distinct,
	density,
	low_value, 
	high_value 
from
	user_tab_columns
where
	table_name = 'T1'
and	column_name = 'V1'
;

select 
	index_name,
	num_rows,
	distinct_keys
from
	user_indexes
where	table_name = 'T1'
and	index_name = 'I1'
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


rem
rem	8.1.7.4 gets things right with the call to dbms_stats
rem

prompt	After a call to dbms_stats (no histograms)

select
	num_distinct,
	density,
	low_value, 
	high_value 
from
	user_tab_columns
where	table_name = 'T1'
;


select 
	index_name,
	num_rows,
	distinct_keys
from
	user_indexes
where	table_name = 'T1'
and	index_name = 'I1'
;


begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 254'
	);
end;
/



column epv format 999,999,999,999,999,999,999,999,999,999,999,999


select
	endpoint_number				epn,
	endpoint_value				epv,
	substr(endpoint_actual_value,1,40)	eav
from
	user_tab_histograms
where
	table_name = 'T1'
and	column_name = 'V1'
order by
	endpoint_number
;

rem
rem	Note how the histogram value stored as an approximate
rem	numeric representation of the first 15 bytes of the string
rem	(The '0' is a 0x30 in ASCII, which is the value 48 in decimal).
rem

select
	48 +
	48 * 256 +
	48 * 256 * 256 +
	48 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 + 
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 +
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 + 
	48 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 * 256 epv
from dual
;


spool off
