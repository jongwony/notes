rem
rem	Script:		filter_cost_01a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	The filter operation 'remembers' previous results
rem	in a small in-memory hash table - so a bit of bad
rem	luck with hash-collisions (which are not preserved)
rem	can change your performance dramatically.
rem
rem	In 8i and 9i, dept_no = 67 will cause a collision 
rem	with dept_no =  0.
rem
rem	In 10g, dept_no = 432 will cause the collision
rem

start setenv

drop table emp;

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

create table emp(
	dept_no		not null,
	sal,
	emp_no		not null,
	padding,
	constraint e_pk primary key(emp_no)
)
as
with generator as (
	select	--+ materialize
		rownum 		id
	from	all_objects 
	where	rownum <= 1000
)
select
	/*+ ordered use_nl(v2) */
	mod(rownum,6),
	rownum,
	rownum,
	rpad('x',60)
from
	generator	v1,
	generator	v2
where
	rownum <= 20000
;

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 'EMP',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/


spool filter_cost_01a

set timing on


prompt	With 'lucky' data

set autotrace on statistics

select
	/*+ no_merge(iv) */
	count(*)
from (
	select 	outer.* 
	from	emp outer
	where	outer.sal >
			(select /*+ no_unnest */ 
				avg(inner.sal) 
	 		from	emp inner 
			where	inner.dept_no = outer.dept_no
		)
)	iv
;


set autotrace off
set timing off


update emp
set dept_no = 67		-- value for 9i
-- set dept_no = 432		-- value for 10g
where rownum = 1
;

commit;


set timing on
set autotrace on statistics

prompt	With one 'unlucky' row

select
	/*+ no_merge(iv) */
	count(*)
from (
	select 	outer.* 
	from	emp outer
	where	outer.sal >
			(select /*+ no_unnest */ 
				avg(inner.sal) 
	 		from	emp inner 
			where	inner.dept_no = outer.dept_no
		)
)	iv
;


set autotrace off
set timing off

spool off
