rem
rem	Script:		tablescan_01a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for 'Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant
rem		 8.1.7.4
rem
rem	Notes:
rem	Cost of scanning 10,000 blocks - different block sizes.
rem
rem		a)	2K, 4K, 8K and 16K block sizes
rem		b)	Automatic segment space management at 8K
rem
rem	The line to set the optimizer cost model to IO is particularly
rem	for the benefit of 10g, where CPU costing is the default, and
rem	effectively mandatory action. But it does protect you from 
rem	accidental CPU costing in 9i
rem
rem	Has to be run several times, choosing a different tablespace
rem	on each run.
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


create table t1 
pctfree 99
pctused 1
-- tablespace test_2k
-- tablespace test_4k
-- tablespace test_8k
-- tablespace test_16k
tablespace test_8k_assm
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

spool tablescan_01a

set autotrace traceonly explain;

alter session set db_file_multiblock_read_count = 8;
prompt	db_file_multiblock_read_count = 8

select	max(val)
from	t1;

set autotrace off

spool off
