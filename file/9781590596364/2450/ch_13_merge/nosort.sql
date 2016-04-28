rem
rem	Script:		nosort.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	To check if a merge join with a sorted
rem	first input can sort the second data set
rem	before acquiring all of the first data
rem	set, we use the 10046 trace and force the 
rem	first data set to do lots of disc reads.
rem
rem	If we see db file sequential read waits 
rem	for the first table AFTER the db file 
rem	scattered reads for the second table, we
rem	will have our result. (We could also enable
rem	the 10032 trace to show that we sort before
rem	we have read all the first table data).
rem

start setenv

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

/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;


create table t1 
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select
	/*+ ordered use_nl(v2) */
	mod(rownum,100)		n1,
	rownum			id,
	lpad(rownum,10,'0')	small_vc,
	rpad('x',200)		padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
;

alter table t1 modify n1 not null;
create index t1_i1 on t1(n1, id);

create table t2
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select
	/*+ ordered use_nl(v2) */
	mod(rownum,100)		n1,
	rownum			id,
	lpad(rownum,10,'0')	small_vc,
	rpad('x',200)		padding
from
	generator	v1,
	generator	v2
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


alter tablespace test_8k offline;
alter tablespace test_8k online;

spool nosort

rem	set autotrace traceonly explain

alter session set events '10032 trace name context forever';
alter session set events '10046 trace name context forever, level 8';

select 
	/*+ ordered index(t1) use_merge(t2) */
	count(t1.small_vc)
from
	t1,
	t2
where
	t1.n1 = 50
and	t2.id = t1.id
;

alter session set events '10046 trace name context off';
alter session set events '10032 trace name context off';

set autotrace off

spool off


set doc off
doc

The 9i trace file:
------------------
EXEC #1:c=0,e=74,p=0,cr=0,cu=0,mis=0,r=0,dep=0,og=1,tim=5611197797
WAIT #1: nam='SQL*Net message to client' ela= 4 p1=1111838976 p2=1 p3=0
WAIT #1: nam='db file sequential read' ela= 18010 p1=13 p2=394 p3=1	-- t1 index root
WAIT #1: nam='db file sequential read' ela= 3326 p1=13 p2=407 p3=1	-- t1 index leaf
WAIT #1: nam='db file sequential read' ela= 10484 p1=13 p2=11 p3=1	-- t1 table block
WAIT #1: nam='db file sequential read' ela= 269 p1=13 p2=521 p3=1	-- t2 seg header
WAIT #1: nam='db file scattered read' ela= 935 p1=13 p2=522 p3=8	-- t2 tablescan
WAIT #1: nam='db file scattered read' ela= 922 p1=13 p2=530 p3=8

	...	etc., scanning the whole t2 table

WAIT #1: nam='db file scattered read' ela= 1009 p1=13 p2=825 p3=8
WAIT #1: nam='db file scattered read' ela= 422 p1=13 p2=833 p3=2	-- t2 tablescan
WAIT #1: nam='db file sequential read' ela= 316 p1=13 p2=14 p3=1	-- t1 table block
WAIT #1: nam='db file sequential read' ela= 33429 p1=13 p2=17 p3=1	-- t1 table block

	...	etc., every third block down the t1 table


#
