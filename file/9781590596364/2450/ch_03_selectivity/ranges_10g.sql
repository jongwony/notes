rem
rem	Script:		ranges_10g.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Possibilities with ranges
rem
rem	Versions tested 
rem		10.1.0.4 - very specifically
rem
rem	Notes:
rem

start setenv

execute dbms_random.seed(0);

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
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

variable b1 number;
variable b2 number;

spool ranges

set autotrace traceonly explain


prompt	Inside the limits

select	count(*)
from	audience
where	month_no between 6 and 9;

prompt	Outside the limits

select	count(*)
from	audience
where	month_no between 14 and 17;

prompt	Further outside the limits

select	count(*)
from	audience
where	month_no between 18 and 21;

prompt	Too far outside the limits

select	count(*)
from	audience
where	month_no between 24 and 27;


set autotrace off

spool off
