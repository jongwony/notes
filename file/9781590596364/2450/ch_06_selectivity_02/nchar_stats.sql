rem
rem	Script:		nchar_stats.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2003
rem	Purpose:	Demo of how character columns have limited statistics
rem
rem	Last tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Repeats char_stats.sql, but using national character sets.
rem	In this example, the database using a 2-byte fixed length
rem	character set. Which makes the character precision even
rem	worse.
rem

start setenv

drop table t1;


create table t1
nologging
as

create table t1 (
	v1	nvarchar2(18)
)
;

insert into t1 
select
	lpad(rownum, 18, '0')
from
	all_objects
;

create index i1 on t1(v1)
nologging
;

analyze table t1 compute statistics;

spool nchar_stats

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


spool off
