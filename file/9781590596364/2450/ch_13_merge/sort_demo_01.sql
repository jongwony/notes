rem
rem	Script:		sort_demo_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Create a million row table and select with a sort order by
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
/

begin
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set sort_area_size = 1048576';
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
rem	alter session set events '10033 trace name context forever';
rem	alter session set events '10046 trace name context forever, level 8';
alter session set events '10053 trace name context forever';

select
	sortcode
from
	t1
order by
	sortcode
.

/*
	Alternative code to do the sort without
	generating a huge output file.
*/

declare
	v varchar2(10);
begin

	for r in (select sortcode from t1 order by sortcode) loop
		v := r.sortcode;
		exit;
	end loop;

end;
.

/*
	And a version to show that you can have 
	more than one allocation of memory active
	at a time.
*/

declare
	v varchar2(10);
begin

	for r in (select sortcode from t1 order by sortcode) loop
		v := r.sortcode;
		for r1 in (select sortcode from t1 order by sortcode) loop
			v := r1.sortcode;
			exit;
		end loop;
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

spool sort_demo_01

execute snap_my_stats.end_snap
execute snap_events.end_snap
execute snap_ts.end_snap

select
	table_name, blocks, avg_row_len
from	user_tables
where	table_name = 'T1'
order by 
	table_name
;

select
	table_name, column_name, avg_col_len
from
	user_tab_columns
where	table_name = 'T1'
order by
	table_name, column_name
;

spool off

