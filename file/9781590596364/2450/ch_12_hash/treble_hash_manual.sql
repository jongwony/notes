rem
rem	Script:		treble_hash_manual.sql
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
rem	You need to run treble_hash.sql first to
rem	create the required tables.
rem
rem	The procedure snap_my_stats requires you to
rem	create a view and package in the SYS account.
rem	These are from the scripts:
rem		c_mystats.sql
rem		snap_myst.sql
rem

start setenv

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

alter session set workarea_size_policy = manual;

alter session set hash_area_size = 10485760;
-- alter session set hash_area_size = 20971520;
-- alter session set hash_area_size = 52428800;
-- alter session set hash_area_size = 104857600;



rem
rem	The actual order of access, because of the swapped join inputs
rem	is T3, T2, T1, T4. The first rows are returned almost instantly
rem	and the 10046 trace shows that the tables are scanned in the order
rem	indicated in the execution plan.  
rem

spool treble_hash_manual_1

set autotrace traceonly explain

select
	/*+
		ordered 
		use_hash(t2)
		use_hash(t3)
		use_hash(t4)
		swap_join_inputs(t2) 
		swap_join_inputs(t3) 
		full(t1)
		full(t2)
		full(t3)
		full(t4)
	*/
	count(t1.small_vc),
	count(t2.small_vc),
	count(t3.small_vc),
	count(t4.small_vc)
from
	t1,
	t4,
	t2,
	t3
where
	t4.id1 = t1.id
and	t4.id2 = t2.id
and	t4.id3 = t3.id
;

set autotrace off
spool off

execute snap_my_stats.start_snap

prompt
prompt	Now running the query
prompt

set termout off

alter session set events '10053 trace name context forever';
alter session set events '10104 trace name context forever';

select
	/*+
		ordered 
		use_hash(t2)
		use_hash(t3)
		use_hash(t4)
		swap_join_inputs(t2) 
		swap_join_inputs(t3) 
		full(t1)
		full(t2)
		full(t3)
		full(t4)
		traced
	*/
	count(t1.small_vc),
	count(t2.small_vc),
	count(t3.small_vc),
	count(t4.small_vc)
from
	t1,
	t4,
	t2,
	t3
where
	t4.id1 = t1.id
and	t4.id2 = t2.id
and	t4.id3 = t3.id
;

alter session set events '10104 trace name context off';
alter session set events '10053 trace name context off';


set termout on

spool treble_hash_manual_2

execute snap_my_stats.end_snap


spool off
