rem
rem	Script:		prefetch_test.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2001
rem	Purpose:	Example for 'Cost Based Oracle'
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem	Not  relevant
rem		 8.1.7.4 
rem
rem	This produces two different execution plans when
rem	system statistics (CPU costing) is enabled - but
rem	only under 9.2.0.6 - NOT for 10.1.0.4
rem
rem	This 9/10 difference may be a side effect of a
rem	change in strategy on rounding the arithmetic.
rem
rem	For my test case, under 9i with CPUSPEED = 500
rem		Rows between   1 and 227 	UNIQUE scan
rem		Rows between 228 and 319	range  scan
rem		Rows between 320 and 456 	UNIQUE scan
rem		Rows between 456 and 639	range  scan
rem		Rows between 640 and 684 	UNIQUE scan
rem		Rows between 685 and 999 	range scan
rem
rem	For my test case, under 9i with CPUSPEED = 1000
rem		Rows between   1 and 456 	UNIQUE scan
rem		Rows between 457 and 640	range  scan
rem		Rows between 640 and 913 	UNIQUE scan
rem		Rows between 914 and 999 	range scan
rem
rem	WARNING
rem	Start a new session before you run this script,
rem	or other test cases may have left the cpu costing
rem	feature disabled for the session
rem

start setenv

drop table driver;
drop table target;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

end;
/

begin
	dbms_stats.set_system_stats('MBRC',8);
	dbms_stats.set_system_stats('MREADTIM',20);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',500);
--	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/

create table target (
	id,
	small_vc,
	padding
)
as
select
	rownum,
	to_char(rownum),
	rpad('x',20)
from
	all_objects
where 
	rownum <= 3000
;

alter table target add constraint t_pk
primary key (id)
;

begin
	dbms_stats.gather_table_stats(
		user,
		'target',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool prefetch_test

begin
	for r in 1..999 loop
		begin
			execute immediate 
			'drop table driver';
		exception
			when others then null;
		end;

		execute immediate
		' create table driver (id, xref, padding) nologging as' ||
		' select rownum, rownum, rpad(''x'',20)' ||
		' from	all_objects' ||
		' where rownum <= ' || r;

		execute immediate
		' alter table driver add constraint d_pk ' ||
		' primary key (id)';

		execute immediate
		' begin' ||
		'	dbms_stats.gather_table_stats('||
		'		user,'||
		'		''driver'','||
		'		cascade => true,'||
		'		estimate_percent => null,'||
		'		method_opt => ''for all columns size 1'''||
		'	);'||
		' end;'
		;

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || ''' for ' ||
			' select ' ||
			' 	/*+ ordered use_nl(t) index(t) full(d) */'||
			' 	d.id, t.small_vc'||
			' from'||
			' 	driver	d,'||
			' 	target	t'||
			' where'||
			' 	t.id = d.xref'||
			' and	t.padding is not null';

	end loop;

end;
.
/


column options format a32

select 
	statement_id,
	options
from
	plan_table
where
	id = 4
order by
	statement_id
;

delete from plan_table;
commit;

spool off

