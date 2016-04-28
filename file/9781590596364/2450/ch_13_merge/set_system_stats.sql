rem
rem	Script:		set_system_stats.sql
rem	Author:		Jonathan Lewis
rem	Dated:		December 2002
rem	Purpose:	Write in a fixed set of system statistics
rem
rem	Notes:
rem	Last tested 10.1.0.2
rem	Last tested  9.2.0.4
rem
rem	There is a role gather_system_statistics available to DBA
rem	this is defined in dbmsstat.sql and, amongst others, offers:
rem		grant update, insert, select, delete on aux_stats$ to gather_system_statistics
rem

begin
	dbms_stats.set_system_stats('MBRC',4);
	dbms_stats.set_system_stats('MREADTIM',30);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',350);
end;
/

alter system flush shared_pool;
