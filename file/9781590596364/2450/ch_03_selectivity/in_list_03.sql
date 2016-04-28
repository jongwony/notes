rem
rem	Script:		in_list_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Simple selectivity
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	Side effects of NOT IN.
rem		selectivity of not(P) is supposed to be 1 - selectivity(P)
rem

start setenv
set timing off

drop table audience;
begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
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
		user,'audience',
		cascade=>true,
		estimate_percent => null,
		method_opt =>'for all columns size 1'
	);
end;
/

set autotrace traceonly explain

spool in_list_03

select count(*) from audience where month_no in (1,2);
select count(*) from audience where month_no not in (1,2);

select count(*) from audience where month_no in (1,2,3);
select count(*) from audience where month_no not in (1,2,3);

select count(*) from audience where month_no in (1,2,3,4);
select count(*) from audience where month_no not in (1,2,3,4);

select count(*) from audience where month_no in (1,2,3,4,5,6,7,8,9,10,11,12);
select count(*) from audience where month_no not in (1,2,3,4,5,6,7,8,9,10,11,12);


select count(*) from audience where month_no in (
	 1, 2, 3, 4, 5, 6, 7, 8, 9,10,
	11,12,13,14,15,16,17,18,19,20,
	21,22,23,24,25,26,27,28,29,30
);

select count(*) from audience where month_no not in (
	 1, 2, 3, 4, 5, 6, 7, 8, 9,10,
	11,12,13,14,15,16,17,18,19,20,
	21,22,23,24,25,26,27,28,29,30
);


select count(*) from audience where month_no in (1,25);
select count(*) from audience where month_no not in (1,25);


set autotrace off

spool off
