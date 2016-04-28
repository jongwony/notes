rem
rem	Script:		char_types.sql
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
rem
rem	The first 32 bytes of the low and high values are recorded.
rem	This includes the space padding for CHAR types. 
rem
rem	An oddity with Oracle 8, when you generate the histogram 
rem	with a call to dbms_stats, you don't get one if the number
rem	of distinct value is less than the number of buckets requested.
rem
rem	Even in Oracle 9 and 10, the normal rule about 'small number
rem	of distinct values' is not the same for character types. We
rem	have end-point numbers of 1,2,3,4, rather than endpoint numbers
rem	taking on the values, and endpoint values generating a cumulative
rem	frequency graph.
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
	v10	varchar2(10),
	c10	char(10)
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

spool char_types

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

rem
rem	How to calculate the value of Aardvark
rem	when it is stored as a char(10) - note
rem	the rpad() to 10 using spaces.
rem
rem	Also shows a definition for 'Apple' as 
rem	a char(10) and varchar(10)
rem

declare
	m_vc varchar2(15) := rpad((rpad('Aardvark',10,' ')),15,chr(0));
--	m_vc varchar2(15) := rpad((rpad('Apple',10,' ')),15,chr(0));
--	m_vc varchar2(15) := rpad('Apple',               15,chr(0));
	m_n number := 0;
begin
	dbms_output.put_line('ASCII' || chr(9) || '256 to the power 15 - N');
	dbms_output.put_line('-----' || chr(9) || '=======================');
	for i in 1..15 loop

		dbms_output.put(ascii(substr(m_vc,i,1)));
		dbms_output.put(chr(9));
		dbms_output.put_Line(
			to_char(
				power(256,15-i) * ascii(substr(m_vc,i,1)),
				'999,999,999,999,999,999,999,999,999,999,999,999'
			)
		);
		m_n := m_n + power(256,15-i) * ascii(substr(m_vc,i,1));
	end loop;
	dbms_output.new_line;
	dbms_output.put_line(chr(9) || 'Summed value');
	dbms_output.put_line(chr(9) || '============');
	dbms_output.put_line(chr(9) || to_char(m_n,'999,999,999,999,999,999,999,999,999,999,999,999'));
end;
.
/

spool off

