rem
rem	Script:		parallel.sql
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
rem	My standard setup is:
rem		8K block size
rem		Locally managed tablespace
rem		Uniform extent sizing at 1MB extents
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

spool parallel

set autotrace traceonly explain

select /*+ parallel(t1,1) */ count(*) from t1;
select /*+ parallel(t1,2) */ count(*) from t1;
select /*+ parallel(t1,3) */ count(*) from t1;
select /*+ parallel(t1,4) */ count(*) from t1;
select /*+ parallel(t1,5) */ count(*) from t1;
select /*+ parallel(t1,6) */ count(*) from t1;
select /*+ parallel(t1,7) */ count(*) from t1;
select /*+ parallel(t1,8) */ count(*) from t1;

set autotrace off

spool off
