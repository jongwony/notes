rem
rem	Script:		has_cpu_harness.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem	Not relevant
rem		 8.1.7.4
rem
rem	Harness to generate string of calls to the 
rem	has_dump.sql script, after setting up for the 
rem	hash_area_size and cpu costing
rem
rem	Uses the data sets created by hash_one.sql
rem

start setenv

set pagesize 0
set feedback off

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'begin dbms_stats.delete_system_stats; end;';
	exception 	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"= choose';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;
end;
/

begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10.000);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/

alter system flush shared_pool;

spool temp1.sql

prompt	set termout off

select
	'start has_dump cpu ' || lpad(8192 * (rownum + 7),10,'0')
from 
	all_objects
where
	rownum = 1
--	rownum <= 20
--	rownum <= 505
;

spool off

accept x prompt 'Press return to execute script temp1.sql - or press ctrl-C'

start temp1


