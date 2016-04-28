rem
rem	Script:		reverse.sql
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
rem	Dump a list of sequential numbers sorted by the internal
rem	form of their reversed representation.
rem
rem	This gives an indication of how scattered a sequence based
rem	index will become if you create it as a REVERSE KEY index.
rem

start setenv
set timing off

spool reverse

select 
	substr(dump(reverse(100000+rownum),16),13,30) reversed,
	1000000 + rownum
from 
	all_objects
where 
	rownum <= 1000
order by 
	reversed
;

spool off
