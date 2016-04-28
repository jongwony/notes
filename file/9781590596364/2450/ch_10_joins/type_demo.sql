rem
rem	Script:		type_demo.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	NOTE - the list partitioning option does not
rem	exist in 8i, so the example with table TYPE3
rem	will not work.
rem
rem	How much damage can you do by storing multiple
rem	reference tables in a single table structure 
rem	with a TYPE column ?  Lots - once you get past 8i.
rem
rem	In this example, to keep the arithmetic simple, I have
rem	created two types with very similar numbers of rows.
rem
rem	The columns are:
rem		TYPE		classify the table
rem		ID		Meaningless numeric key within type
rem		DESCRIPTION	Often the real key (e.g. currency code).
rem
rem	There are lots of variations on this theme, usually
rem	producing much more dramatic errors in cardinality.
rem
rem	If you have made this mistake, you can rectify it by
rem	turning the single table into a list-partitioned table,
rem	which effectively turns it back into one table per type.
rem	This works, of course, only if you always supply the
rem	type (list partitioning) column as a literal string.
rem

start setenv

execute dbms_random.seed(0)

drop table type3;
drop table type2;
drop table type1;
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
	trunc(dbms_random.value(0,20))	class1_code,
	trunc(dbms_random.value(0,25))	class2_code,
	rownum				id,
	lpad(rownum,10,'0')		small_vc
from
	generator	v1,
	generator	v2
where
	rownum <= 500000
;

create table type1 as
select
	rownum-1		id,
	'CLASS1'		type,
	lpad(rownum-1,10,'0')	description
from	all_objects
where	rownum <= 20
;

create table type2 as
select
	rownum-1		id,
	'CLASS1'		type,
	lpad(rownum-1,10,'0')	description
from	all_objects
where	rownum <= 20
union all
select
	rownum-1		id,
	'CLASS2'		type,
	lpad(rownum-1,10,'0')	description
from	all_objects
where	rownum <= 25
;

update type2 set
	description = lpad(rownum-1,10,'0')
;

create table type3(
	id, type, description
)
partition by list (type) (
	partition p1 values('CLASS1'),
	partition p2 values('CLASS2')
)
as 
select
	id, type, description
from
	type2
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


alter table type1 add constraint type1_pk primary key(id, type);
alter table type2 add constraint type2_pk primary key(id, type);
alter table type3 add constraint type3_pk primary key(id, type) using index local;


begin
	dbms_stats.gather_table_stats(
		user,
		'type1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'type2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'type3',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool type_demo

set autotrace traceonly explain

prompt	Baseline queries with 'single-type' table.

select
	t1.small_vc,
	type1.description
from
	t1, type1
where
	t1.id between 1000 and 1999
and	type1.id = t1.class1_code
and	type1.type = 'CLASS1'
and	type1.description = lpad(0,10,'0')
;


prompt	Now repeat, with the 'multi-type' table.

select
	t1.small_vc,
	type2.description
from
	t1, type2
where
	t1.id between 1000 and 1999
and	type2.id = t1.class1_code 
and	type2.type = 'CLASS1'
and	type2.description = lpad(0,10,'0')
;

prompt	Repeat with histograms on the type column

begin
	dbms_stats.gather_table_stats(
		user,
		'type2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for columns TYPE size 75'
	);
end;
/

select
	t1.small_vc,
	type2.description
from
	t1, type2
where
	t1.id between 1000 and 1999
and	type2.id = t1.class1_code 
and	type2.type = 'CLASS1'
and	type2.description = lpad(0,10,'0')
;

prompt	Finally the partitioned table

select
	t1.small_vc,
	type3.description
from
	t1, type3
where
	t1.id between 1000 and 1999
and	type3.id = t1.class1_code 
and	type3.type = 'CLASS1'
and	type3.description = lpad(0,10,'0')
;

set autotrace off


spool off
