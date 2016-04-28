rem
rem	Script:		constraint_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Even a table-level constraint between columns
rem	can turn into a new predicate - which may (for
rem	example) allow an index to be used.
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
	trunc((rownum-1)/15)	n1,
	trunc((rownum-1)/15)	n2,
	rpad(rownum,215)	v1
from all_objects 
where rownum <= 3000
;

create index t_i1 on t1(n1);

alter table t1 modify n1 not null;
alter table t1 modify n2 not null;

rem
rem	With this constraint, we can use an index
rem	Without it, the path is a full table scan
rem

alter table t1 add constraint t1_ck check (n1 >= n2);

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

spool constraint_03

rem	alter session set events '10053 trace name context forever, level 2';

explain plan for
select
	count(t1.v1)	ct_v1
from 	t1
where	t1.n2 >= 180
;

select * from table(dbms_xplan.display);
rollback;


spool off

set doc off
doc

Execution path 10.1.0.4
-----------------------
---------------------------------------------------------------------
| Id  | Operation                    | Name | Rows  | Bytes | Cost  |
---------------------------------------------------------------------
|   0 | SELECT STATEMENT             |      |     1 |   222 |    12 |
|   1 |  SORT AGGREGATE              |      |     1 |   222 |       |
|*  2 |   TABLE ACCESS BY INDEX ROWID| T1   |    30 |  6660 |    12 |
|*  3 |    INDEX RANGE SCAN          | T_I1 |   301 |       |     2 |
---------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("T1"."N2">=180)
   3 - access("N1">=180)


Execution path 9.2.0.6
----------------------
----------------------------------------------------------------------------
| Id  | Operation                    |  Name       | Rows  | Bytes | Cost  |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |             |     1 |   222 |    12 |
|   1 |  SORT AGGREGATE              |             |     1 |   222 |       |
|*  2 |   TABLE ACCESS BY INDEX ROWID| T1          |    30 |  6660 |    12 |
|*  3 |    INDEX RANGE SCAN          | T_I1        |   301 |       |     2 |
----------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("T1"."N2">=180)
   3 - access("T1"."N1">=180)


#
