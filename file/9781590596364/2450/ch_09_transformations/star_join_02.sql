rem
rem	Script:		star_join_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Further notes on the STAR JOIN (not star transformation)
rem
rem	With seven dimension tables and a STAR hint, the optimizer
rem	went through all 5040 possible permutations of the seven
rem	tables (leaving the fact table as the 8th in the join order).
rem
rem	This is contrary to the normal _optimizer_search_limit policy
rem	which tries to stop the optimizer wasting time on bad join
rem	orders by skipping any join orders which result in more than
rem	(default) 5 cartesian joins.  Of course, in this case, every
rem	possible join order that was a STAR join had to have six
rem	cartesian joins; and also in contradiction of the limit of 
rem	2,000 set by _optimizer_max_permutations.
rem
rem	Without the hint, though, Oracle examined
rem		10 plans under the heading GENERAL PLANS
rem		 1 plan  under the heading STAR PLANS
rem		 4 plans under the heading ADDITIONAL PLANS
rem
rem	This tends to suggest that it did the usual short circuit based
rem	on comparing time to completion with time spent optimizing for
rem	the unhinted query. But it just keeps going with the STAR hint 
rem	until it has exhausted all possible plans.
rem

start setenv

drop table dim1;
drop table dim2;
drop table dim3;
drop table dim4;
drop table dim5;
drop table dim6;
drop table dim7;

drop table fact_tab;

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

create table dim1 (
	id		number		not null,
	v1		varchar2(10),
	p1		varchar2(10)
);

create table dim2 (
	id		number		not null,
	v2		varchar2(10),
	p2		varchar2(10)
);

create table dim3 (
	id		number		not null,
	v3		varchar2(10),
	p3		varchar2(10)
);

create table dim4 (
	id		number		not null,
	v4		varchar2(10),
	p4		varchar2(10)
);

create table dim5 (
	id		number		not null,
	v5		varchar2(10),
	p5		varchar2(10)
);

create table dim6 (
	id		number		not null,
	v6		varchar2(10),
	p6		varchar2(10)
);

create table dim7 (
	id		number		not null,
	v7		varchar2(10),
	p7		varchar2(10)
);

create table fact_tab (
	id1		number not null,
	id2		number not null,
	id3		number not null,
	id4		number not null,
	id5		number not null,
	id6		number not null,
	id7		number not null,
	small_vc	varchar2(10),
	padding		varchar2(100),
	constraint f_pk primary key (id1, id2, id3, id4, id5, id6, id7)
);


begin
	dbms_stats.gather_table_stats(
		user,
		'fact_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim3',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim4',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim5',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim6',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'dim7',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool star_join

alter session set tracefile_identifier = 'star';

alter session set events '10053 trace name context forever, level 1';

rem	set autotrace traceonly explain

prompt	Hinted with the STAR hint

select 
	/*+ star */
	d1.p1, d2.p2, d3.p3,
	d4.p4, d5.p5, d6.p6,
	d7.p7,
	f.small_vc
from
	dim1		d1,
	dim2		d2,
	dim3		d3,
	dim4		d4,
	dim5		d5,
	dim6		d6,
	dim7		d7,
	fact_tab	f	
where
	d1.v1 = 'abc'
and	d2.v2 = 'def'
and	d3.v3 = 'ghi'
and	d4.v4 = 'ghi'
and	d5.v5 = 'ghi'
and	d6.v6 = 'ghi'
and	d7.v7 = 'ghi'
and	f.id1 = d1.id
and	f.id2 = d2.id
and	f.id3 = d3.id
and	f.id4 = d4.id
and	f.id5 = d5.id
and	f.id6 = d6.id
and	f.id7 = d7.id
;

alter session set tracefile_identifier = 'none';

prompt	Unhinted

select 
	d1.p1, d2.p2, d3.p3,
	d4.p4, d5.p5, d6.p6,
	d7.p7,
	f.small_vc
from
	dim1		d1,
	dim2		d2,
	dim3		d3,
	dim4		d4,
	dim5		d5,
	dim6		d6,
	dim7		d7,
	fact_tab	f	
where
	d1.v1 = 'abc'
and	d2.v2 = 'def'
and	d3.v3 = 'ghi'
and	d4.v4 = 'ghi'
and	d5.v5 = 'ghi'
and	d6.v6 = 'ghi'
and	d7.v7 = 'ghi'
and	f.id1 = d1.id
and	f.id2 = d2.id
and	f.id3 = d3.id
and	f.id4 = d4.id
and	f.id5 = d5.id
and	f.id6 = d6.id
and	f.id7 = d7.id
;

alter session set events '10053 trace name context off';
set autotrace off

spool off
