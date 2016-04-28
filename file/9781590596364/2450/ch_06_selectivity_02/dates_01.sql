rem
rem	Script:		dates_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Any side effects of dates in general
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	There are 1440 minutes in a day.
rem
rem	The minutes is a total range of 4.5 days around today
rem	If you are working a normal set of hours, the number
rem	of rows before and after 'now' will be roughly even.
rem
rem	to_date() with full format string
rem	to_date() with 'RRRR' in string
rem	to_date() with 'RR' in string
rem	to_date() + N
rem	
rem	DATE 'yyyy-mon-dd hh24:mi:ss'
rem
rem	Do any of the common formats change the selectivity calculations ?
rem

start setenv
set timing off

drop table t1;
create table t1 as
select
	rownum					id,
	trunc(sysdate - 2) + rownum/1440	minutes,
	lpad(rownum,10)				small_vc,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 6480
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


column date4 new_value m_date_yyyy
column date2 new_value m_date_yy

select
	to_char(sysdate,'yyyy-mon-dd hh24:mi:ss') date4,
	to_char(sysdate,  'yy-mon-dd hh24:mi:ss') date2
from
	dual
;

spool dates_01

set autotrace traceonly explain;

prompt
prompt	Unbounded Range
prompt

select count(*) 
from t1 
where 
	minutes > to_date('&m_date_yyyy','yyyy-mon-dd hh24:mi:ss');


select count(*) 
from t1 
where 
	minutes > to_date('&m_date_yyyy','rrrr-mon-dd hh24:mi:ss');


select count(*) 
from t1 
where 
	minutes > to_date('&m_date_yy','rr-mon-dd hh24:mi:ss');

prompt
prompt	Bounded Range - to_date() to to_date()+1
prompt

select count(*) 
from t1 
where 
	minutes between	to_date('&m_date_yyyy','yyyy-mon-dd hh24:mi:ss')
		and	to_date('&m_date_yyyy','yyyy-mon-dd hh24:mi:ss') + 1;

select count(*) 
from t1 
where 
	minutes between	to_date('&m_date_yyyy','rrrr-mon-dd hh24:mi:ss')
		and	to_date('&m_date_yyyy','rrrr-mon-dd hh24:mi:ss') + 1;

select count(*) 
from t1 
where 
	minutes between to_date('&m_date_yy','rr-mon-dd hh24:mi:ss')
		and	to_date('&m_date_yy','rr-mon-dd hh24:mi:ss') + 1;


set autotrace off

spool off

set doc off
doc

Cardinality results (at about 8:00 am) from explain plan

	= sysdate	1

	> sysdate	3127	-- correct (+/- 1)
	>= sysdate	3128	-- correct (+/- 1)

	between sysdate-1 and sysdate			168
	between trunc(sysdate-1) and trunc(sysdate)	145

	between sysdate and sysdate + 1			157
	between trunc(sysdate) and trunc(sysdate) + 1	181

#

