rem
rem	Script:		tablescan_04.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for 'Cost Based Oracle'.
rem	Purpose:	Impact of CPU costing
rem
rem	Versions tested 
rem		10.1.0.4
rem
rem	Not relevant
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Warning:
rem	This script requires you to delete data from the data dictionary
rem
rem	Notes:
rem	The aim is to compare the behaviour of noworkload stats
rem	with generated system statistics. 
rem
rem	Oracle seems to set:
rem		MBRC = db_file_multiblock_read_count
rem		sreadtim = ioseektim + db_block_size / iotfrspeed
rem		mreadtim = ioseektim + 
rem			db_file_multiblock_read_count * db_block_size / iotfrspeed
rem
rem	The question is - does Oracle set these values once from the
rem	default blocksize, or does it create new values for each object
rem	based on the block size of the object.
rem
rem	Method of investigation create a (nearly) fixed size table of
rem	approximately 80MB (the table from tablescan_01b.sql).
rem	See what happens to the cost of scanning it with noworkload
rem	statistics compared to the cost of the statistics that mimic the
rem	noworkload statistics for the 8KB (standard) blocksize of the database.
rem
rem	My NOWORKLOAD statistics were:
rem		cpuspeednw	913.641725
rem		ioseektim	10
rem		iotfrspeed	4096
rem
rem	With an 8K blocksize, and db_file_multiblock_read_count = 8,
rem	this is equivalent to:
rem		MBRC		= 8
rem		sreadim		= 10 + 8192/4096 = 12
rem		mreadtim	= 10 + 8 * 8192/4096 = 26
rem

start setenv

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;
end;
/

rem
rem	Option 1: 
rem		delete from sys/aux_stats$
rem		Start a new session, and allow the following block to run
rem

begin
	dbms_stats.set_system_stats('MBRC',8);
	dbms_stats.set_system_stats('MREADTIM',26.0);
	dbms_stats.set_system_stats('SREADTIM',12.0);
	dbms_stats.set_system_stats('CPUSPEED',913.641725);
end;
.
/

rem
rem	Option 2: 
rem		delete from sys/aux_stats$
rem		Start a new session, and allow the following block to run
rem

begin
	dbms_stats.set_system_stats('CPUSPEEDNW',913.641725);
	dbms_stats.set_system_stats('IOSEEKTIM',10);
	dbms_stats.set_system_stats('IOTFRSPEED',4096);
end;
.


alter system flush shared_pool;

create table t1 
pctfree 99
pctused 1
-- tablespace test_2k
-- tablespace test_4k
-- tablespace test_8k
tablespace test_16k
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
	rownum <= 5000
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

spool tablescan_04

set autotrace traceonly explain 

alter session set db_file_multiblock_read_count = 8;

select	max(val)
from	t1;

set autotrace off

spool off


set doc off
doc

Block size		noworkload		     normal
----------		----------		     ------
        2K		     7,729		     10,854
        4K		     4,387		      5,429
        8K		     2,717		      2,717
       16K                   1,881		      1,361

#
