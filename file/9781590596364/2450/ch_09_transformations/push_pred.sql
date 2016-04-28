rem
rem	Script:		push_pred.sql
rem	Author:		Jonathan Lewis
rem	Dated:		February 2003
rem	Purpose:	Demo of for 'Cost Based Oracle'.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Predicate pushing takes place when views cannot be
rem	merged but there is a possible join condition between
rem	tables outside the view and tables inside the view.
rem
rem	This probably means that you will only see them in
rem	rare cases with a nested loop join into the view.
rem
rem	Sometimes you may see predicate moving inside a view, 
rem	even when predicate pushing is disabled. This is 
rem	PROBABLY transitive closure, not predicate pushing.
rem
rem	The demonstration uses an outer join into a join view.
rem	Oracle 8i uses a hash join for all three cases, until
rem	you make the range on t1.id1 large (e.g. between 1 and 850)
rem
rem	Note the line VIEW PUSHED PREDICATE
rem

start setenv

drop table t3;
drop table t2;
drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'execute dbms_stats.delete_system_stats';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;

end;
/

create table t1 as
select
	rownum - 1			id1,
	trunc((rownum - 1)/10)		n1,
	lpad(rownum,10,'0')		small_vc,
	rpad('x',100)			padding
from
	all_objects
where	
	rownum <= 5000
;

alter table t1 add constraint t1_pk primary key(id1);

create table t2 as
select
	trunc((rownum-1)/5)		id1,
	rownum				id2,
	lpad(rownum,10,'0')		small_vc,
	rpad('x',100)			padding
from
	all_objects
where
	rownum <= 25000
;

alter table t2 add constraint t2_pk primary key(id1, id2);

create table t3 as
select
	trunc((rownum-1)/5)		id1,
	rownum				id2,
	lpad(rownum,10,'0')		small_vc,
	rpad('x',100)			padding
from
	all_objects
where
	rownum <= 25000
;

alter table t3 add constraint t3_pk primary key(id1, id2);


begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		cascade		 => true,
		estimate_percent => null,
		method_opt 	 => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T2',
		cascade		 => true,
		estimate_percent => null,
		method_opt 	 => 'for all columns size 1'
	);
end;
/


begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T3',
		cascade		 => true,
		estimate_percent => null,
		method_opt 	 => 'for all columns size 1'
	);
end;
/

create or replace view v1 as
select
	t2.id1,
	t2.id2,
	t3.small_vc,
	t3.padding
from
	t2, t3
where
	t3.id1 = t2.id1
and	t3.id2 = t2.id2
;


spool push_pred

set autotrace traceonly explain

prompt
prompt Default settings, and without blocking the merge
prompt

select 
	t1.*, 
	v1.* 
from 
	t1, 
	v1
where 
	t1.n1 = 5
and	t1.id1 between 10 and 50
and	v1.id1(+) = t1.id1
;

prompt
prompt	Stop pushing predicates
prompt

alter session set "_push_join_predicate"=false;

select 
	t1.*, 
	v1.* 
from 
	t1, 
	v1
where 
	t1.n1 = 5
and	t1.id1 between 10 and 50
and	v1.id1(+) = t1.id1
;

prompt
prompt	Allow pushing predicates
prompt

alter session set "_push_join_predicate"=true;

select 
	t1.*, 
	v1.* 
from 
	t1, 
	v1
where 
	t1.n1 = 5
and	t1.id1 between 10 and 50
and	v1.id1(+) = t1.id1
;

set autotrace off

spool off

set doc off
doc

The 9i execution plan
---------------------

------------------------------------------------------------------------------- 
| Id  | Operation                       |  Name       | Rows  | Bytes | Cost  | 
------------------------------------------------------------------------------- 
|   0 | SELECT STATEMENT                |             |     1 |   240 |     5 | 
|   1 |  NESTED LOOPS OUTER             |             |     1 |   240 |     5 | 
|*  2 |   TABLE ACCESS BY INDEX ROWID   | T1          |     1 |   119 |     3 | 
|*  3 |    INDEX RANGE SCAN             | T1_PK       |    42 |       |     2 | 
|   4 |   VIEW PUSHED PREDICATE         | V1          |     1 |   121 |     2 | 
|*  5 |    FILTER                       |             |       |       |       | 
|   6 |     NESTED LOOPS                |             |     1 |   129 |     3 | 
|*  7 |      INDEX RANGE SCAN           | T2_PK       |     1 |     9 |     2 | 
|   8 |      TABLE ACCESS BY INDEX ROWID| T3          |     1 |   120 |     1 | 
|*  9 |       INDEX UNIQUE SCAN         | T3_PK       |     1 |       |       | 
------------------------------------------------------------------------------- 
                                                                                
Predicate Information (identified by operation id):                             
---------------------------------------------------                             
                                                                                
   2 - filter("T1"."N1"=5)                                                      
   3 - access("T1"."ID1">=10 AND "T1"."ID1"<=50)                                

   5 - filter("T1"."ID1"<=50 AND "T1"."ID1">=10)                                

   7 - access("T2"."ID1"="T1"."ID1")                                            
       filter("T2"."ID1">=10 AND "T2"."ID1"<=50)                                
   9 - access("T3"."ID1"="T2"."ID1" AND "T3"."ID2"="T2"."ID2")                  
       filter("T3"."ID1">=10 AND "T3"."ID1"<=50)                                

The filter_predicates in lines 7 and 9 are there NOT from
predicate pushing, but from transitive closure. They appear
even when "_push_join_predicate" is set to false.

	filter("T3"."ID1">=10 AND "T3"."ID1"<=50)                                

The critical predicate for pushing is the one in line 7

	access("T2"."ID1"="T1"."ID1")                                            
	                                                                                


The 10g execution plan
----------------------

------------------------------------------------------------------------
| Id  | Operation                      | Name  | Rows  | Bytes | Cost  |
------------------------------------------------------------------------
|   0 | SELECT STATEMENT               |       |     1 |   206 |     6 |
|   1 |  NESTED LOOPS OUTER            |       |     1 |   206 |     6 |
|*  2 |   TABLE ACCESS BY INDEX ROWID  | T1    |     1 |   119 |     3 |
|*  3 |    INDEX RANGE SCAN            | T1_PK |    42 |       |     2 |
|   4 |   VIEW PUSHED PREDICATE        | V1    |     1 |    87 |     3 |
|   5 |    NESTED LOOPS                |       |     5 |   665 |     3 |
|   6 |     TABLE ACCESS BY INDEX ROWID| T3    |     5 |   600 |     3 |
|*  7 |      INDEX RANGE SCAN          | T3_PK |     5 |       |     2 |
|*  8 |     INDEX UNIQUE SCAN          | T2_PK |     1 |    13 |       |
------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("T1"."N1"=5)
   3 - access("T1"."ID1">=10 AND "T1"."ID1"<=50)
   7 - access("T3"."ID1"="T1"."ID1")
   8 - access("T2"."ID1"="T1"."ID1" AND "T3"."ID2"="T2"."ID2")

Notice particularly that the 10g plan no longer has a FILTER operation,
and all those redundant filter_predicates have disappeared.

#

