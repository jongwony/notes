rem
rem	Script:		sort_demo_04.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Doing a large sort/merge join,
rem	Does the cost of the sort change.
rem	What happens about memory usage.
rem

start setenv

alter system flush shared_pool;

execute dbms_random.seed(0)

drop table t2;
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


create table t2 
nologging
as
select	* 
from	t1
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

begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
.
/

begin
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set sort_area_size = 40000000';
	exception	when others then null;
	end;

end;
/

prompt
prompt	You will now have to wait a few seconds for a long query to complete
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

select	/*+ ordered use_merge(t1) use_merge(t2) */
	t1.sortcode s1, t2.sortcode s2
from
	t1, t2
where
	t2.sortcode = t1.sortcode
;

/*
	Alternative code to do the sort without
	generating a huge output file.
*/
declare
	v varchar2(10);
begin

	for r in (
		select	/*+ ordered use_merge(t1) use_merge(t2) */
			t1.sortcode s1, t2.sortcode s2
a		from	t1, t2
		where	t2.sortcode = t1.sortcode
	) loop
		v := r.s1;
		exit;
	end loop;

end;
.



alter session set events '10053 trace name context off';
alter session set events '10046 trace name context off';
alter session set events '10033 trace name context off';
alter session set events '10032 trace name context off';

set pagesize 40
set termout on

spool sort_demo_04

execute snap_my_stats.end_snap
execute snap_events.end_snap
execute snap_ts.end_snap

select
	table_name, blocks, avg_row_len
from	user_tables
where	table_name in ('T1','T2')
order by 
	table_name
;

select
	table_name, column_name, avg_col_len
from
	user_tab_columns
where	table_name in ('T1','T2')
and	column_name = 'SORTCODE'
order by
	table_name, column_name
;

spool off


set doc off
doc

#

