rem
rem	Script:		join_card_05.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	We forget about filter columns for the moment,
rem	and consider a two-column join predicate with
rem	a disjunct (OR).
rem

start setenv

define t1j1 = 30
define t1j2 = 50

define t2j1 = 40
define t2j2 = 40

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
	trunc(dbms_random.value(0, &t1j1 ))	join1,
	trunc(dbms_random.value(0, &t1j2 ))	join2,
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


spool join_card_05

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

prompt
prompt The original join
prompt =================
prompt

select
	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
or	t2.join2 = t1.join2
;

prompt
prompt How Oracle treats it (almost)
prompt =============================
prompt

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join2 = t1.join2
union all
select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
and	t2.join2 != t1.join2
;


prompt
prompt If we block Concatenation
prompt =========================
prompt

select
	/*+ no_expand */
	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
or	t2.join2 = t1.join2
;


alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit


set doc off
doc

Concatenation - effectively a UNION ALL, just string 
the two results together one after the other. Note how
10g manages to tell you what really happens.

BUT where has that 125,000 come from ?
	The 2,000,000 in the top line is 1/50 * 100,000,000 (t2.join2)

	The 125,000 in the second line is 1/40 * 100,000,000 * 1/20
	which is 
		1/40 * 100,000,000	(t1.join1)
		5%			(unknown value => 5% on !=)

Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=237 Card=2125000 Bytes=72250000)
   1    0   CONCATENATION
   2    1     HASH JOIN (Cost=118 Card=2000000 Bytes=68000000)
   3    2       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=53 Card=10000 Bytes=170000)
   4    2       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=170000)
   5    1     HASH JOIN (Cost=118 Card=125000 Bytes=4250000)
   6    5       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=53 Card=10000 Bytes=170000)
   7    5       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=170000)


Both 8i and 9i seem to manage to add 125,00 + 125,000
to get the answer 2,125,000. It the right answer, with
the wrong intermediate representation.

Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=120 Card=2125000 Bytes=72250000)
   1    0   CONCATENATION
   2    1     HASH JOIN (Cost=60 Card=125000 Bytes=4250000)
   3    2       TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=10000 Bytes=170000)
   4    2       TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=10000 Bytes=170000)
   5    1     HASH JOIN (Cost=60 Card=125000 Bytes=4250000)
   6    5       TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=10000 Bytes=170000)
   7    5       TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=10000 Bytes=170000)


Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=120 Card=2125000 Bytes=72250000)
   1    0   CONCATENATION
   2    1     HASH JOIN (Cost=60 Card=125000 Bytes=4250000)
   3    2       TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=10000 Bytes=170000)
   4    2       TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=10000 Bytes=170000)
   5    1     HASH JOIN (Cost=60 Card=125000 Bytes=4250000)
   6    5       TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=10000 Bytes=170000)
   7    5       TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=10000 Bytes=170000)


=========================================

BUT for the UNION ALL, Oracle does:
In this case, the 2,450,000 that appears in the second half is:
	49/50 * 1/40 * 100,000,000
	where
		49/50 is (1 - 1/50) t1.join2
	and	1/40 is from t2.join1

Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=237 Card=4450000 Bytes=139300000)
   1    0   UNION-ALL
   2    1     HASH JOIN (Cost=118 Card=2000000 Bytes=56000000)
   3    2       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=53 Card=10000 Bytes=140000)
   4    2       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=140000)
   5    1     HASH JOIN (Cost=118 Card=2450000 Bytes=83300000)
   6    5       TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=53 Card=10000 Bytes=170000)
   7    5       TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=53 Card=10000 Bytes=170000)

#
