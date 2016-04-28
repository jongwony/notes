rem
rem	Script:		unnest_cost_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		July 2004
rem	Purpose:	Investigation of FILTER and UNEST operations
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Does Oracle 10 choose a filter for an existence
rem	subquery. It should do based on costing. But 
rem	sometimes things seem to get pre-empted.
rem
rem	It was possible to rig a query where 9i and 10g
rem	had a cheaper cost for the FILTER - and they 
rem	both took hash joins. But in fact, these were
rem	semi-joins - which suggests that there is some
rem	'heuristic' decision (i.e. rule) which promotes
rem	semi-joins over simple unnesting.
rem
rem	If you disable semi-joins, using 
rem		alter session set "_always_semi_join"=off
rem	then the filter is chosen by default.
rem
rem	Interesting note - the hash_sj hint allowed 
rem	Oracle 10 to do a RIGHT SEMI join - which is
rem	what it wanted to do by default.
rem
rem	Oracle 9.2 had an option for turning the subquery
rem	into a "distinct" in-line view, which was then not
rem	a semi join.
rem
rem	The cost of this type of existence FILTER in 10g is
rem		Cost of driving table +
rem			num_distinct of join keys * cost of second table
rem
rem	This holds even when
rem		distinct values in main table > distinct values in filter
rem	or
rem		distinct values in main table > size of max hash table
rem
rem	Note - the hash_sj, merge_sj, and nl_sj hints are deprecated in 10g
rem	along with the corresponding anti-join hints: hash_aj, merge_aj, and nl_aj.
rem	This is probably because they should not be needed, and could be replaced
rem	by a simple use_hash, use_merge, or use_nl hint (along with a couple of
rem	other suitable hints such as semijoin_driver) - but I haven't worked
rem	out how this can be done yet.
rem
rem	The NL_SJ hint is either non-existent in 8i, or is the de facto
rem	meaning of a FILTER, as we do not see a NESTED LOOP (SEMI) when 
rem	we run this script against 8i
rem

start setenv
set timing off

define m_main_scale = 5000
define m_filter_size = 16

drop table main_tab; 
drop table filter_tab;

begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
end;
/

create table main_tab (
	n number		not null, 
	v varchar2(100)
);

create table filter_tab (
	n number		not null, 
	v varchar2(100)
)
pctfree 99
pctused 1
;

begin 
	for f in 1..10 * &m_filter_size loop
		insert into filter_tab values (f,rpad('a',100));
	end loop; 
	commit; 
end;
/

create unique index filter_tab_i1 on filter_tab (n);

