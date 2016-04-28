rem
rem	Script:		descending_bug.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	There is a bug with joins that involve descending indexes
rem	the access condition on the join double-accounts for the
rem	join, because it uses the 'descending' and 'non-descending'
rem	version of the data.
rem
rem	The access_predicates column of the execution plan shows:
rem		("T2"."N1"="T1"."N1" AND SYS_OP_DESCEND("T2"."N1")=SYS_OP_DESCEND("T1"."N1"))
rem
rem	This reduces the join cardinality from 225 to 1.
rem
rem	The bug is fixed in 10g - although the access_predicates
rem	column still shows the same text.
rem

start setenv
set timing off

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
	mod(rownum,200)		n1,
	mod(rownum,200)		n2,
	rpad(rownum,215)	v1
from all_objects 
where rownum <= 3000
;


create table t2
as
select 
	trunc((rownum-1)/15)	n1,
	trunc((rownum-1)/15)	n2,
	rpad(rownum,215)	v1
from all_objects 
where rownum <= 3000
;

create index t2_i1 on t2(n1 /* desc */);

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

spool descending_bug

set autotrace traceonly explain

prompt
prompt	Check the cardinalities on autotrace
prompt	Normal b-tree index
prompt

select 
	t1.n1, t2.n2, t1.v1
from
	t1,t2
where
	t1.n2 = 45
and	t2.n1 = t1.n1
;

set autotrace off

drop index t2_i1;
create index t2_i1 on t2(n1 desc);

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

set autotrace traceonly explain

prompt
prompt	Descending index
prompt

select 
	t1.n1, t2.n2, t1.v1
from
	t1,t2
where
	t1.n2 = 45
and	t2.n1 = t1.n1
;

set autotrace off


spool off

set doc off
doc


Execution Plan (9.2.0.6 - with ordinary index)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=CHOOSE (Cost=33 Card=225 Bytes=51750)
   1    0   HASH JOIN (Cost=33 Card=225 Bytes=51750)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=16 Card=15 Bytes=3330)
   3    1     TABLE ACCESS (FULL) OF 'T2' (Cost=16 Card=3000 Bytes=24000)



Execution Plan (9.2.0.6 - with descending index)
----------------------------------------------------------
   0      SELECT STATEMENT Optimizer=CHOOSE (Cost=33 Card=1 Bytes=230)
   1    0   HASH JOIN (Cost=33 Card=1 Bytes=230)
   2    1     TABLE ACCESS (FULL) OF 'T1' (Cost=16 Card=15 Bytes=3330)
   3    1     TABLE ACCESS (FULL) OF 'T2' (Cost=16 Card=3000 Bytes=24000)




Fixed in 10g.
Note the access and filter parameters.

---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |   225 | 51750 |    60  (24)| 00:00:02 |
|*  1 |  HASH JOIN         |      |   225 | 51750 |    60  (24)| 00:00:02 |
|*  2 |   TABLE ACCESS FULL| T1   |    15 |  3330 |    30  (24)| 00:00:01 |
|   3 |   TABLE ACCESS FULL| T2   |  3000 | 24000 |    28  (18)| 00:00:01 |
---------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("T2"."N1"="T1"."N1" AND
              SYS_OP_DESCEND("T2"."N1")=SYS_OP_DESCEND("T1"."N1"))
   2 - filter("T1"."N2"=45)

#

