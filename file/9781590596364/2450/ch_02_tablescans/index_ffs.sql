rem
rem	Script:		index_ffs.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for 'Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	This script exists to demontrate the index fast full scan
rem

start setenv

execute dbms_random.seed(0)

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
pctfree 99
pctused 1
as
select
	rownum					id,
	trunc(100 * dbms_random.normal)		val,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;


create index t1_i on t1(val);

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

spool index_ffs

prompt
prompt	Statistics on index T1_I
prompt

select
	index_name, blevel, leaf_blocks, num_rows
from
	user_indexes
where
	index_name = 'T1_I'
;

set autotrace traceonly explain

prompt
prompt	Execution plan with genuine statistics
prompt

select count(*) from t1 where val > 100;

prompt
prompt	Using index_ffs to drive a nested loop
prompt

select
	/*+ ordered no_merge(tb) use_nl(ta) rowid(ta) */
	*
from
	(
		select /*+ index_ffs(t1) */
			rowid
		from t1
		where val > 250
		order by rowid
	)	tb,
	t1	ta
where	ta.rowid = tb.rowid
;

prompt
prompt	From another session, run the hack_stats script to
prompt	change the value of LEAF_BLOCKS on index t1_i, and
prompt	the cost of the basic index fast full scan will change
prompt	Suggested value:  set leaf blocks = 4
prompt

accept	x prompt "Press return after hacking the index stats"

prompt
prompt	Basic execution plan after hacking leaf_blocks
prompt

select count(*) from t1 where val > 100;

set autotrace off

spool off
