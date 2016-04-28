rem
rem	Script:		join_card_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Starting with the same simple case, we now
rem	have nulls in the join columns and in the
rem	filter columns
rem

start setenv

define t1f0 = 25
define t1j1 = 30

define t2f0 = 50
define t2j1 = 40

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
	trunc(dbms_random.value(0, &t1f0 ))	filter,
	trunc(dbms_random.value(0, &t1j1 ))	join1,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where 
	rownum <= 10000
;

update t1 set join1 = null
where mod(to_number(v1),20) = 0;

update t1 set filter = null
where mod(to_number(v1),50) = 0;

commit;



create table t2
as
select
	trunc(dbms_random.value(0, &t2f0 ))	filter,
	trunc(dbms_random.value(0, &t2j1 ))	join1,
	lpad(rownum,10)				v1,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;

update t2 set join1 = null
where mod(to_number(v1),30) = 0;

update t2 set filter = null
where mod(to_number(v1),100) = 0;

commit;

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


spool join_card_03

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

select	t1.v1, t2.v1
from
	t1,
	t2
where
	t2.join1 = t1.join1
and	t1.filter = 1
and	t2.filter = 1
;


alter session set events '10053 trace name context off';

set autotrace off

spool off

rem	exit


set doc off
doc


Execution Plan (10.1.0.3 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=113 Card=1782 Bytes=60588)
   1    0   HASH JOIN (Cost=113 Card=1782 Bytes=60588)
   2    1     TABLE ACCESS (FULL) OF 'T2' (TABLE) (Cost=56 Card=198 Bytes=3366)
   3    1     TABLE ACCESS (FULL) OF 'T1' (TABLE) (Cost=56 Card=392 Bytes=6664)


Execution Plan (9.2.0.6 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=57 Card=1782 Bytes=60588)
   1    0   HASH JOIN (Cost=57 Card=1782 Bytes=60588)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=28 Card=198 Bytes=3366)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=28 Card=392 Bytes=6664)


Note that with a slight variation in precision on the T2 scan,
which reports 199 rows rather than 198 rows, probably due to 
compuational error (dividing by 5 often produces errors in the
Nth decimal place), the join cardinality is slightly larger in 
8i than in 9i and 10g. The value is consistent with the standard
formula though.

Execution Plan (8.1.7.4 autotrace)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=ALL_ROWS (Cost=53 Card=1791 Bytes=60894)
   1    0   HASH JOIN (Cost=53 Card=1791 Bytes=60894)
   2    1     TABLE ACCESS (FULL) OF 'T2' (Cost=26 Card=199 Bytes=3383)
   3    1     TABLE ACCESS (FULL) OF 'T1' (Cost=26 Card=392 Bytes=6664)

#
