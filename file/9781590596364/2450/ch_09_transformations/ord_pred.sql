rem
rem	Script:		ord_pred.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.6
rem		 8.1.7.4
rem	
rem	Notes
rem	Only really relevant for 8.1
rem
rem	This is an add on to the push_subq.sql script
rem	that demonstrates the effect of the hint
rem	ordered_predicates (which goes in the same
rem	place as all other hints - and not after the 
rem	"WHERE" as suggested by several books, including
rem	most of the Oracle manuals).
rem
rem	In particular we want to show:
rem	a) ordered_predicates does not make
rem	   the subquery operate before the join
rem
rem	b) ordered_predicates WILL affect the
rem	   timing of the execution of the subquery
rem	   IF the subquery has been pushed so that
rem	   it is simply 'one of several predicates
rem	   on the table'.
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

spool ord_pred

rem
rem	The FULL hint is to make sure that
rem	Oracle has two predicates that have
rem	to be tested against the table blocks
rem	(rather than one that can be tested in
rem	the index and one against the table).
rem
rem	We have no PUSH_SUBQ, so the parent/child
rem	join is executed before the subquery. This
rem	means the simple predicate has to be tested 
rem	against the parent first - i.e. before the
rem	join - the ordered_predicates is irrelevant.
rem

set autotrace traceonly

select
	/*+ full(par) ordered_predicates */
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	chi.id1 = par.id1		
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
and	par.id1 between 100 and 200
;

set autotrace off

rem
rem	With the subquery pushed, Oracle now
rem	has two predicates to apply to parent
rem	before doing the join - so does them
rem	in the order of the WHERE clause. In
rem	this case, subquery first. This can 
rem	be seen most easily by checking the
rem	logical I/O count when you reverse
rem	the order of the predicates.
rem
rem	LIOs in this order: ca. 9,100
rem

set autotrace traceonly

select
	/*+ full(par) ordered_predicates push_subq */
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	chi.id1 = par.id1		
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
and	par.id1 between 100 and 200
;

set autotrace off


rem
rem	Reverse the order of the predicates.
rem
rem	LIOs in this order: ca. 1,300
rem

set autotrace traceonly

select
	/*+ full(par) ordered_predicates push_subq */
	par.small_vc1,
	chi.small_vc1
from
	parent	par,
	child	chi
where
	chi.id1 = par.id1		
and	par.id1 between 100 and 200
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

set autotrace off


spool off
