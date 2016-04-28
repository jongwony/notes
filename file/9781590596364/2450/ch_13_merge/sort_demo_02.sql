rem
rem	Script:		sort_demo_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Building an index on the million row table.
rem
rem	The data size has to be increased by 8 bytes per row.
rem	(or 12 bytes for a global index) as the rowid will be
rem	added to the index - for sorting purposes if it is a 
rem	non-unique index, as carried information if it is a
rem	unique index
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

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id,
	substr(dbms_random.string('U',6),1,6)	sortcode
from	all_objects 
where	rownum <= 5000
;


create table t1 
nologging		-- adjust as necessary
as
/*
with generator as (
	select	--+ materialize
		rownum 				id,
	substr(dbms_random.string('U',6),1,6)	sortcode
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	/*+ ordered use_nl(v2) */
	substr(v2.sortcode,1,4) || substr(v1.sortcode,1,2) sortcode
from
	generator	v1,
	generator	v2
where
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


begin
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

--	begin		execute immediate 'alter session set sort_area_size =  1048576';
--	begin		execute immediate 'alter session set sort_area_size =  4194304';
--	begin		execute immediate 'alter session set sort_area_size = 16777216';
	begin		execute immediate 'alter session set sort_area_size = 41943040';
	exception	when others then null;
	end;

--	begin		execute immediate 'alter session set sort_area_retained_size =        0';
	begin		execute immediate 'alter session set sort_area_retained_size =  8388608';
	exception	when others then null;
	end;

end;
/

prompt
prompt	You will now have to wait for a large index to be built
prompt

spool junk

set pagesize 999
set termout off

execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

alter session set events '10032 trace name context forever';
alter session set events '10033 trace name context forever';
alter session set events '10046 trace name context forever, level 8';
alter session set events '10053 trace name context forever';

create index t1_i1 on t1(sortcode) nologging;

alter session set events '10053 trace name context off';
alter session set events '10046 trace name context off';
alter session set events '10033 trace name context off';
alter session set events '10032 trace name context off';

set pagesize 40
set termout on

spool sort_demo_02

execute snap_my_stats.end_snap
execute snap_events.end_snap
execute snap_ts.end_snap

spool off


set doc off
doc

#

