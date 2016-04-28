rem
rem	Script:		in_list_10g.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Simple selectivity - month of birth.
rem
rem	Versions tested 
rem		10.1.0.4 - very specifically
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
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

create table audience as
select
	trunc(dbms_random.value(1,13))	month_no
from
	all_objects
where
	rownum <= 1200
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

spool in_list_10g

select count(*) from audience where month_no in (13);
select count(*) from audience where month_no in (14);
select count(*) from audience where month_no in (15);
select count(*) from audience where month_no in (16);
select count(*) from audience where month_no in (17);
select count(*) from audience where month_no in (18);
select count(*) from audience where month_no in (19);
select count(*) from audience where month_no in (20);
select count(*) from audience where month_no in (21);
select count(*) from audience where month_no in (22);
select count(*) from audience where month_no in (23);


select count(*) from audience where month_no in (13, 15);
select count(*) from audience where month_no in (14, 16);
select count(*) from audience where month_no in (15, 17);
select count(*) from audience where month_no in (16, 18);

set autotrace off

spool off
