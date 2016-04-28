rem
rem	Script:		scalar_sub_01.sql
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
rem	Demonstrate that scalar subqueries use the same
rem	technology as the FILTER operation to minimise
rem	the number of times the subquery has to be executed
rem
rem	Since Deterministic functions have never appeared 
rem	to work as advertised, this may allow you to do
rem	something a little clever instead, viz:
rem	
rem		select 
rem			(select funct(colx) from dual) func
rem		from	...
rem	
rem	instead of
rem		select
rem			func(colx)
rem		from	...
rem

start setenv

drop table emp;

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


rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 1000
;


create table emp(
	dept_no		not null,
	sal,
	emp_no		not null,
	padding,
	constraint e_pk primary key(emp_no)
)
as
/*
with generator as (
	select	--+ materialize
		rownum 		id
	from	all_objects 
	where	rownum <= 1000
)
*/
select
	/*+ ordered use_nl(v2) */
	mod(rownum,6),
	rownum,
	rownum,
	rpad('x',60)
from
	generator	v1,
	generator	v2
where
	rownum <= 20000
;

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 'EMP',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/


spool scalar_sub_01

set timing on
set autotrace on 

prompt
prompt	"Lucky" example of using scalar subquery.  
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		outer.dept_no,
		outer.sal,
		outer.emp_no,
		outer.padding,
		(
			select	avg(inner.sal) 
		 	from	emp	inner 
			where	inner.dept_no = outer.dept_no
		) 						av_sal
	from	emp	outer
)
where
	sal > av_sal
;

prompt
prompt	"Lucky" example of using scalar subquery.  
prompt	This time without the predicate.
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		outer.dept_no,
		outer.sal,
		outer.emp_no,
		outer.padding,
		(
			select	avg(inner.sal) 
		 	from	emp	inner 
			where	inner.dept_no = outer.dept_no
		) 						av_sal
	from	emp	outer
)
;

set autotrace off
set timing off

rem
rem	Make sure a nasty collision happens
rem
rem	Dept_no 67 will collide with Dept_no zero in 8i and 9i
rem	You have to use dept_no = 432 for 10g. (Although this
rem	will also collide in 8i and 9i).
rem

update	emp
set	dept_no = 67		-- 8i/9i value
-- set	dept_no = 432		-- 10g value
where	rownum = 1
;

commit;

set timing on
set autotrace on 

prompt
prompt	"Unlucky" example of using scalar subquery.  
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		outer.dept_no,
		outer.sal,
		outer.emp_no,
		outer.padding,
		(
			select	avg(inner.sal) 
		 	from	emp	inner 
			where	inner.dept_no = outer.dept_no
		) 						av_sal
	from	emp	outer
)
where
	sal > av_sal
;

prompt
prompt	"Unlucky" example of using scalar subquery.  
prompt	This time without the predicate.
prompt

select
	count(av_sal)
from (
	select /*+ no_merge */
		outer.dept_no,
		outer.sal,
		outer.emp_no,
		outer.padding,
		(
			select	avg(inner.sal) 
		 	from	emp	inner 
			where	inner.dept_no = outer.dept_no
		) 						av_sal
	from	emp	outer
)
;


set autotrace off
set timing off


spool off

set doc off
doc

Anomalies:
---------
If you run the first query without the NO_MERGE hint
then 10g reports the following plan in v$sql_plan.
NOTE the absence of line 1 and 2.

  Id  Par  Pos Starts     Rows Plan
---- ---- ---- ------ -------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------
   0       400                 SELECT STATEMENT (all_rows)    Cost (400,,) (Columns 0)
   3    0    1      1        1   SORT   (aggregate)  (Columns 0)
   4    3    1      1    9,997     FILTER    (Columns 0) Filter ("OUTER"."SAL">)
   5    4    1      1   20,000       TABLE ACCESS (analyzed) TEST_USER EMP (full)  Cost (57,20000,160000)  IO_Cost (56,5945352,) (Columns 0)
   6    4    2                       SORT   (aggregate)  (Columns 0)
   7    1    1                         TABLE ACCESS (analyzed) TEST_USER EMP (full)  Cost (57,3333,26664)  IO_Cost (56,5612012,) (Columns 0) Filter ("INNER"."DEPT_NO"=:B1)


If you run the same plan through dbms_xplan, you get:

-------------------------------------------------------------------------------
| Id  | Operation              | Name | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT       |      |     1 |     8 |   400   (2)| 00:00:04 |
|   1 |  SORT AGGREGATE        |      |     1 |     8 |            |          |
|*  2 |   TABLE ACCESS FULL    | EMP  |  3333 | 26664 |    57   (2)| 00:00:01 |
|   3 |    SORT AGGREGATE      |      |     1 |     8 |            |          |
|*  4 |     FILTER             |      |       |       |            |          |
|   5 |      TABLE ACCESS FULL | EMP  | 20000 |   156K|    57   (2)| 00:00:01 |
|   6 |      SORT AGGREGATE    |      |     1 |     8 |            |          |
|*  7 |       TABLE ACCESS FULL| EMP  |  3333 | 26664 |    57   (2)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("INNER"."DEPT_NO"=:B1)
   4 - filter("OUTER"."SAL"> (SELECT AVG("INNER"."SAL") FROM "EMP" "INNER" WHERE "INNER"."DEPT_NO"=:B1))
   7 - filter("INNER"."DEPT_NO"=:B1)

Oracle 10g has decided to filter - perhaps on a cost-based decision,possibly 
because it has been coded to avoid the unnest which crashes 9i.


#
