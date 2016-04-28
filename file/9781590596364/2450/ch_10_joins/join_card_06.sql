rem
rem	Script:		join_card_06.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Demonstrate the effect of varying the overlap
rem
rem	If there are no histograms, then variations in
rem	the overlap have no effect.
rem
rem	If there are histograms in place, then the arithmetic
rem	changes IF the histogram indicates the presence of
rem	popular values.  (Note - the 8i calculations seem to
rem	be different from the 9i and 10g calculations).
rem
rem	Set t1off (&m_offset) to be 0 for no overlap.
rem	Set buckets (&m_buckets) to be 1 for no histograms
rem
rem	Examples for 8i - with overlap = 50
rem		buckets = 85	cardinality =   328,109
rem		buckets = 84	cardinality =   322,167
rem		buckets = 83	cardinality =   336,838
rem		buckets = 82	cardinality = 1,000,000
rem		buckets = 81	cardinality =   346,040
rem		buckets = 80	cardinality = 1,000,000
rem		buckets = 79	cardinality =   355,752
rem		buckets = 78	cardinality =   348,960
rem		buckets = 77	cardinality = 1,000,000
rem		buckets = 76	cardinality =   367,218
rem	Note - the real number of rows was 513,404
rem
rem	Examples for 9i/10g - with overlap = 50
rem		buckets = 91	cardinality =   548,019
rem		buckets = 87	cardinality = 1,000,000
rem		buckets = 86	cardinality = 1,000,000
rem		buckets = 85	cardinality =   538,364
rem		buckets = 80	cardinality = 1,000,000
rem	Note - 9i, 10g got closer to the real value than 8i
rem	when they didn't use the default approach.
rem
rem	In all cases where the value 1,000,000 appears, the
rem	number of buckets matched the number of end-points
rem	stored (minus one, because you need n+1 end-points
rem	to record n buckets).
rem

start setenv
set feedback off
set timing off

define buckets = &m_buckets
define t1off = &m_offset

define t1j1 = 100
define t2j1 = 100

execute dbms_random.seed(0)

drop table t2;
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
	&t1off + trunc(dbms_random.value(0, &t1j1 ))	join1,
	lpad(rownum,10)					v1,
	rpad('x',100)					padding
from
	all_objects
where 
	rownum <= 10000
;


create table t2
as
select
	trunc(dbms_random.value(0, &t2j1 ))		join1,
	lpad(rownum,10)					v1,
	rpad('x',100)					padding
from
	all_objects
where
	rownum <= 10000
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

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size &buckets'
	);
end;
/


begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size &buckets'
	);
end;
/


spool join_card_06

select 
	min(join1), max(join1)
from	t1
;

set autotrace traceonly explain

alter session set events '10053 trace name context forever';

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
;

alter session set events '10053 trace name context off';

set autotrace off


select count(*)
from
	t1,
	t2
where
	t2.join1 = t1.join1
;

select
	table_name, 
	max(endpoint_number)	requested_buckets,
	count(*) - 1		stored_buckets
from
	user_tab_histograms
where	table_name in ('T1','T2')
and	column_name = 'JOIN1'
group by
	table_name
;

spool off

rem	exit


set doc off
doc


Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------


Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=58 Card=1000000 Bytes=28000000)
   1    0   HASH JOIN (Cost=58 Card=1000000 Bytes=28000000)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=27 Card=10000 Bytes=140000)
   3    1     TABLE ACCESS (FULL) OF 'T2' (Cost=27 Card=10000 Bytes=140000)


Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------

#
