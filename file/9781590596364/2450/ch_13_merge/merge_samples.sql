rem
rem	Script:		merge_samples.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem

start setenv

alter session set hash_join_enabled = false;

execute dbms_random.seed(0)

drop table t2;
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
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select	rownum			id,
	rownum			n1,
	trunc((rownum - 1)/2)	n2,
	lpad(rownum,10,'0') 	small_vc,
	rpad('x',100,'x')	padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
;

alter table t1 add constraint t1_pk primary key(id);

create table t2
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
	rownum			id,
	rownum			n1,
	trunc((rownum - 1)/2)	n2,
	lpad(rownum,10,'0') 	small_vc,
	rpad('x',100,'x')	padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
;

alter table t2 add constraint t2_pk primary key(id);

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

begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool merge_samples

set autotrace traceonly explain

prompt
prompt	1 to 1 - with equality
prompt

select
	count(distinct t1_vc ||t2_vc)
from	(
	select /*+ no_merge ordered use_merge(t2) */
		t1.small_vc	t1_vc,
		t2.small_vc	t2_vc
	from
		t1,
		t2
	where
		t2.id = t1.id
	and	t1.n1 <= 1000
	)
;


prompt
prompt	1 to many - with equality
prompt

select
	count(distinct t1_vc ||t2_vc)
from	(
	select /*+ no_merge ordered use_merge(t2) */
		t1.small_vc	t1_vc,
		t2.small_vc	t2_vc
	from
		t1,
		t2
	where
		t2.n2 = t1.id
	and	t1.n1 <= 1000
	)
;

prompt
prompt	1 to many - on a range
prompt

select
	count(distinct t1_vc ||t2_vc)
from	(
	select /*+ no_merge */
		t1.small_vc	t1_vc,
		t2.small_vc	t2_vc
	from
		t1,
		t2
	where
		t2.id between t1.id - 1 and t1.id + 1
	and	t1.n1 <= 1000
	)
;


prompt
prompt	many to many - with equality
prompt

select
	count(distinct t1_vc ||t2_vc)
from	(
	select /*+ no_merge ordered use_merge(t2) */
		t1.small_vc	t1_vc,
		t2.small_vc	t2_vc
	from
		t1,
		t2
	where
		t2.n2 = t1.n2
	and	t1.n1 <= 1000
	)
;


prompt
prompt	many to many - with a range
prompt

select
	count(distinct t1_vc ||t2_vc)
from	(
	select /*+ no_merge */
		t1.small_vc	t1_vc,
		t2.small_vc	t2_vc
	from
		t1,
		t2
	where
		t2.n2 between t1.n2 - 1 and t1.n2 + 1
	and	t1.n1 <= 1000
	)
;


prompt
prompt	One to one - without sorting the first data set:
prompt
prompt	With t1.id <= 1000, you get a no-sort access path
prompt
prompt	With t1.id <= 9000, you see a trace file with a
prompt	section for the SM join that considers an index
prompt	on the outer (and rejects it).
prompt 

rem	set autotrace off
rem	alter session set events '10053 trace name context forever';

select
	count(distinct t1_vc ||t2_vc)
from	(
	select /*+ no_merge ordered use_merge(t2) */
		t1.small_vc	t1_vc,
		t2.small_vc	t2_vc
	from
		t1,
		t2
	where
		t2.id = t1.id
	and	t1.id <= 9000
--	and	t1.id <= 1000
	)
;


set autotrace off
rem	alter session set events '10053 trace name context off';

spool off
