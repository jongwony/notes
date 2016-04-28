rem
rem	Script:		tablescan_01b.sql
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
rem	Cost of tablescan on an 80MB (approx) table, with different block sizes
rem	From a baseline of 10,000 rows and 8K blocks, you need:
rem
rem		Block size	Rows
rem		16K		 5000
rem		8K		10000
rem		4K		20000
rem		2K		40000
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


create table t1 
pctfree 99
pctused 1
tablespace test_2k
-- tablespace test_4k
-- tablespace test_8k
-- tablespace test_16k
-- tablespace test_8k_assm
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
	rownum <= 40000
--	rownum <= 20000
--	rownum <= 10000
--	rownum <=  5000
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
