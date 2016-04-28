rem
rem	Script:		partition_8.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem	Not tested
rem		 8.1.7.4
rem
rem	For generating a large table in 8i, comment
rem	out the "WITH ... AS" section of code in the
rem	create table statement, and re-instate the 
rem	'create table generator' code.
rem

start setenv
set timing off
set feedback off

execute dbms_random.seed(0)

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


rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;


create table t1 (
	part_col	not null,
	id		not null,
	small_vc,
	padding	
)
partition by range(part_col) (
	partition	p0200 values less than ( 200),
	partition	p0400 values less than ( 400),
	partition	p0600 values less than ( 600),
	partition	p0800 values less than ( 800),
	partition	p1000 values less than (1000)
)
nologging
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	trunc(sqrt(rownum-1)),
	rownum-1,
	lpad(rownum-1,10),
	rpad('x',50)
from
	generator	v1,
	generator	v2
where
	rownum <= 1000000
/


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


spool partition_8

select	table_name, partition_name, num_rows 
from 	user_tab_partitions 
where	table_name = 'T1'
order by partition_position
;

select 	table_name, num_rows 
from 	user_tables
where	table_name = 'T1'
;

break on partition_name skip 1
 
select	partition_name, column_name, num_distinct, density
from	user_part_col_statistics
where	table_name = 'T1'
order by partition_name
;

clear breaks

select	column_name, num_distinct, density
from	user_tab_col_statistics
where	table_name = 'T1'
;

set autotrace traceonly explain

prompt	Single known partition
select	count(*) 
from 	t1
where	part_col between 250 and 350
;


prompt	Crossing two partitions
select	count(*) 
from 	t1
where	part_col between 150 and 250
;


variable v1 number
variable v2 number

execute :v1 := 150; :v2 := 250

prompt	Bind Variables:
select	count(*) 
from 	t1
where	part_col between :v1 and :v2
;

set autotrace off

spool off
