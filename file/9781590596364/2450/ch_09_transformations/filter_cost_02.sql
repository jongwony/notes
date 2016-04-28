rem
rem	Script:		filter_cost_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		July 2004
rem	Purpose:	Investigation of existence and FILTER operation
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem
rem	If Oracle does a filter - does it check the
rem	'last probe' value before looking at the 
rem	hash table ?
rem
rem	Test this by using only 4 selected values 
rem	(with no collisions in the hash table) and 
rem	order the driving table in two different ways
rem
rem	Method 1: "Cycle" test - the four values were
rem	continuously recycled through the table.
rem
rem	Method 2: "Repeats" test - all occurences of each
rem	value in turn appeared in adjacent rows in the table.
rem
rem	Observation
rem		The CPU usage involved in the "cycle"
rem		test was 110% more than that involved
rem		in the "Repeats" test.
rem
rem	Conclusion:
rem		Oracle remembers the last value, and
rem		does not have to look in the hash table
rem		for it. The lookup in the hash table 
rem		accounts for the extra CPU usage.
rem
rem	Just think of the effect on CPU that changing 
rem	to ASSM could have in an unlucky case.
rem
rem
rem	Note: this script uses the package snap_my_stats,
rem	created by script snap_myst.sql, and dependend on
rem	the view v$my_stats, created in the sys account
rem	by the script c_mystats.sql
rem

start setenv

drop table main_tab; 
drop table filter_tab;

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

create table main_tab (
	n number, 
	v varchar2(100)
);

create table filter_tab (
	n number, 
	v varchar2(100)
)
pctfree 99
pctused 1
;

begin 
	for f in 1..4 loop
		insert into filter_tab values (f,rpad('a',100));
	end loop; 
	commit; 
end;
/

create unique index filter_tab_i1 on filter_tab (n);

begin
	dbms_stats.gather_table_stats(
		user,
		'filter_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


set feedback off
spool filter_cost_02


prompt	============================================
prompt	========= Test 1, Driving value cycled =====
prompt	============================================

truncate table main_tab;
begin 
	for f1 in 1..50000 loop 
		for f2 in 1..4 loop
			insert into main_tab values (f2,rpad('a',10));
		end loop; 
	end loop; 
	commit; 
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'main_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

rem alter session set events '10046 trace name context forever, level 4';

execute snap_my_stats.start_snap

select
	count(m.v)
from
	main_tab m
where	exists (
		select	/*+ no_unnest */
			v
		from	filter_tab f
		where	f.n=m.n
		and	f.v like 'a%'
	)
;
/
/
/
/
/
/
/
/
/

prompt	============================================
prompt	========= Test 1, Driving value cycled =====
prompt	============================================

execute snap_my_stats.end_snap

prompt
prompt	==============================================
prompt	========= Test 2, Driving value repeated =====
prompt	==============================================

truncate table main_tab;
begin 
	for f2 in 1..4 loop
		for f1 in 1..50000 loop 
			insert into main_tab values (f2,rpad('a',10));
		end loop; 
	end loop; 
	commit; 
end;
/


begin
	dbms_stats.gather_table_stats(
		user,
		'main_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


execute snap_my_stats.start_snap

select
	count(m.v) 
from
	main_tab m
where	exists (
		select	/*+ no_unnest */
			v 
		from	filter_tab f 
		where	f.n=m.n 
		and	f.v like 'a%'
	)
;
/
/
/
/
/
/
/
/
/

prompt	==============================================
prompt	========= Test 2, Driving value repeated =====
prompt	==============================================

execute snap_my_stats.end_snap

spool off


set doc off
doc


#
