rem
rem	Script:		bitmap_mbrc.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Why does bitmap cost change with dbf_mbrc ?
rem	
rem	Notes
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The cost of a simple bitmap index access changes with
rem	the size of db_file_multiblock_read_count.  This is a 
rem	quick way to map what's going on.
rem
rem	We assume that a suitable plan_table has already been
rem	created and is accessible to the current user.
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
pctfree 70
pctused 30
nologging
as
select
	mod((rownum-1),20)		n1,		-- 20 values, scattered
	trunc((rownum-1)/500)		n2,		-- 20 values, clustered
--
	mod((rownum-1),25)		n3,		-- 25 values, scattered
	trunc((rownum-1)/400)		n4,		-- 25 values, clustered
--
	mod((rownum-1),25)		n5,		-- 25 values, scattered for btree
	trunc((rownum-1)/400)		n6,		-- 25 values, clustered for btree
--
	lpad(rownum,10,'0')		small_vc,
	rpad('x',220)			padding
from
	all_objects
where
	rownum  <= 10000
;

create bitmap index t1_i1 on t1(n1) 
nologging
pctfree 90
;

create bitmap index t1_i2 on t1(n2) 
nologging
pctfree 90
;

create bitmap index t1_i3 on t1(n3) 
nologging
pctfree 90
;
 
create bitmap index t1_i4 on t1(n4) 
nologging
pctfree 90
;

create        index t1_i5 on t1(n5) 
nologging
pctfree 90
;

create        index t1_i6 on t1(n6) 
nologging
pctfree 90
;


begin
	dbms_stats.gather_table_stats(
		ownname => user,
		tabname	=> 'T1',
		cascade	=> true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
.
/

delete from plan_table;
commit;

begin
	for r in 1..160 loop

		execute immediate
			'alter session set db_file_multiblock_read_count = ' || r;

		execute immediate
			'explain plan set statement_id = ''' ||
			to_char(r,'fm000') || 'N'' for ' ||
			' select /*+ index(t1) */ small_vc from t1 where n1 = 2';

	end loop;
end;
.
/

spool bitmap_mbrc

set linesize 100
set pagesize 90


select
	to_number(substr(statement_id,1,3))	id,
	cost					act_cost
from
	plan_table
where
	id = 0
and	statement_id like '%N%'
order by
	statement_id
;

spool off

