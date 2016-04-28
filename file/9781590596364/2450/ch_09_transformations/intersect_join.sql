rem
rem	Script:		template.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4 
rem
rem	Not relevant
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Oracle 10g can transform set operations
rem	(viz: intersect, minus, union all, union)
rem	joins under certain conditions.  The conversion
rem	is limited to intersection and minus, and is in
rem	a beta-like state, requiring the hidden parameter
rem	_convert_set_to_join to be modified.
rem

start setenv

drop table t2;
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
	trunc((rownum-1)/15)	n1,
	trunc((rownum-1)/15)	n2,
	rpad(rownum,180)	v1
from all_objects 
where rownum <= 3000
;

create table t2
as
select 
	mod(rownum,200)		n1,
	mod(rownum,200)		n2,
	rpad(rownum,180)	v1
from all_objects 
where rownum <= 3000
;

create index t1_i1 on t1(n1);
create index t2_i1 on t2(n1);

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

begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool intersect_join

set autotrace traceonly explain

prompt	Simple intersection query

select n2 from t1 where n1 < 3
intersect
select n2 from t2 where n1 < 2
;

prompt	Simple minus query

select n2 from t1 where n1 < 3
minus
select n2 from t2 where n1 < 2
;

alter session set "_convert_set_to_join"=true;

prompt	Repeated with _convert_set_to_join = true
prompt	Simple intersection query

select n2 from t1 where n1 < 3
intersect
select n2 from t2 where n1 < 2
;

prompt	Simple minus query

select n2 from t1 where n1 < 3
minus
select n2 from t2 where n1 < 2
;

prompt	Alternative form of the intersect

select
	distinct t1.n2
from
	t1, t2
where
	t1.n1 < 3
and	t2.n1 < 2
and	sys_op_map_nonnull(t2.n2) = sys_op_map_nonnull(t1.n2)
;


prompt	Alternative form of the minus

select 
	distinct n2 
from 
	t1
where
	n1 < 3
and	not exists (
		select 
			null
		from 
			t2
		where 
			n1 < 2
		and 	sys_op_map_nonnull(t2.n2) = sys_op_map_nonnull(t1.n2)
	)
;

set autotrace off

spool off

set doc off
doc



Full execution plan for the intersection query:
-----------------------------------------------

  Id  Par  Pos  Ins Plan
---- ---- ---- ---- ---------------------------------------------------------------------
   0        24      SELECT STATEMENT (all_rows)     Old Cost (24,28,448) New Cost (24,0,0)
   1    0    1        SORT    (unique)  Old Cost (24,28,448) New Cost (24,0,0)
   2    1    1          HASH JOIN     Old Cost (18,33,528) New Cost (18,0,0) 
                              Access (SYS_OP_MAP_NONNULL("N2")=SYS_OP_MAP_NONNULL("N2"))
   3    2    1    1       TABLE ACCESS (analyzed) TABLE TEST_USER T1 (by index rowid)  Old Cost (3,30,240) New Cost (3,0,0)
   4    3    1              INDEX (analyzed) INDEX TEST_USER T1_I1 (range scan)  Old Cost (2,30,0) New Cost (2,0,0) 
                                  (Columns 1) Access ("N1"<2)
   5    2    2    2       TABLE ACCESS (analyzed) TABLE TEST_USER T2 (full)  Old Cost (14,45,360) New Cost (14,0,0) 
                                Filter ("N1"<3)

Full execution plan for the distinct query:
-------------------------------------------

  Id  Par  Pos  Ins Plan
---- ---- ---- ---- ---------------------------------------------------------------------
   0        24      SELECT STATEMENT (all_rows)     Old Cost (24,28,448) New Cost (24,0,0)
   1    0    1        SORT    (unique)  Old Cost (24,28,448) New Cost (24,0,0)
   2    1    1          HASH JOIN     Old Cost (18,33,528) New Cost (18,0,0) 
                              Access (SYS_OP_MAP_NONNULL("T2"."N2")=SYS_OP_MAP_NONNULL("T1"."N2"))
   3    2    1    1       TABLE ACCESS (analyzed) TABLE TEST_USER T1 (by index rowid)  Old Cost (3,30,240) New Cost (3,0,0)
   4    3    1              INDEX (analyzed) INDEX TEST_USER T1_I1 (range scan)  Old Cost (2,30,0) New Cost (2,0,0) 
                                  (Columns 1) Access ("T1"."N1"<2)
   5    2    2    2       TABLE ACCESS (analyzed) TABLE TEST_USER T2 (full)  Old Cost (14,45,360) New Cost (14,0,0) 
                                Filter ("T2"."N1"<3)

#
