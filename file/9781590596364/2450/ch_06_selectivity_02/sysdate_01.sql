rem
rem	Script:		sysdate_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Any side effects of using sysdate
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	There are 1440 minutes in a day.
rem
rem	The minutes is a total range of 4.5 days around today
rem	If you run this query some time in a normal working day,
rem	the number of rows before or after 'now' will be about
rem	the same.  ('normal' covering four or five hours either
rem	side of noon). For the purposes of the tests, I set the
rem	clock on the test machine to exactly midday just before 
rem	running the scripts.
rem
rem	At midday exactly, there will be 2,880 rows in the future
rem	(if you include the current second in the count).
rem
rem	At the start of the day (trunc(sysdate)) there would be 
rem	exactly 3,600 in the future (with the rule about including
rem	the current second).
rem
rem	Conclusions:
rem	For the purposes of calculating selectivity:
rem		SYSDATE is a known constant
rem		trunc(sysdate) is a known constant
rem		to_date('dd-mon-yyyy') is a calculated constant
rem
rem		sysdate +/- N is a "bind variable" - using the 5% rule
rem			UNTIL you get to 10g
rem
rem		As a special case: sysdate + 0 is a bind variable
rem

start setenv
set feedback off

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

create table t1 as
select
	rownum					id,
	trunc(sysdate - 2) + (rownum-1)/1440	minutes,
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


column today		new_value m_today	noprint
column yesterday	new_value m_yesterday	noprint
column tomorrow		new_value m_tomorrow	noprint

select 
	to_char(trunc(sysdate)    ,'dd-mon-yyyy') today,
	to_char(trunc(sysdate) - 1,'dd-mon-yyyy') yesterday,
	to_char(trunc(sysdate) + 1,'dd-mon-yyyy') tomorrow
from dual;
 
spool sysdate_01

set autotrace traceonly explain;

prompt
prompt	Variations on sysdate
prompt	=====================
prompt
prompt	= sysdate
prompt	=========

rem
rem	One chance in 60 that you'll actually get a row
rem

select count(*) 
from t1 
where minutes = sysdate;


prompt	> sysdate
prompt	=========

select count(*) 
from t1 
where minutes > sysdate;


prompt	>= sysdate
prompt	==========

select count(*) 
from t1 
where minutes >= sysdate;


prompt	> trunc(sysdate)
prompt	================

select count(*) 
from t1 
where minutes > trunc(sysdate);


prompt	>= trunc(sysdate)
prompt	=================

select count(*) 
from t1 
where minutes >= trunc(sysdate);


prompt
prompt	Variations on a single day range
prompt	================================
prompt
prompt	sysdate to sysdate + 1
prompt	======================
prompt

select count(*) 
from t1 
where minutes between sysdate and sysdate + 1
;

prompt
prompt	trunc(sysdate) to trunc(sysdate + 1)
prompt	====================================
prompt

select count(*) 
from t1 
where minutes between trunc(sysdate) and trunc(sysdate + 1)
;

prompt
prompt	trunc(sysdate) to trunc(sysdate) + 1
prompt	====================================
prompt

select count(*) 
from t1 
where minutes between trunc(sysdate) and trunc(sysdate) + 1
;

prompt	sysdate - 1 to sysdate
prompt	======================
prompt

select count(*) 
from t1 
where minutes between sysdate-1 and sysdate
;

prompt
prompt	trunc(sysdate - 1) to trunc(sysdate)
prompt	====================================
prompt

select count(*) 
from t1 
where minutes between trunc(sysdate-1) and trunc(sysdate)
;

prompt
prompt	trunc(sysdate) - 1 to trunc(sysdate)
prompt	====================================
prompt

select count(*) 
from t1 
where minutes between trunc(sysdate)-1 and trunc(sysdate)
;

prompt
prompt	Variations on a 2 day day range
prompt	===============================
prompt
prompt	sysdate - 1 to sysdate + 1
prompt	==========================
prompt

select count(*) 
from t1 
where minutes between sysdate - 1 and sysdate + 1
;

prompt
prompt	trunc(sysdate) - 1 to trunc(sysdate) + 1
prompt	========================================
prompt

select count(*) 
from t1 
where minutes between trunc(sysdate) - 1 and trunc(sysdate) + 1
;

prompt
prompt	trunc(sysdate - 1) to trunc(sysdate + 1)
prompt	========================================
prompt

select count(*) 
from t1 
where minutes between trunc(sysdate - 1) and trunc(sysdate + 1)
;

prompt
prompt	Variations with literal date-only values
prompt	========================================
prompt
prompt	> to_date({today})
prompt	==================
prompt

select count(*) 
from t1 
where minutes > to_date('&m_today','dd-mon-yyyy');

prompt
prompt	> to_date({literal for yesterday})
prompt	==================================
prompt

select count(*) 
from t1 
where minutes > to_date('&m_yesterday','dd-mon-yyyy');

prompt
prompt	between to_date({yesterday}) and to_date({tomorrow})
prompt	====================================================
prompt

select count(*) 
from t1 
where minutes between to_date('&m_yesterday','dd-mon-yyyy')
		  and to_date('&m_tomorrow','dd-mon-yyyy');


prompt
prompt	between to_date({today}) - 1 and to_date({today}) + 1
prompt	=====================================================
prompt

select count(*) 
from t1 
where minutes between to_date('&m_today','dd-mon-yyyy') - 1
		  and to_date('&m_today','dd-mon-yyyy') + 1;

prompt
prompt	One special warning
prompt	===================
prompt
prompt	>= sysdate + 0
prompt	==============
prompt

select count(*) 
from t1 
where minutes >= sysdate + 0;


set autotrace off

spool off


