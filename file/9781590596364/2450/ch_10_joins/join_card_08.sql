rem
rem	Script:		join_card_08.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	We forget about filter columns for the moment,
rem	and look at queries which join three tables.
rem
rem	We demonstrate:
rem	How Oracle works out join selectivity when there
rem	are multiple columns in the join.
rem	How Oracle identifies the selectivity of a column
rem	in the intermediate result.
rem	How changing the SQL can affect the join cardinality
rem	when in theory it shouldn't
rem	How adding redundant join predicates can affect the
rem	cardinality badly.
rem
rem	We also discover that 10g has a 'sanity check' for
rem	multi-column joins. Instead of using greater((ndv))
rem	for each predicate individually, it uses all the
rem	ndv() from just one of the two tables - whichever
rem	product gives it the larger product.
rem
rem	To work out the three-table join - we start with 
rem	the first two tables:
rem
rem	Join Selectivity = {join1 bit} * {join2 bit} =
rem		((10000 – 0) / 10000) * 
rem		((10000 – 0) / 10000) /
rem		greater (36 , 40)		*		
rem
rem		((10000 – 0) / 10000) * 
rem		((10000 – 0) / 10000) /
rem		greater (38 , 40)		=	1/1600
rem
rem	Join Cardinality =
rem		1/1600 * 
rem		10000  * 1000 = 62,500
rem
rem	Then we join the intermediate result to table t3
rem
rem	Join Selectivity = {join2 bit} * {join3 bit} * {join4 bit} =
rem		((10000 – 0) / 10000) * 
rem		((10000 – 0) / 10000) /
rem		greater( 37, 38)		*
rem
rem		((10000 – 0) / 10000) * 
rem		((10000 – 0) / 10000) /
rem		greater( 39, 42)		*
rem
rem		((10000 – 0) / 10000) * 
rem		((10000 – 0) / 10000) /
rem		greater( 41, 40)		=	1/65,436
rem
rem	Join Cardinality =
rem		1 / 65436 * 
rem		62500 * 10000 = 9,551	(As required)
rem


start setenv
set timing off

define t1j1 = 40
define t1j2 = 40
define t1j3 = 40
define t1j4 = 40

define t2j1 = 36
define t2j2 = 38
define t2j3 = 42

define t3j2 = 37
define t3j3 = 39
define t3j4 = 41

execute dbms_random.seed(0)

drop table t3;
drop table t2;
drop table t1;

begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
end;
/


begin
	execute immediate 'execute dbms_stats.delete_system_stats';
exception
	when others then null;
end;
/


create table t1 
as
select
	trunc(dbms_random.value(0, &t1j1 ))	join1,
	trunc(dbms_random.value(0, &t1j2 ))	join2,
	trunc(dbms_random.value(0, &t1j3 ))	join3,
	trunc(dbms_random.value(0, &t1j4 ))	join4,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where 
	rownum <= 10000
;


create table t2
as
select
	trunc(dbms_random.value(0, &t2j1 ))	join1,
	trunc(dbms_random.value(0, &t2j2 ))	join2,
	trunc(dbms_random.value(0, &t2j3 ))	join3,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;

create table t3
as
select
	trunc(dbms_random.value(0, &t3j2 ))	join2,
	trunc(dbms_random.value(0, &t3j3 ))	join3,
	trunc(dbms_random.value(0, &t3j4 ))	join4,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
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
		't3',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool join_card_08

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

rem
rem	NOTE
rem		t3.join2 = t2.join2
rem	and	t2.join2 = t1.join2
rem	so we know
rem		t3.join2 = t1.join1
rem
rem	The cardinality changes depending on
rem	which ONE predicate we put into the
rem	query - as the selectivity in the 
rem	intermediate result comes from the
rem	table referenced in the predicate
rem
rem	The cardinality goes very bad if we
rem	put BOTH predicates into the query
rem

select	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.join1 = t1.join1
and	t2.join2 = t1.join2
--
and	t3.join2 = t2.join2
and	t3.join3 = t2.join3
--
and	t3.join4 = t1.join4
;

select	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.join1 = t1.join1
and	t2.join2 = t1.join2
--
and	t3.join3 = t2.join3
--
and	t3.join2 = t1.join2
and	t3.join4 = t1.join4
;

select	t1.v1, t2.v1, t3.v1
from
	t1,
	t2,
	t3
where
	t2.join1 = t1.join1
and	t2.join2 = t1.join2
--
and	t3.join2 = t2.join2
and	t3.join3 = t2.join3
--
and	t3.join2 = t1.join2
and	t3.join4 = t1.join4
;

alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit

set doc off
doc


Execution PlanS (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=212 Card=9551 Bytes=573060)
   1    0   HASH JOIN (Cost=212 Card=9551 Bytes=573060)
   2    1     TABLE ACCESS (FULL) OF 'T3' (TABLE) (Cost=53 Card=10000 Bytes=200000)
   3    1     HASH JOIN (Cost=120 Card=62500 Bytes=2500000)
   4    3       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=54 Card=10000 Bytes=200000)
   5    3       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=200000)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=212 Card=9301 Bytes=558060)
   1    0   HASH JOIN (Cost=212 Card=9301 Bytes=558060)
   2    1     TABLE ACCESS (FULL) OF 'T3' (TABLE) (Cost=53 Card=10000 Bytes=200000)
   3    1     HASH JOIN (Cost=120 Card=62500 Bytes=2500000)
   4    3       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=54 Card=10000 Bytes=200000)
   5    3       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=200000)




Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=109 Card=9551 Bytes=573060)
   1    0   HASH JOIN (Cost=109 Card=9551 Bytes=573060)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=28 Card=10000 Bytes=200000)
   3    1     HASH JOIN (Cost=62 Card=62500 Bytes=2500000)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=29 Card=10000 Bytes=200000)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=10000 Bytes=200000)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=109 Card=9074 Bytes=544440)
   1    0   HASH JOIN (Cost=109 Card=9074 Bytes=544440)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=28 Card=10000 Bytes=200000)
   3    1     HASH JOIN (Cost=62 Card=62500 Bytes=2500000)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=29 Card=10000 Bytes=200000)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=10000 Bytes=200000)


Execution Plan (8.1.7.4. autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=114 Card=9551 Bytes=573060)
   1    0   HASH JOIN (Cost=114 Card=9551 Bytes=573060)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=27 Card=10000 Bytes=200000)
   3    1     HASH JOIN (Cost=63 Card=62500 Bytes=2500000)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=10000 Bytes=200000)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=27 Card=10000 Bytes=200000)

   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=114 Card=9074 Bytes=544440)
   1    0   HASH JOIN (Cost=114 Card=9074 Bytes=544440)
   2    1     TABLE ACCESS (FULL) OF 'T3' (Cost=27 Card=10000 Bytes=200000)
   3    1     HASH JOIN (Cost=63 Card=62500 Bytes=2500000)
   4    3       TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=10000 Bytes=200000)
   5    3       TABLE ACCESS (FULL) OF 'T2' (Cost=27 Card=10000 Bytes=200000)

#
