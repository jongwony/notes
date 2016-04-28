rem
rem	Script:		ordered.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2003
rem	Purpose:	Effects of unnesting and ORDERED hint.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	What happens if you use the ordered hint in a query
rem	that includes subqueries that can be unnested ?
rem
rem	It looks as if subquery unnesting is applied from the bottom
rem	up, and the subqueries are inserted in order of unnesting 
rem	at the top of the FROM clause - then the plan is optimised.
rem
rem	In particular
rem		t1 , t3 where exists t2, t4
rem	ends up as:
rem		t4, t2, t1, t3
rem
rem	And Oracle obeys the ordered hint !
rem
rem	An upgrade could be a disaster unless every time you
rem	use ORDERED with subqueries you've also included an
rem	UNNEST in every subquery
rem
rem
rem	The no_unnest hint resolves the problem in this case.
rem
rem	(In this example, the actual performance impact is
rem	probably irrelevant - I have simply created an example
rem	that demonstrates the issue; with real data sets, you
rem	would see a performance implication.)
rem

start setenv

drop table t4;
drop table t3;
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


create table t1 (id, n1, v1, padding)
as
select 
	rownum,
	mod(rownum,731),
	rpad(rownum,6),
	rpad('x',100)
from
	all_objects
where
	rownum <= 20000
;

alter table t1 add constraint t1_pk primary key(id);

create table t2
as 
select * from t1
where rownum <= 2000;

alter table t2 add constraint t2_pk primary key(id);
create index t2_n1 on t2(n1);

create table t3 (id, n1, v1, padding)
as
select 
	rownum,
	mod(rownum,731),
	rpad(rownum,6),
	rpad('x',100)
from
	all_objects
where
	rownum <= 20000
;

alter table t3 add constraint t3_pk primary key(id);

create table t4
as 
select * from t3
where rownum <= 2000;

alter table t4 add constraint t4_pk primary key(id);
create index t4_n1 on t4(n1);

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

begin
	dbms_stats.gather_table_stats(
		user,
		't3',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		't4',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool ordered

set autotrace traceonly explain


select 
	/*+ ordered push_subq */
	t1.v1
from 
	t1, t3
where 
	t3.n1 = t1.n1	
and	exists (
		select 
			t2.id 
		from	t2
		where	t2.n1 = 15
		and	t2.id = t1.id
	)
and	exists (
		select 
			t4.id 
		from	t4
		where	t4.n1 = 15
		and	t4.id = t3.id
	)
;


select 
	/*+ ordered push_subq */
	t1.v1
from 
	t1, t3
where 
	t3.n1 = t1.n1	
and	exists (
		select 	/*+ no_unnest */
			t2.id 
		from	t2
		where	t2.n1 = 15
		and	t2.id = t1.id
	)
and	exists (
		select 	/*+ no_unnest */
			t4.id 
		from	t4
		where	t4.n1 = 15
		and	t4.id = t3.id
	)
;


set autotrace off

spool off

