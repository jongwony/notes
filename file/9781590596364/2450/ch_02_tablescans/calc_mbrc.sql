rem
rem	Script:		calc_mbrc.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2002
rem	Purpose:	Calculate cost of tablescan for changing values of mbrc
rem	
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes
rem	Cost with cpu_costing is higher than cost with nocpu_costing
rem	Your system may stop changing before it gets to 128 blocks,
rem	it could go higher - the limit is usually dependent on the
rem	operating system and the current block size, and may top out 
rem	when 'scan size * block_size'reaches 1 MB.
rem
rem	Note:
rem	The script requires you to create a plan_table as it cycles
rem	through the values for db_file_multiblock_read_count, explaining 
rem	a tablescan into the plan_table to find the cost.
rem
rem	This script creates a fairly small table (1,000 blocks), but we then
rem	use dbms_stats() to tell Oracle that it was a very big table (say 10M 
rem	blocks)
rem
rem	The number of blocks to fake is the input parameter
rem
rem	The code caters for CPU Costing on and off for 9i and above,
rem	so is more complex than it needs to be for Oracle 8
rem

start setenv
set timing off

define m_blocks=128000
rem	define m_blocks = &1

alter session set optimizer_mode = all_rows;

drop table t1;

create table t1
nologging
pctfree 90
pctused 10
storage (initial 40M)
as
select
	rownum		id,
	to_char(rownum)	vc_small,
	rpad('x',1000)	padding
from
	all_objects
where
	rownum <= 1000
;

analyze table t1 compute statistics;

rem
rem	Over-ridden by:
rem

begin
	dbms_stats.set_table_stats(
		ownname		=> null,
		tabname		=>'T1',
		numrows		=> &m_blocks,
		numblks		=> &m_blocks,
		avgrlen		=> 3500,
		flags		=> 0
	);
end;
/


delete from plan_table;
commit;

begin
	for r in 1..128 loop

		execute immediate
		'alter session set db_file_multiblock_read_count = ' || r;

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || 'N'' for ' ||
		' select /*+ nocpu_costing */ count(*) from t1';

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || 'C'' for ' ||
		' select /*+ cpu_costing */ count(*) from t1';

	end loop;
end;
.
/

spool calc_mbrc

set linesize 100
set pagesize 90

rem
rem	We use the 'cost - 1' for Oracle 9.2 because it has 
rem		_tablescan_cost_plus_one = true;
rem	whereas Oracle 8.1.7 has
rem		_tablescan_cost_plus_one = false;
rem

select
	to_number(substr(statement_id,1,3)) id,
	cost							act_cost,
	round(&m_blocks/to_number(substr(statement_id,1,3)),0)	old_cost,
	round(&m_blocks/cost,3)					eff_mbrc
--	round(&m_blocks/(cost-1),3)				eff_mbrc
from
	plan_table
where
	id = 0
and	statement_id like '%N%'
order by
	statement_id
;

spool off

