rem
rem	Script:		first_rows.sql
rem	Author:		Jonathan Lewis
rem	Dated:		June 2002
rem	Purpose:	Problems with FIRST_ROWS optimisation
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The FIRST_ROWS optimizer does not have a sensible strategy
rem	for dealing with optimisation of an ORDER BY (and possibly
rem	other variants such as GROUP BY) when it finds it can use
rem	an index to do the ORDER BY "free of charge".
rem
rem	This example demonstrates the point. Without the in-line
rem	view, Oracle does a full scan on the primary key index to
rem	return the 100 required rows in order, at a total cost
rem	and total execution time that is much higher than that of
rem	using the required index.
rem
rem	Of course, it is arguably the case that this is correct
rem	behaviour if we assume that the time to the first row is
rem	important, and therefore we avoid collecting a large number
rem	of rows and sorting them.  In practice, this is perhaps not
rem	really likely to be the case.
rem
rem	Bug number 670328 applies
rem
rem	Parameter _sort_elimination_cost_ratio affects the break
rem	point between optimising for the WHERE clause and optimising
rem	for the ORDER BY clause.
rem
rem	If the parameter is zero, the ORDER BY clause takes precedence
rem	If the parameter is non-zero, then the index is used if the cost 
rem	of using it is less than the cost of doing the sort multiplied 
rem	by the value of the parameter.
rem
rem	Special note for 10g:
rem	The parameter still has the same effect in general, but zero
rem	now means zero, not (effectively) infinity.  The default of
rem	zero will now effectively ignore the index option unless it
rem	is actually cheaper than the non-index option. A non-zero
rem	value will behave as it always used to
rem

start setenv

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

create table t1 as
select
	rownum			id,
--	mod(rownum,100)		modded,
	mod(rownum,300)		modded,
	lpad(rownum,1000)	padding
from
	all_objects
where
	rownum <= 10000
;

alter table t1 add constraint t1_pk primary key(id);
create index t1_mod on t1(modded);

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

alter session set optimizer_mode=first_rows;

set autotrace traceonly explain

spool first_rows

prompt
prompt	Get a base-line cost and plan for acquiring the rows
prompt

select	*
from	t1
where	modded = 0
;

prompt
prompt	See what happens if we add an 'order by primary key'.
prompt

select	*
from	t1
where	modded = 0
order by 
	id
;

rem
rem	Block the PK index from being used for ordering, and see
rem	that Oracle could notionally get a better path. Strangely
rem	the cost varies depending on the strategy used for blocking
rem	the index. On my 9.2.0.6 test, the no_merge hint managed to
rem	reduce the lengths of the rows to be sorted, and therefore
rem	calculated a smaller cost.
rem

prompt
prompt	Block the index with a no_merge hint
prompt

select * from (
select	/*+ no_merge */ 
	*
from	t1
where	modded = 0
)
order by 
	id
;


prompt
prompt	Block the index with a no_index hint
prompt

select	/*+ no_index(t1,t1_pk) */
	*
from	t1
where	modded = 0
order by 
	id
;

set autotrace off

rem
rem	The costs under 8i are:
rem		Using the PK index to avoid the sort: 		1,450
rem		Block the PK index (no_index) and sorting:	43
rem
rem	Cost ratio:	1450/43 = 33.729, so we test 
rem		_sort_elimination_cost_ratio at 33 and 34
rem
rem	At 33:  43 * 33 = 1,419:  so the PK nosort should be ignored
rem	At 34:	43 * 34 = 1,462:  so the PK nosort falls inside the limit.
rem
rem	(Because of a change in the cost in 10g, the break point
rem	for the parameter was 32/33 on my 10g system)
rem

set autotrace traceonly explain 

alter session set "_sort_elimination_cost_ratio" = 34;

prompt
prompt	Cost ratio set to 34 - PK path should be accepted
prompt

select
	*
from	t1
where	modded = 0
order by 
	id
;

alter session set "_sort_elimination_cost_ratio" = 33;

prompt
prompt	Cost ratio set to 33 - PK NOSORT should be too expensive
prompt

select
	*
from	t1
where	modded = 0
order by 
	id
;

set autotrace off

spool off
