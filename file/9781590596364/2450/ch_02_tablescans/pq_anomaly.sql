rem
rem	Script:		pq_anomaly.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	An oddity with parallel costing of tablescans
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	My standard setup is:
rem		8K block size
rem		Locally managed tablespace
rem		Uniform extent sizing at 1MB extents
rem
rem	Buffer size:  ca. 4,000 blocks
rem
rem	The cost calculation for a tablescan uses the adjusted
rem	size of db_file_multiblock_read_count (old method) or
rem	the actual value of MBRC (new method). 
rem
rem	But run time execution uses direct read, preceded by a 
rem	segment checkpoint so the read will always be the 'full' 
rem	size. The size of the direct path read matches the 
rem	"db_file_multiblock_read_count"
rem
rem	Start by reading every 4th block from the table 
re	into the buffer by using a tablescan. Interestingly
rem	there are two possible strategies that Oracle can
rem	use on the query I used to set this up. The choice 
rem	of strategy seemed rather random. (Note - the path
rem	was the same in both cases; the execution method
rem	varied).
rem	
rem	Option 1:
rem	"db file parallel read" for multiple blocks:
rem		EXEC #3:c=0,e=146,p=0,cr=0,cu=0,mis=0,r=0,dep=0,og=1,tim=634626798
rem		WAIT #3: nam='SQL*Net message to client' ela= 10 p1=1111838976 p2=1 p3=0
rem		WAIT #3: nam='db file parallel read' ela= 106671 p1=1 p2=40 p3=40
rem		WAIT #3: nam='db file parallel read' ela= 82579 p1=1 p2=40 p3=40
rem		WAIT #3: nam='db file parallel read' ela= 83709 p1=1 p2=40 p3=40
rem
rem	Option 2:
rem	"db file sequential read" for single blocks
rem		EXEC #3:c=0,e=120,p=0,cr=0,cu=0,mis=0,r=0,dep=0,og=1,tim=1126157249
rem		WAIT #3: nam='SQL*Net message to client' ela= 8 p1=1111838976 p2=1 p3=0
rem		WAIT #3: nam='db file sequential read' ela= 31044 p1=5 p2=20753 p3=1
rem		WAIT #3: nam='db file sequential read' ela= 1337 p1=5 p2=20757 p3=1
rem
rem	Execution plan (from STAT lines)
rem		SORT AGGREGATE 
rem		    TABLE ACCESS BY INDEX ROWID T1 
rem		        INDEX RANGE SCAN I1
rem
rem	Once this cache was primed, the parallel query started
rem	with the following events:
rem		WAIT #3: nam='rdbms ipc reply' ela= 244 p1=5 p2=21474836 p3=0
rem		WAIT #3: nam='rdbms ipc reply' ela= 207 p1=5 p2=21474836 p3=0
rem		WAIT #3: nam='enqueue' ela= 53305 p1=1413677062 p2=65549 p3=0
rem			p1 =  0x54430006 = TC 6
rem			p2 =  0x1000D 
rem
rem	After which the direct reads were all 8 blocks
rem
rem	In passing, slaves p002 and p003 did the tablescan,
rem	slaves p000 and p001 were the 'second set' that did
rem	the sort (order by) in 9i.
rem

start setenv
set timing off

alter session set "_optimizer_cost_model" = io;

alter session set db_file_multiblock_read_count = 8;

execute dbms_stats.delete_system_stats;

execute dbms_random.seed(0)

drop table t1;

create table t1 
pctfree 99
pctused 1
-- tablespace data_2k
as
select
	rownum					id,
	trunc(100 * dbms_random.normal)		val,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;

create index i1 on t1(id);

execute dbms_stats.gather_table_stats(user,'t1',cascade => true);

spool pq_anomaly

execute snap_my_stats.start_snap
alter session set events '10046 trace name context forever, level 8';

select
	/*+ index(t1,i1) */
	count(val)
from
	t1
where	id > 0
and	mod(id,4) = 0
;

execute snap_my_stats.end_snap
execute snap_my_stats.start_snap
set pause on

select /*+ parallel(t1,2) */ 
	id, val 
from t1 
order by val
;

execute snap_my_stats.end_snap
alter session set events '10046 trace name context forever, level 8';

set autotrace off

spool off

