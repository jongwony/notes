rem
rem	Script:		birth_month_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Simple selectivity - month of birth, with nulls
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	See notes in file birth_month_01 for baseline.
rem	In this example, a random ten percent of the audience cannot
rem	remember which month they were born in. This is represented
rem	in the database by setting the month_no to null every 10th row.
rem

start setenv

execute dbms_random.seed(0);

drop table audience;

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

create table audience as
select
	rownum				id,
	trunc(dbms_random.value(1,13))	month_no
from
	all_objects
where
	rownum <= 1200
;

update	
	audience
set	month_no = null
where	mod(id,10) = 0
;

commit;


begin
	dbms_stats.gather_table_stats(
		user,
		'audience',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


rem
rem	A little function to make is possible to call
rem	the conversion routines in dbms_stats from an
rem	SQL statement
rem

create or replace function value_to_number(i_raw in raw)
return number deterministic as
	m_n		number(6);
begin
	dbms_stats.convert_raw_value(i_raw,m_n);
	return m_n;
end;
.
/
	
spool birth_month_02

select
	column_name,
	num_distinct,
	num_nulls,
	density,
	value_to_number(low_value)	low,
	value_to_number(high_value)	high
from
	user_tab_columns
where	table_name = 'AUDIENCE'
;

select 
	column_name, endpoint_number, endpoint_value 
from 
	user_tab_histograms 
where 
	table_name = 'AUDIENCE'
order by
	column_name, endpoint_number
;


set autotrace traceonly explain

select count(*) 
from audience
where month_no = 12
;

set autotrace off

spool off
