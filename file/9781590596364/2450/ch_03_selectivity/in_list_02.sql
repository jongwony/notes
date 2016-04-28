rem
rem	Script:		in_list_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Simple selectivity.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	Checking effects of in-list error in 8i with larger number
rem	of possible distinct values in base column.
rem

start setenv

drop table audience;

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

/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 1000
;

*/


create table audience as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
select
	trunc(dbms_random.value(1,1001))	month_no
from
	generator	v1,
	generator	v2
where
	rownum <= 12000
;


begin
	dbms_stats.gather_table_stats(
		user,
		'audience',
		cascade=>true,
		estimate_percent => null,
		method_opt =>'for all columns size 1'
	);
end;
/

set autotrace traceonly explain

spool in_list_02

select count(*) from audience where month_no in (1,2);
select count(*) from audience where month_no in (1,2,3);
select count(*) from audience where month_no in (1,2,3,4);
select count(*) from audience where month_no in (1,2,3,4,5);
select count(*) from audience where month_no in (1,2,3,4,5,6);
select count(*) from audience where month_no in (1,2,3,4,5,6,7);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9,10);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9,10,11);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9,10,11,12);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9,10,11,12,13);
select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9,10,11,12,13,14);


select count(*) from audience where month_no in (
	 1, 2, 3, 4, 5, 6, 7, 8, 9,10,
	11,12,13,14,15,16,17,18,19,20,
	21,22,23,24,25,26,27,28,29,30
);

set autotrace off

spool off
