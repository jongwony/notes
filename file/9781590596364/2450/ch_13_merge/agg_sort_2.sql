rem
rem	Script:		agg_sort_2.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The I/O cost / pass of sorting is affected 
rem	by the expected size of the output from 
rem	9i onwards - this is probably from the
rem	_new_sort_cost_estimate
rem
rem
rem	Note - for group by / distinct, the number of 
rem	distinct values output for a multi-column 
rem	aggregation of N columns is estimates by taking
rem	the product of the N columns num_distincts, and
rem	then dividing N-1 times by the square root of 2.
rem
rem	We can control the num_distinct values, and check
rem	the effect on the I/O cost / pass.
rem
rem	A simple loop, using num_distinct for just one column
rem	gives break point / grouping cardinality at
rem
rem	 col1.distinct   cost  group card
rem	--------------   ----  ----------
rem		  769      13         544
rem		  770      14         545
rem
rem		 2309      14        1633
rem		 2310      15        1634
rem

start setenv

execute dbms_random.seed(0)

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

/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;


create table t1 
nologging
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select
	/*+ ordered use_nl(v2) */
	dbms_random.string('U',trunc(dbms_random.value(1,3)))			col1,
	dbms_random.string('U',trunc(dbms_random.value(1,3)))			col2
from
	generator	v1,
	generator	v2
where
	rownum <= 5000
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


create or replace procedure set_col_dist(
	i_col	in	varchar2,
	i_dist	in	number
)
as

	srec			dbms_stats.statrec;
	m_distcnt		number;
	m_density		number;
	m_nullcnt		number;
	m_avgclen		number;

begin

	dbms_stats.get_column_stats(
		ownname		=> NULL,
		tabname		=> 't1',
		colname		=> i_col, 
		distcnt		=> m_distcnt,
		density		=> m_density,
		nullcnt		=> m_nullcnt,
		srec		=> srec,
		avgclen		=> m_avgclen
	); 

	dbms_stats.set_column_stats(
		ownname		=> NULL,
		tabname		=> 't1',
		colname		=> i_col, 
		distcnt		=> i_dist,
		density		=> m_density,
		nullcnt		=> m_nullcnt,
		srec		=> srec,
		avgclen		=> m_avgclen
	); 

end;
/


spool agg_sort_2


column col1 format a4
column col2 format a4

rem	alter session set events '10053 trace name context forever';
set autotrace traceonly explain


prompt	Baseline: 

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(100 * 71 / sqrt(2)) = 5021	-- So card = 5,000

execute set_col_dist('col1',100)
execute set_col_dist('col2',71)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(50 * 71 / sqrt(2)) = 2511	-- So card = 2,511

execute set_col_dist('col1',50)
execute set_col_dist('col2',71)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(25 * 71 / sqrt(2)) = 1256	-- So card = 1,256

execute set_col_dist('col1',25)
execute set_col_dist('col2',71)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(3500 * 1 / sqrt(2)) = 2475 -- So card = 2,475

execute set_col_dist('col1',3500)
execute set_col_dist('col2',1)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


set autotrace off
alter session set events '10053 trace name context off';

delete from plan_table;
commit;

rem
rem	The ranges have been set for my particular data set
rem


begin
	set_col_dist('col2',1);

	for r in 768..2312 loop

		if not (r between 775 and 2305) then

			set_col_dist('col1',r);

			execute immediate
				'explain plan set statement_id = ''' ||
				to_char(r,'fm0000') || ''' for ' ||
				'select ' ||
				'	col1, col2, count(*) ' ||
				'from ' ||
				'	t1 ' ||
				'group by ' ||
				'	col1, col2'
				;

		end if;

	end loop;

end;
/


select 
	statement_id,
	cost,
	cardinality
from
	plan_table
where
	id = 0
order by
	statement_id
;

delete from plan_table;
commit;

spool off

execute set_col_dist('col2',1)

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever, level 2';

prompt	ceil(769 * 1 / sqrt(2)) = 544

execute set_col_dist('col1',769)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(770 * 1 / sqrt(2)) = 545

execute set_col_dist('col1',770)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(2309 * 1 / sqrt(2)) = 1633

execute set_col_dist('col1',2309)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;

prompt	ceil(2310 * 1 / sqrt(2)) = 1634

execute set_col_dist('col1',2310)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;

prompt	ceil(7100 * 1 / sqrt(2)) = 5021  (card = 5000)

execute set_col_dist('col1',7100)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;


prompt	ceil(8000 * 1 / sqrt(2)) = 5021  (card = 5000)

execute set_col_dist('col1',8000)

select 
	col1, col2, count(*)
from
	t1
group by
	col1, col2
;



alter session set events '10053 trace name context off';
set autotrace off


