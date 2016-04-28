rem
rem	Script:		birth_month_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Simple selectivity - month of birth.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	When hacking the stats with the 'set_column_stats' package,
rem	10g picks up the new statistics automatically, earlier 
rem	versions will only do so if the old statistics are flushed
rem	from the shared pool.
rem
rem	The following comments relate specifically to the query:
rem		where month_no = 12
rem	and Oracle 10g
rem
rem	If you run hack_stats.sql to modify the num_distinct and the
rem	density, you will find that the NUM_DISTINCT is used to estimate
rem	the CARD in the full tablescan if there is no histogram.
rem
rem	If you change the method_opt to 'for all columns size 6', you 
rem	will find that Oracle creates a height-balanced histogram, and 
rem	the DENSITY will be used to estimate the CARD in the full tablescan.
rem
rem	If you use more than 12 buckets (there are twelve distinct values)
rem	Oracle will build a frequency histogram, and report exactly the number
rem	of rows with the value 12, whatever you do in hack_stats.  This will
rem	also occur in Oracle 8i if you use exactly 12 buckets - the mechanism 
rem	for building a histogram changed from 8i to 9i, and the results are
rem	slightly different.
rem
rem	For 9i and 10g, the histogram with 12 buckets happens to produce
rem	a special case: the number of rows with the value 12 covers two 
rem	buckets, so Oracle reports the results as 'two buckets worth'
rem	whatever you do in hack_stats.
rem
rem	Oracle 8i and Oracle 9i behave a little differently from 10g
rem	in their choice of num_distinct and density.
rem
rem	Oracle 8i always uses the DENSITY to calculate the CARD.
rem
rem	Oracle 9i uses the same strategy (NUM_DISTINCT if there is no 
rem	histogram, DENSITY if there is) - but you have to flush the 
rem	shared pool after changing the statistics, or Oracle does not
rem	pick up the new values.
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
	trunc(dbms_random.value(1,13))	month_no
from
	all_objects
where
	rownum <= 1200
;


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
	
spool birth_month_01

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
and	column_name = 'MONTH_NO'
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

accept x prompt 'Now use hack_stats.sql to change distinct or density'

alter system flush shared_pool;

select count(*) 
from audience
where month_no = 12
;

set autotrace off

spool off
