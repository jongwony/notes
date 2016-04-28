rem
rem	Script:		pv.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Simple selectivity
rem
rem	Last tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	Odd side effects of partition views and in lists.
rem
rem	All three versions can handle these partition view
rem	queries very effectively - whether or not the parameter
rem	partition_view_enabled is set to true or false.
rem
rem	8i, 9i, and 10g report partition view queries very differently.
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

spool pv

select count(*) from audience where month_no in (1,25);
select count(*) from audience where month_no not in (1,25);


select count(*) from
(
select * from audience where month_no in (1,25)
union all
select * from audience where month_no not in (1,25)
)
/


select * from
(
select * from audience where month_no in (1,25)
union all
select * from audience where month_no not in (1,25)
)
where  month_no = 25
/


set autotrace off

spool off
