rem
rem	Script:		merge_demo_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		 9.2.0.6
rem	Not tested
rem		10.1.0.4
rem		 8.1.7.4
rem
rem	If we have pga_aggregate_target set, then
rem	we populate v$sql_workarea_active et. al.
rem	even if we do not have workarea_size_policy
rem	set to auto. If it is not set, the PGA
rem	does not shrink after the tests (because
rem	the UGA is a subheap, presumably).
rem
rem	Create a million row table and self join,
rem	with, and without, an order by.
rem
rem	Test 1 - without the ORDER BY
rem
rem	In both cases, both workareas stay open
rem
rem	With sort_area_size = 40 MB, the query
rem	uses 28M for the first sort, and 32 MB
rem	for the second sort - retaining 70MB
rem	on the merge.
rem
rem	With 25MB - which results in a dump to 
rem	disc - the retained UGA is 6MB as the 
rem	data set is reported, and the max UGA is 
rem	30.5 MB.  THis fits with 10% * 2 plus a
rem	bit.
rem
rem	Test 2 - with the ORDER BY
rem
rem	There are three workareas, which are
rem	all open at one point, but the first
rem	one (the first sort) closes - possibly 
rem	as the sort completes and the first
rem	rows of the result set become available.
rem
rem	With sort_area_size = 40 MB, the query
rem	uses 28MB for the first sort, 32MB for
rem	the second, and 34 for the order by.
rem	Max UGA = 108 MB (too big !).  Dropping
rem	to 77MB as the data set is returned.
rem
rem	With sort_area_size = 25MB, the first 
rem	sort drops to 5MB, the second to 2MB,
rem	and the third to 4MB. The first workarea
rem	closes as the data starts to return, but
rem	the UGA usage stays at 11MB.
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
	rownum 	id,
	substr(dbms_random.string('U',4),1,4)	sortcode
from	all_objects 
where	rownum <= 5000
;

*/

create table t1 
nologging		-- adjust as necessary
as
with generator as (
	select	--+ materialize
		rownum 				id,
	substr(dbms_random.string('U',4),1,4)	sortcode
	from	all_objects 
	where	rownum <= 5000
)
select
	/*+ ordered use_nl(v2) */
	substr(v2.sortcode,1,4) || substr(v1.sortcode,1,2)	sortcode,
	substr(v1.sortcode,2,2)					v2,
	substr(v2.sortcode,2,3)					v3
from
	generator	v1,
	generator	v2
where
--	rownum <= 12000
	rownum <= 1048576
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
.
/


spool merge_demo_01

begin
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set sort_area_size = 41943040';
--	begin		execute immediate 'alter session set sort_area_size = 26214400';
	exception	when others then null;
	end;

end;
/


rem	set pause on


execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

rem	set autotrace traceonly explain

select
	/*+ no_merge(v) */
	 count(*) 
from	(
	select
		/*+ ordered use_merge(b) */ 
		a.v2, b.v3
	from
		t1	a,
		t1	b
	where
		a.sortcode = b.sortcode
	order by
		a.v2, b.v3
	)	v
;



execute snap_ts.end_snap
execute snap_events.end_snap
execute snap_my_stats.end_snap


spool off
