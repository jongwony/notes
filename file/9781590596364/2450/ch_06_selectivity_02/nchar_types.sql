rem
rem	Script:		nchar_types.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Notes:
rem	Repeats char_types.sql - but using a two-byte national character set.
rem	Note how the end_point_values are remarkably different.
rem	The optimizer uses a fixed number of BYTES from the
rem	string, not a fixed number of characters.
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

create table t1 (
	v10	nvarchar2(10),
	c10	nchar(10)
)
;

insert into t1 values('Apple','Apple');
insert into t1 values('Blueberry','Blueberry');
insert into t1 values('Aardvark','Aardvark');
insert into t1 values('Zymurgy','Zymurgy');

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

spool nchar_types

break on column_name skip 1
column column_name format a5 heading "Col"

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


rem	analyze table t1 compute statistics for table for all indexes for all columns size 10;

column endpoint_number format 999 heading "End no"

column endpoint_value format 999,999,999,999,999,999,999,999,999,999,999,999 heading "End Value"
column endpoint_actual_value format a42 heading "End act val"

select 
	column_name,
	endpoint_number,
	endpoint_value,
	substr(replace(endpoint_actual_value,' ','.'),1,42) endpoint_actual_value
from
	user_tab_histograms
where
	table_name = 'T1'
order  by
	column_name, endpoint_Number
;

spool off

