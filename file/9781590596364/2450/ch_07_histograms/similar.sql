rem
rem	Script:		similar.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant to
rem		 8.1.7.4
rem
rem	Notes:
rem		Cursor_sharing = similar
rem	If you have a range-based predicate, your query is always re-optimized.
rem	The same is not true for in-lists of the same size.	
rem	If you have a histogram on an equality, your query is always re-optimized.
rem
rem	This requires you to build the snap_my_stats package, 
rem	that depends on the v$my_stats view.  See scripts
rem	c_mystats.sql and snap_myst.sql
rem

start setenv

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

create table t1
as
select
	trunc((rownum-1)/100)	n1,
	rpad('x',100)		padding
from
	all_objects
where
	rownum <= 1000
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


spool similar

execute snap_my_stats.start_snap

select	count(*) from t1 where n1 in (0,1);
select	count(*) from t1 where n1 in (1,1);
select	count(*) from t1 where n1 in (2,1);
select	count(*) from t1 where n1 in (3,1);
select	count(*) from t1 where n1 in (4,1);
select	count(*) from t1 where n1 in (5,1);
select	count(*) from t1 where n1 in (6,1);
select	count(*) from t1 where n1 in (7,1);
select	count(*) from t1 where n1 in (8,1);
select	count(*) from t1 where n1 in (9,1);

execute snap_my_stats.end_snap
execute snap_my_stats.start_snap

select	count(*) from t1 where n1 = 0;
select	count(*) from t1 where n1 = 1;
select	count(*) from t1 where n1 = 2;
select	count(*) from t1 where n1 = 3;
select	count(*) from t1 where n1 = 4;
select	count(*) from t1 where n1 = 5;
select	count(*) from t1 where n1 = 6;
select	count(*) from t1 where n1 = 7;
select	count(*) from t1 where n1 = 8;
select	count(*) from t1 where n1 = 9;

execute snap_my_stats.end_snap
execute snap_my_stats.start_snap

select	count(*) from t1 where n1 between 0 and 0;
select	count(*) from t1 where n1 between 0 and 1;
select	count(*) from t1 where n1 between 0 and 2;
select	count(*) from t1 where n1 between 0 and 3;
select	count(*) from t1 where n1 between 0 and 4;
select	count(*) from t1 where n1 between 0 and 5;
select	count(*) from t1 where n1 between 0 and 6;
select	count(*) from t1 where n1 between 0 and 7;
select	count(*) from t1 where n1 between 0 and 8;
select	count(*) from t1 where n1 between 0 and 9;

execute snap_my_stats.end_snap

spool off


set doc off
doc


#

