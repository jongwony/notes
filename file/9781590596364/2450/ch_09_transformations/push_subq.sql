rem
rem	Script:		push_subq.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem	
rem	Notes
rem	Really only relevant for 8.1
rem
rem	This will unnest in 9i and 10g, and the point 
rem	of the exercise will be lost, although you can
rem	resurrect the behaviour by using the UNNEST hint.
rem
rem	The data in the three tables is arranged to that
rem	it requires much less work to do the subquery 
rem	early. But Oracle always postpones subqueries
rem	to the end of execution.
rem
rem	Table child has 8 rows for every row in parent. 
rem	subtest is used to eliminate data - and the smart
rem	move is to eliminate parent rows before joining,
rem	but Oracle (8i) joins before eliminating
rem
rem	The NO_UNNEST hint is there to force 9i and 10g
rem	to use the filter option that 8i has to take
rem

start setenv

drop table subtest;
drop table child;
drop table parent;

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

create table parent(
	id1		number not null,
	small_vc1	varchar2(10),
	small_vc2	varchar2(10),
	padding		varchar2(200),
	constraint par_pk primary key(id1)
);


create table child(
	id1		number	not null,
	id2		number	not null,
	small_vc1	varchar2(10),
	small_vc2	varchar2(10),
	padding		varchar2(200),
	constraint chi_pk primary key (id1,id2)
)
;

create table subtest (
	id1		number not null,
	small_vc1	varchar2(10),
	small_vc2	varchar2(10),
	padding		varchar2(200),
	constraint sub_pk primary key(id1)
)
;


insert into parent
select
	rownum,
	to_char(rownum),
	to_char(rownum),
	rpad(to_char(rownum),100)
from
	all_objects
where	rownum <= 3000
;

commit;

begin
	for i in 1..8 loop
		insert into child
		select
			rownum,
			i,
			to_char(rownum),
			to_char(rownum),
			rpad(to_char(rownum),100)
		from
			parent;
	commit;
	end loop;
end;
/

insert into subtest
select * from parent;
commit;

