rem
rem	Script:		sort_demo_04a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem
rem	Keep re-connecting as a new session to run
rem	this script so that you can see the effects
rem	for different values of sort_area_size
rem

start setenv

alter system flush shared_pool;

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


begin
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

--	begin		execute immediate 'alter session set sort_area_size =  1048576';
--	begin		execute immediate 'alter session set sort_area_size =  2097152';
--	begin		execute immediate 'alter session set sort_area_size =  3555328';
--	begin		execute immediate 'alter session set sort_area_size =  4194304';
--	begin		execute immediate 'alter session set sort_area_size =  8388608';
--	begin		execute immediate 'alter session set sort_area_size = 10485760';
	begin		execute immediate 'alter session set sort_area_size = 12582912';
--	begin		execute immediate 'alter session set sort_area_size = 16777216';
--	begin		execute immediate 'alter session set sort_area_size = 25165824';
--	begin		execute immediate 'alter session set sort_area_size = 26738688';
--	begin		execute immediate 'alter session set sort_area_size = 31457280';
--	begin		execute immediate 'alter session set sort_area_size = 41943040';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set sort_area_retained_size =        0';
--	begin		execute immediate 'alter session set sort_area_retained_size =  1048576';
--	begin		execute immediate 'alter session set sort_area_retained_size =  8388608';
	exception	when others then null;
	end;

end;
.
/

prompt
prompt	You will now have to wait a few seconds for a long query to complete
prompt

spool junk

set pagesize 999
set termout off

desc t1;

execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

-- alter session set events '10032 trace name context forever';
-- alter session set events '10033 trace name context forever';
-- alter session set events '10046 trace name context forever, level 8';
-- alter session set events '10053 trace name context forever';

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
		from	t1, t2
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

spool sort_demo_04a

execute snap_my_stats.end_snap
execute snap_events.end_snap
execute snap_ts.end_snap

spool off


set doc off
doc


#

