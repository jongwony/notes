rem
rem	Script:		ranges.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Possibilities with ranges
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.6
rem		 8.1.7.4
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

select	count(*) 
from	audience 
where	month_no > 8
;

select	count(*) 
from	audience 
where	month_no >= 8
;

select	count(*) 
from	audience 
where	month_no < 8
;

select	count(*) 
from	audience 
where	month_no <= 8
;

select	count(*) 
from	audience 
where	month_no between 6 and 9
;

select	count(*) 
from	audience 
where	month_no >= 6 and month_no <= 9
;

select	count(*) 
from	audience 
where	month_no >= 6 and month_no < 9
;

select	count(*) 
from	audience 
where	month_no > 6 and month_no <= 9
;

select	count(*) 
from	audience 
where	month_no > 6 and month_no < 9
;

select	count(*) 
from	audience 
where	month_no > :b1
;

select	count(*) 
from	audience 
where	month_no >= :b1
;

select	count(*) 
from	audience 
where	month_no < :b1
;

select	count(*) 
from	audience 
where	month_no <= :b1
;

select	count(*) 
from	audience 
where	month_no between :b1 and :b2
;

select	count(*) 
from	audience 
where	month_no >= :b1 and month_no <= :b2
;

select	count(*) 
from	audience 
where	month_no >= :b1 and month_no < :b2
;

select	count(*) 
from	audience 
where	month_no > :b1 and month_no <= :b2
;

select	count(*) 
from	audience 
where	month_no > :b1 and month_no < :b2
;

select	count(*) 
from	audience 
where	month_no > 12
;

select	count(*) 
from	audience 
where	month_no between 25 and 30
;


rem
rem	And now for the funny one
rem

select	count(*)
from	audience
where	month_no >  8 
or	month_no <= 8
;

set autotrace off

spool off
