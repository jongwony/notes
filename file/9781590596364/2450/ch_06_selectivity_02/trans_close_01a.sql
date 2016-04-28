rem
rem	Script:		trans_close_01a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant on
rem		 8.1.7.4
rem
rem	Repeat trans_close_01.sql but using 
rem	the dbms_xplan package that is not 
rem	available to 8i
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
	mod(rownum,10)		n1,
	mod(rownum,10)		n2,
	to_char(rownum)		small_vc,
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

spool trans_close_01a

explain plan for
select
	small_vc
from
	t1
where
	n1 = 5
;

select * from table(dbms_xplan.display);
delete from plan_table;

explain plan for
select
	small_vc
from
	t1
where
	n1 = 5
and	n2 = n1
;

select * from table(dbms_xplan.display);
delete from plan_table;

spool off

set doc off
doc


#
