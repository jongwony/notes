rem
rem	Script:		sort_stream_b.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not tested
rem		 8.1.7.4
rem
rem	Re-run the query from sort_demo_01.sql with
rem		cpu costing enabled
rem		workarea_size_policy = manual
rem

start setenv

set pagesize 100
set linesize 1024
set trimspool on

execute dbms_random.seed(0)

drop table t1;
drop table generator;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

end;
/

/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

create table generator as
select
	rownum 	id,
	substr(dbms_random.string('U',6),1,6)	sortcode
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
	substr(dbms_random.string('U',6),1,6)	sortcode
	from	all_objects 
	where	rownum <= 5000
)
select
	/*+ ordered use_nl(v2) */
	substr(v2.sortcode,1,4) || substr(v1.sortcode,1,2) sortcode
from
	generator	v1,
	generator	v2
where
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
.
/


begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10.000);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/

delete from plan_table;
commit;

alter session set workarea_size_policy = manual;

spool sort_stream_b

prompt	Check how much to subtract from the cost to 
prompt	allow for the basic cost of the tablescan

set autotrace traceonly explain
select count(*) from t1;
set autotrace off

define	m_scan_cost = 283

begin
	for r in 1..512 loop

		execute immediate
		'alter session set sort_area_size = ' || (r * 65536);

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || ''' for ' ||
		'
			select
				sortcode
			from
				t1
			order by
				sortcode
		';

	end loop;
end;
.
/

rem
rem	The constant in the sort_cost column is something I had to
rem	discover after running the script once, and checking the
rem	autotrace output for the cost of the two tablescans after
rem	getting to the steady state value for total_cost
rem

select
	id, 
	sort_kb,
	total_cost,
	sort_cost,
	sort_cost - lag(sort_cost,1) over(order by id)	delta
from
	(
	select
		to_number(substr(statement_id,1,3))		id,
		64 * to_number(substr(statement_id,1,3))	sort_KB,
		cost						total_cost,
		cost - &m_scan_cost				sort_cost
	from
		plan_table
	where
		id = 0
	order by
		statement_id
	)
order by id
;


delete from plan_table;
commit;

spool off


