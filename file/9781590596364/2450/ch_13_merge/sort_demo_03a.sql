rem
rem	Script:		sort_demo_03a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.3
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Using explain plan in a pl/sql loop to test the
rem	effects on cost of changing the sort_area_size
rem	for the million row table.
rem
rem	The version with CPU costing enabled
rem

start setenv

execute dbms_random.seed(0)

drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

end;
/

begin
	dbms_stats.set_system_stats('MBRC',6.588);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/


rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id,
	substr(dbms_random.string('U',6),1,6)	sortcode
from	all_objects 
where	rownum <= 5000
;


create table t1 
nologging		-- adjust as necessary
as
/*
with generator as (
	select	--+ materialize
		rownum 				id,
	substr(dbms_random.string('U',6),1,6)	sortcode
	from	all_objects 
	where	rownum <= 5000
)
*/
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
/


spool sort_demo_03

select
	table_name, blocks, avg_row_len
from	user_tables
where	table_name in ('T1')
;


select
	table_name, column_name, avg_col_len
from
	user_tab_columns
where	table_name in ('T1')
order by
	table_name, column_name
;

delete from plan_table;
commit;

begin
	for r in 1..256 loop

		execute immediate
		'alter session set sort_area_size = ' || r * 131072;

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || ''' for ' ||
		'select	sortcode from t1 order by sortcode';
--		'create index t1_i1 on t1(sortcode)';

	end loop;
end;
.
/

select
	to_number(substr(statement_id,1,3))		id,
	round(to_number(substr(statement_id,1,3))/8,3)	MB,
	cost						act_cost
from
	plan_table
where
	id = 0
order by
	statement_id
;

rem	delete from plan_table;
commit;


spool off