begin
	dbms_stats.gather_table_stats(
		user,
		'filter_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool unnest_cost_02


truncate table main_tab;
begin 
	for f1 in 1..&m_main_scale loop 
		for f2 in 1..&m_filter_size loop
			insert into main_tab values (f2,rpad('a',100));
		end loop; 
	end loop; 
	commit; 
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'main_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

set autotrace traceonly explain

prompt	NO_UNNEST

select
	count(m.v) 
from
	main_tab m
where	exists (
		select	/*+ no_unnest */
			v 
		from
			filter_tab f 
		where	
			f.n = m.n 
		and	f.v like 'a%'
	)
;

prompt	NL_SJ

select
	count(m.v) 
from
	main_tab m
where	exists (
		select	/*+ nl_sj */
			v 
		from
			filter_tab f 
		where
			f.n=m.n 
		and	f.v like 'a%'
	)
;

prompt	MERGE_SJ

select
	count(m.v) 
from
	main_tab m
where	exists (
		select	/*+ merge_sj */
			v 
		from
			filter_tab f 
		where
			f.n=m.n 
		and	f.v like 'a%'
	)
;

prompt	HASH_SJ

select
	count(m.v) 
from
	main_tab m
where	exists (
		select	/*+ hash_sj */
			v 
		from
			filter_tab f 
		where
			f.n=m.n 
		and	f.v like 'a%'
	)
;

prompt	No hint

select
	count(m.v) 
from
	main_tab m
where	exists (
		select
			v 
		from
			filter_tab f 
		where
			f.n=m.n 
		and	f.v like 'a%'
	)
;

set autotrace off

spool off


set doc off
doc


Execution Plans in 10g.
-----------------------
Execution Plan (NO_UNNEST)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=202 Card=1 Bytes=104)
   1    0   SORT (AGGREGATE)
   2    1     FILTER
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (TABLE) (Cost=186 Card=80000 Bytes=8320000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (TABLE) (Cost=1 Card=1 Bytes=104)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (INDEX (UNIQUE))

Execution Plan (NL_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=80186 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     NESTED LOOPS (SEMI) (Cost=80186 Card=80000 Bytes=16640000)
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (TABLE) (Cost=186 Card=80000 Bytes=8320000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (TABLE) (Cost=1 Card=160 Bytes=16640)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (INDEX (UNIQUE))

Execution Plan (MERGE_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=1544 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     MERGE JOIN (SEMI) (Cost=1544 Card=80000 Bytes=16640000)
   3    2       SORT (JOIN) (Cost=1510 Card=80000 Bytes=8320000)
   4    3         TABLE ACCESS (FULL) OF 'MAIN_TAB' (TABLE) (Cost=186 Card=80000 Bytes=8320000)
   5    2       SORT (UNIQUE) (Cost=34 Card=160 Bytes=16640)
   6    5         TABLE ACCESS (FULL) OF 'FILTER_TAB' (TABLE) (Cost=26 Card=160 Bytes=16640)

Execution Plan (HASH_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=216 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     HASH JOIN (RIGHT SEMI) (Cost=216 Card=80000 Bytes=16640000)
   3    2       TABLE ACCESS (FULL) OF 'FILTER_TAB' (TABLE) (Cost=26 Card=160 Bytes=16640)
   4    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (TABLE) (Cost=186 Card=80000 Bytes=8320000)

Execution Plan (Unhinted)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=216 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     HASH JOIN (RIGHT SEMI) (Cost=216 Card=80000 Bytes=16640000)
   3    2       TABLE ACCESS (FULL) OF 'FILTER_TAB' (TABLE) (Cost=26 Card=160 Bytes=16640)
   4    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (TABLE) (Cost=186 Card=80000 Bytes=8320000)


9i Execution plans
------------------
Execution Plan (NO_UNNEST)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=187 Card=1 Bytes=104)
   1    0   SORT (AGGREGATE)
   2    1     FILTER
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=186 Card=4000 Bytes=416000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (Cost=1 Card=1 Bytes=104)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (UNIQUE)


Execution Plan (NL_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=80186 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     NESTED LOOPS (SEMI) (Cost=80186 Card=80000 Bytes=16640000)
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=186 Card=80000 Bytes=8320000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (Cost=1 Card=160 Bytes=16640)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (UNIQUE)


Execution Plan (MERGE_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=1544 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     MERGE JOIN (SEMI) (Cost=1544 Card=80000 Bytes=16640000)
   3    2       SORT (JOIN) (Cost=1510 Card=80000 Bytes=8320000)
   4    3         TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=186 Card=80000 Bytes=8320000)
   5    2       SORT (UNIQUE) (Cost=34 Card=160 Bytes=16640)
   6    5         TABLE ACCESS (FULL) OF 'FILTER_TAB' (Cost=26 Card=160 Bytes=16640)


Execution Plan (HASH_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=354 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     HASH JOIN (SEMI) (Cost=354 Card=80000 Bytes=16640000)
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=186 Card=80000 Bytes=8320000)
   4    2       TABLE ACCESS (FULL) OF 'FILTER_TAB' (Cost=26 Card=160 Bytes=16640)


Execution Plan (Unhinted)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=224 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     HASH JOIN (Cost=224 Card=80000 Bytes=16640000)
   3    2       SORT (UNIQUE)
   4    3         TABLE ACCESS (FULL) OF 'FILTER_TAB' (Cost=26 Card=160 Bytes=16640)
   5    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=186 Card=80000 Bytes=8320000)



8i Execution plans
------------------
Execution Plan (NO_UNNEST)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=185 Card=1 Bytes=104)
   1    0   SORT (AGGREGATE)
   2    1     FILTER
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=185 Card=4000 Bytes=416000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (Cost=1 Card=1 Bytes=104)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (UNIQUE)


Execution Plan (NL_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=185 Card=1 Bytes=104)
   1    0   SORT (AGGREGATE)
   2    1     FILTER
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=185 Card=4000 Bytes=416000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (Cost=1 Card=1 Bytes=104)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (UNIQUE)


Execution Plan (MERGE_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=1548 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     MERGE JOIN (SEMI) (Cost=1548 Card=80000 Bytes=16640000)
   3    2       SORT (JOIN) (Cost=1518 Card=80000 Bytes=8320000)
   4    3         TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=185 Card=80000 Bytes=8320000)
   5    2       SORT (UNIQUE) (Cost=31 Card=160 Bytes=16640)
   6    5         TABLE ACCESS (FULL) OF 'FILTER_TAB' (Cost=25 Card=160 Bytes=16640)


Execution Plan (HASH_SJ)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=317 Card=1 Bytes=208)
   1    0   SORT (AGGREGATE)
   2    1     HASH JOIN (SEMI) (Cost=317 Card=80000 Bytes=16640000)
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=185 Card=80000 Bytes=8320000)
   4    2       TABLE ACCESS (FULL) OF 'FILTER_TAB' (Cost=25 Card=160 Bytes=16640)


Execution Plan (Unhinted)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=185 Card=1 Bytes=104)
   1    0   SORT (AGGREGATE)
   2    1     FILTER
   3    2       TABLE ACCESS (FULL) OF 'MAIN_TAB' (Cost=185 Card=4000 Bytes=416000)
   4    2       TABLE ACCESS (BY INDEX ROWID) OF 'FILTER_TAB' (Cost=1 Card=1 Bytes=104)
   5    4         INDEX (UNIQUE SCAN) OF 'FILTER_TAB_I1' (UNIQUE)


#

