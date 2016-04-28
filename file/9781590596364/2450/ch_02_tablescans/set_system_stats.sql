rem
rem	Script:		set_system_stats.sql
rem	Author:		Jonathan Lewis
rem	Dated:		December 2002
rem	Purpose:	Write in a fixed set of system statistics
rem	Purpose:	Demonstration script for 'Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.3
rem		 9.2.0.6
rem
rem	Not relevant
rem		 8.1.7.4
rem
rem	Notes:
rem	This script is limited to statistics that exist in all versions 
rem	from 9.0 onwards. A few more statistics appear in 9.2 and 10.1
rem
rem	There is a role gather_system_statistics available to DBAs
rem	This is defined in $ORACLE_HOME/rdbms/admin/dbmsstat.sql that
rem	amongst other privileges, offers:
rem		grant update, insert, select, delete on aux_stats$ to gather_system_statistics
rem
rem	There is an odd bug with the system stats calls - you cannot
rem	run them twice in the same session (as a normal end user) in
rem	some versions of Oracle without getting Oracle errors:
rem		ORA-20000: Unable to set values for system statistics : insufficient privileges
rem		ORA-06512: at "SYS.DBMS_STATS", line 4448
rem		ORA-06512: at line 2
rem
rem	The values in the (non-executed) first set of calls make a 9i system 
rem	behave like an 8i system with db_file_multiblock_read_count set to 8. 
rem	(sreadtim = mreadtim, and MBRC = adjusted dbf_mbrc).
rem
rem	The modified statistics will not invalidate existing plans,
rem	which is why we have the flush shared_pool;
rem

begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',350);
end;
.

rem
rem	The sample figures used in chapter 2 (tablescans)
rem

begin
	dbms_stats.set_system_stats('MBRC',12);
	dbms_stats.set_system_stats('MREADTIM',30);
	dbms_stats.set_system_stats('SREADTIM',5);
	dbms_stats.set_system_stats('CPUSPEED',500);
end;
/

alter system flush shared_pool;

