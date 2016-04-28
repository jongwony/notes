rem
rem	Script:		tablescan_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for 'Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	My standard setup is:
rem		8K block size
rem		Locally managed tablespace
rem		Uniform extent sizing at 1MB extents
rem
rem	The line to set the optimizer cost model to IO is particularly
rem	for the benefit of 10g, where CPU costing is the default, and
rem	effectively mandatory action. But it does protect you from 
rem	accidental CPU costing in 9i
rem

start setenv

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


/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;

*/

create table t1 
pctfree 99
pctused 1
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
select
	/*+ ordered use_nl(v2) */
	rownum					id,
	trunc(100 * dbms_random.normal)		val,
	rpad('x',100)				padding
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

spool tablescan_01

set autotrace traceonly explain;

alter session set db_file_multiblock_read_count = 4;
prompt	db_file_multiblock_read_count = 4

select	max(val)
from	t1;

alter session set db_file_multiblock_read_count = 8;
prompt	db_file_multiblock_read_count = 8

select	max(val)
from	t1;

alter session set db_file_multiblock_read_count = 16;
prompt	db_file_multiblock_read_count = 16

select	max(val)
from	t1;

alter session set db_file_multiblock_read_count = 32;
prompt	db_file_multiblock_read_count = 32

select	max(val)
from	t1;


alter session set db_file_multiblock_read_count = 64;
prompt	db_file_multiblock_read_count = 64

select	max(val)
from	t1;


alter session set db_file_multiblock_read_count = 128;
prompt	db_file_multiblock_read_count = 128

select	max(val)
from	t1;


alter session set db_file_multiblock_read_count = 8;

select	
	val, count(*)
from	t1
group by
	val
;

set autotrace off

spool off
