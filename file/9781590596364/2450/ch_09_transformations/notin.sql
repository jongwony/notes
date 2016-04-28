rem
rem	Script:		notin.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	An apparent contradiction.
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


create table t1(n1 number, v1 varchar2(20));
create table t2(n1 number, v1 varchar2(20));

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

insert into t1 values(99,'Ninety-nine');
commit;

rem
rem	We have a 99 row in table t1
rem	We do not have a 99 row in table t2
rem
rem	So find the rows in table t1 which for which 
rem	there is no corresponding row in table t2
rem

spool notin


select	* 
from	t1 
where	t1.n1 not in (
		select t2.n1 
		from t2
	)
;


rem
rem	We insert a row (which is NOT a 99 row)
rem	into table t2 and repeat the query
rem

insert into t2 values (null, null);
commit;


set echo on

select * from t1 where n1 = 99;
select * from t2 where n1 = 99;

select	* 
from	t1 
where	t1.n1 not in (
		select t2.n1 
		from t2
	)
;

rem
rem	If we restrict both tables to 
rem	non-null values, we get an answer.
rem

select * 
from	t1 
where	t1.n1 is not null
and	t1.n1 not in (
		select t2.n1 
		from t2
		where t2.n1 is not null
	)
;

set echo off

spool off