begin
	dbms_stats.gather_table_stats(
		user,
		'parent',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'child',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'subtest',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool push_subq

rem
rem	In the first case, we visit parent then child, 
rem	filtering finally against sub_test, for a total 
rem	workload of about 1250 logical I/Os
rem

set autotrace traceonly

prompt
prompt	With no_unnest, without push_subq
prompt

select
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	par.id1 between 100 and 200
and	chi.id1 = par.id1		
and	exists (
		select	
			/*+ no_unnest */
			null
		from	subtest	sub
		where 
			sub.small_vc1 = par.small_vc1
		and	sub.id1 = par.id1
		and	sub.small_vc2 >= '2'
	)
;


rem
rem	Now push the subquery to the earliest point
rem
rem	In the second case, we visit parent then sub_test
rem	to apply the subquery, then finally child, for 
rem	a total workload of about 300 logical I/Os
rem

prompt
prompt	With no_unnest, with push_subq
prompt

select
	/*+ push_subq */
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	par.id1 between 100 and 200
and	chi.id1 = par.id1		
and	exists (
		select	
			/*+ no_unnest */
			null
		from	subtest	sub
		where 
			sub.small_vc1 = par.small_vc1
		and	sub.id1 = par.id1
		and	sub.small_vc2 >= '2'
	)
;


rem
rem	Next we have one without the no_unnest hint so
rem	that 9i and 10g can show what they do with the
rem	push_subq hint. Note the drop in consistent gets
rem

prompt
prompt	Without no_unnest, with push_subq
prompt

select
	/*+ push_subq */
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	par.id1 between 100 and 200
and	chi.id1 = par.id1		
and	exists (
		select	
			null
		from	subtest	sub
		where 
			sub.small_vc1 = par.small_vc1
		and	sub.id1 = par.id1
		and	sub.small_vc2 >= '2'
	)
;


rem
rem	Then one with no push_subq so that 9i and 10g
rem	can do whatever they want. 
rem

prompt
prompt	Without no_unnest, without push_subq
prompt

select
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	par.id1 between 100 and 200
and	chi.id1 = par.id1		
and	exists (
		select	
			null
		from	subtest	sub
		where 
			sub.small_vc1 = par.small_vc1
		and	sub.id1 = par.id1
		and	sub.small_vc2 >= '2'
	)
;

rem
rem	And finally one to show that 8i can do 
rem	the same as 9i and 10g if requested
rem

prompt
prompt	With explicit unnest, without push_subq
prompt	(Especially for 8i)
prompt

select
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	par.id1 between 100 and 200
and	chi.id1 = par.id1		
and	exists (
		select
			/*+ unnest */
			null
		from	subtest	sub
		where 
			sub.small_vc1 = par.small_vc1
		and	sub.id1 = par.id1
		and	sub.small_vc2 >= '2'
	)
;

set autotrace off

spool off


set doc off
doc

With push_subq and no_unnest

The plan from 9.2.0.6 v$sql_plan including two columns 
from v$sql_plan_statistics.

By comparing the ROWS on the INDEX PAR_PK line with the
STARTS on the INDEX SUB_PK line, that the subquery is
operated once for each index access on PAR_PK, before
Oracle goes to the PARENT table.  In effect there ought
to be a FILTER between the fourth and fifth lines.

Starts     Rows Plan
------ -------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------
                SELECT STATEMENT (all_rows)    Cost (14,,) (Columns 0)
     1        8   TABLE ACCESS (analyzed) TEST_USER CHILD (by index rowid)  Cost (2,1,9)  IO_Cost (2,,) (Columns 0)
     1       10     NESTED LOOPS    Cost (14,6,108)  IO_Cost (14,,) (Columns 0)
     1        1       TABLE ACCESS (analyzed) TEST_USER PARENT (by index rowid)  Cost (4,5,45)  IO_Cost (4,,) (Columns 0) 
				Filter ( IS NOT NULL)
     1      101         INDEX (analyzed) TEST_USER PAR_PK (range scan)  Cost (2,102,)  IO_Cost (2,,) (Columns 1) 
				Access ("SYS_ALIAS_2"."ID1">=100 AND "SYS_ALIAS_2"."ID1"<=200)
   101        1         TABLE ACCESS (analyzed) TEST_USER SUBTEST (by index rowid)  Cost (2,1,14)  IO_Cost (2,,) (Columns 0) 
				Filter ("SUB"."SMALL_VC1"=:B1 AND "SUB"."SMALL_VC2">='2')
   101      101           INDEX (analyzed) TEST_USER SUB_PK (unique scan)  Cost (1,1,)  IO_Cost (1,,) (Columns 1) 
				Access ("SUB"."ID1"=:B1)
     1        8       INDEX (analyzed) TEST_USER CHI_PK (range scan)  Cost (1,1,)  IO_Cost (1,,) (Columns 1) 
				Access ("CHI"."ID1"="SYS_ALIAS_2"."ID1") 
				Filter ("CHI"."ID1">=100 AND "CHI"."ID1"<=200)



The same query passed through explain plan 9.2.0.6
You will note that there are some differences in the 
filter_predicates described. Explain plan appears to 
show that it is filtering with a subquery after reaching 
the table, v$sql_plan has lost the detail of the subquery.

Plan
---------------------------------------------------------------------
SELECT STATEMENT (all_rows)     Cost (14,6,108) IO_Cost (14,,)
  TABLE ACCESS (analyzed)  TEST_USER CHILD (by index rowid)  Cost (2,1,9) IO_Cost (2,,)
    NESTED LOOPS     Cost (14,6,108) IO_Cost (14,,)
      TABLE ACCESS (analyzed)  TEST_USER PARENT (by index rowid)  Cost (4,5,45) IO_Cost (4,,) 
		Filter ( 
		         EXISTS (
				SELECT /*+ NO_UNNEST */ 0 
					FROM "SUBTEST" "SUB" 
					WHERE "SUB"."ID1"=:B1
					AND "SUB"."SMALL_VC1"=:B2 
					AND "SUB"."SMALL_VC2">='2'
				)
		)
        INDEX (analyzed) UNIQUE TEST_USER PAR_PK (range scan)  Cost (2,102,) IO_Cost (2,,) (Columns 1) 
		Access ("SYS_ALIAS_2"."ID1">=100 AND "SYS_ALIAS_2"."ID1"<=200)
        TABLE ACCESS (analyzed)  TEST_USER SUBTEST (by index rowid)  Cost(2,1,14) IO_Cost (2,,) 
		Filter ("SUB"."SMALL_VC1"=:B1 AND "SUB"."SMALL_VC2">='2')
          INDEX (analyzed) UNIQUE TEST_USER SUB_PK (unique scan)  Cost (1,1,) IO_Cost (1,,) (Columns 1) 
		Access ("SUB"."ID1"=:B1)
      INDEX (analyzed) UNIQUE TEST_USER CHI_PK (range scan)  Cost (1,1,) IO_Cost (1,,) (Columns 1) 
		Access ("CHI"."ID1"="SYS_ALIAS_2"."ID1") 
		Filter ("CHI"."ID1">=100 AND "CHI"."ID1"<=200)

#
