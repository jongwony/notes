rem
rem	Script:		merge_demo_01b.sql
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
rem	As for merge_demo_01.sql, but using the
rem	pga_aggregate target. Note - this does
rem	not require workarea_size_policy = auto.
rem
rem	To allow a single operation to use 25MB
rem	we set pga_aggregate_target to 500MB, for
rem	40MB, we use 800MB.
rem
rem	Create a million row table and self join,
rem	with, and without, an order by.
rem
rem	Test 1 - without the ORDER BY
rem	To be done
rem
rem	Test 2 - with the ORDER BY
rem
rem	There are three workareas, which are
rem	all open at one point, but the first
rem	one (the first sort) closes - possibly 
rem	as the sort completes and the first
rem	rows of the result set become available.
rem
rem	With pga_aggregate_target = 800 MB, the
rem	query uses 28MB for the first sort, 32MB
rem	for the second, and 34 for the order by.
rem	Max UGA = 108 MB (too big !).  The 
rem	find sort for order by dumps the data
rem	to disc after sorting to do the count,
rem	retaining only 6MB
rem
rem	With pga_aggregate_target = 500 MB, the
rem	forst sort drops to 500KB after peaking
rem	at 24MB, the second to 2MB, and the third 
rem	to 2.4MB. The first workarea closes as 
rem	the data starts to return. Max UGA is 31MB
rem

start setenv

execute dbms_random.seed(0)

rem	drop table t1;

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


spool merge_demo_01b

begin
--	begin		execute immediate 'alter session set workarea_size_policy = auto';
--	exception	when others then null;
--	end;

--	begin		execute immediate 'alter system set pga_aggregate_target = 500m scope = memory';
	begin		execute immediate 'alter system set pga_aggregate_target = 800m scope = memory';
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
