rem
rem	Script:		char_histograms.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem
rem	The first 32 bytes of the low and high values are recorded.
rem	This includes the space padding for CHAR types.
rem

start setenv
set timing off

execute dbms_random.seed(0);

drop table t1;
purge recyclebin;

create table t1 (
	v10	varchar2(10),
	c10	char(10),
	c40	char(40)
)
;

insert into t1 
select
	val, val, val
from	(
	select
		dbms_random.string('l',trunc(dbms_random.value(6,10.999))) val
	from
		all_objects
	where
		rownum <= 10000
	)
;

commit;

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
rem	A little function to make is possible to call
rem	the conversion routines in dbms_stats from an
rem	SQL statement
rem

create or replace function value_to_varchar2(i_raw in raw)
return varchar2 deterministic as
	m_vc		varchar2(100);
begin
	dbms_stats.convert_raw_value(i_raw,m_vc);
	return m_vc;
end;
/

spool char_histograms

break on column_name skip 1
column column_name format a5

select
	column_name,
	substr(value_to_varchar2(low_value),1,10)	low,
	low_value,
	substr(value_to_varchar2(high_value),1,10)	high,
	high_value
from
	user_tab_columns
where	table_name = 'T1'
;


begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 10'
	);
end;
/


column endpoint_number format 999 heading "End no"

column endpoint_value format 999,999,999,999,999,999,999,999,999,999,999,999 heading "End Value"
column endpoint_actual_value format a42 heading "End act val"

select 
	column_name,
	endpoint_number,
	endpoint_value,
--	endpoint_actual_value
	substr(replace(endpoint_actual_value,' ','.'),1,40) endpoint_actual_value
from
	user_tab_histograms
where
	table_name = 'T1'
order  by
	column_name, endpoint_Number
;

spool off

