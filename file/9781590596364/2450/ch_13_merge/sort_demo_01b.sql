rem
rem	Script:		sort_demo_01b.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem	Not tested
rem		 8.1.7.4 
rem
rem	To be run after sort_demo_01, as that
rem	program creates the table needed.
rem
rem	Keep re-connecting as a new session to run
rem	this script so that you can see the effects
rem	for different values of pga_aggregate_target
rem	The initial value in the program is 200M
rem
rem	This version has enabled system statistics
rem	(cpu costing) at levels which emulate the
rem	traditional costing algorithm  (sreadtim =
rem	mreadtim), and the MBRC matches the 
rem	effective db_file_multiblock_read_count
rem	used when the actual is 8.
rem

start setenv

alter system flush shared_pool;

alter session set "_optimizer_cost_model"=choose;
alter session set workarea_size_policy = auto;
alter system set pga_aggregate_target = 200m scope = memory;

begin
	dbms_stats.set_system_stats('MBRC',6.588);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/

prompt
prompt	You will now have to wait a few seconds for a long query to complete
prompt

spool junk

set pagesize 999
set arraysize 999

set termout off

desc t1;

execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

execute snap_ts.start_snap
execute snap_events.start_snap
execute snap_my_stats.start_snap

alter session set events '10032 trace name context forever';
alter session set events '10033 trace name context forever';
rem	alter session set events '10046 trace name context forever, level 8';
alter session set events '10053 trace name context forever';

select
	sortcode
from
	t1
order by
	sortcode
/



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
	And a version to show that you can have more
	than one allocation of memory active at a time.
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

spool sort_demo_01b

execute snap_my_stats.end_snap
execute snap_events.end_snap
execute snap_ts.end_snap

spool off

