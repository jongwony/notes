rem
rem	Script:		in_list.sql
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
rem	The "dire warning".  
rem	An upgrade from 8 to 9 changes the in-list cardinality
rem
rem	We have a table where every value for column N1 returns
rem	100 rows. Under 9i and 10g, a list of two values produces
rem	a cardinality of 200 rows. Under 8i, the eswtimated cardinality
rem	is only 190 rows. This is an error in the optimizer code.
rem	
rem	The in-list is converted to an 'OR' list
rem		n1 = 1 OR n1 = 2
rem
rem	Unfortunately, 8i then treats the two predicates as independent,
rem	so the calculated cardinality is
rem		estimate of rows where n1 = 1	(one in 10 = 100) plus
rem		estimate of rows where n1 = 2	(one in 10 = 100) minus
rem		estimate of rows where 'n1 = 1 and n1 = 2' ... one in 100 = 10.
rem
rem	See the Chapter 3 "Basic Selectivity" for more details
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

create table t1
as
select
	trunc((rownum-1)/100)	n1,
	rpad('x',100)		padding
from
	all_objects
where
	rownum <= 1000
;


begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

set autotrace traceonly explain


spool in_list

select 
	* 
from	t1
where
	n1 in (1,2)
;


set autotrace off

spool off


set doc off
doc

Under 8i, the cardinality of an in-list is too low.

Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=3 Card=190 Bytes=19570)
   1    0   TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=190 Bytes=19570)


Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=4 Card=200 Bytes=20600)
   1    0   TABLE ACCESS (FULL) OF 'T1' (Cost=4 Card=200 Bytes=20600)


Execution Plan (10.1.0.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=4 Card=200 Bytes=20600)
   1    0   TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=200 Bytes=20600)


#

