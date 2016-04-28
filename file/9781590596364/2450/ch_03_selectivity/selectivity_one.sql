rem
rem	Script:		Selectivity_one.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	For dates and numbers, predicates that
rem	go outside the range return carinalities
rem	that are equivalent to 'column = constant'
rem	(in the absence of histograms at least)
rem	
rem	This is not true for the special case
rem	where the number of distinct values in
rem	a column is ONE - if you are using 9i
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
nologging		-- adjust as necessary
as
select
	decode( mod(rownum,4),
		0, 'England',
		1, 'Northern Ireland',
		2, 'Scotland',
		3, 'Wales',
		   'Great Britain'
	)			country,
	decode( mod(rownum,2),
		0,'Australia',
		1,'America',
		  'Other'
	)			continent,
	'Earth'			planet,
	1			one
from
	all_objects
where
	rownum <= 3000
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

spool selectivity_one

set autotrace traceonly explain

prompt	Equality
prompt	========

select	count(*)
from	t1
where	planet = 'Mars'
;

select	count(*)
from	t1
where	continent = 'Europe'
;

select	count(*)
from	t1
where	country = 'Zog'
;

select	count(*)
from	t1
where	one = 2
;

prompt	Greater Than
prompt	============

select	count(*)
from	t1
where	planet > 'Mars'
;

select	count(*)
from	t1
where	continent > 'Europe'
;

select	count(*)
from	t1
where	country > 'Zog'
;

select	count(*)
from	t1
where	one > 2
;

set autotrace off

spool off

set doc off
doc

results (full scan line only)
-----------------------------
8.1.7.4 
-------
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=3000 Bytes=18000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=1500 Bytes=12000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=750 Bytes=7500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=3000 Bytes=9000)

   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=3000 Bytes=18000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=1500 Bytes=13500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=2 Card=750 Bytes=7500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=3000 Bytes=9000)


9.2.0.6
-------
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=1 Bytes=6)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=1500 Bytes=12000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=750 Bytes=7500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=4 Card=1 Bytes=3)

   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=1 Bytes=6)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=4 Card=1500 Bytes=13500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=3 Card=750 Bytes=7500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=4 Card=1 Bytes=3)



10.1.0.4
--------
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=1 Bytes=6)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=1500 Bytes=13500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=622 Bytes=6220)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=1 Bytes=3)

   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=1 Bytes=6)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=1500 Bytes=13500)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=622 Bytes=6220)
   2    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=4 Card=1 Bytes=3)



#
