rem
rem	Script:		star_join.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Demostration of the STAR JOIN (not star transformation)
rem
rem	Three small tables, and a fact table with a concatenated index
rem	The three dimensions go through a cartesian join, in this case
rem	a merge join and the result is used to drive into the fact table 
rem	using the concatenated PK index.
rem
rem	In fact, in 9.2.0.4, an examination of the 10053 trace file gave
rem	no indication that a star join had been noticed, the apparent
rem	star join just happened to be the first join order examined. 
rem	When the STAR hint was included the 10053 trace had lines:
rem
rem		STAR PLANS
rem		***********************
rem		Join order[1]: DIM1 [D1] DIM2 [D2] DIM3 [D3] FACT_TAB [ F] 
rem
rem	and only examined 6 join orders, all of which ended with table FACT_TAB
rem	(whereas the unhinted example walked through all 24 possible orders)
rem
rem	With the hint, there was no section headed:
rem		GENERAL PLANS
rem
rem	Note - you can include the fact() hint if there is any chance
rem	of Oracle choosing the wrong table as the fact table in a star
rem

start setenv

drop table dim1;
drop table dim2;
drop table dim3;

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


create table fact_tab (
	id1		number not null,
	id2		number not null,
	id3		number not null,
	small_vc	varchar2(10),
	padding		varchar2(100),
	constraint f_pk primary key (id1, id2, id3)
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


spool star_join

rem	alter session set events '10053 trace name context forever, level 2';

set autotrace traceonly explain

prompt	Unhinted

select 
	d1.p1, d2.p2, d3.p3,
	f.small_vc
from
	dim1		d1,
	dim2		d2,
	dim3		d3,
	fact_tab	f	
where
	d1.v1 = 'abc'
and	d2.v2 = 'def'
and	d3.v3 = 'ghi'
and	f.id1 = d1.id
and	f.id2 = d2.id
and	f.id3 = d3.id
;

prompt	Hinted with the STAR hint

select 
	/*+ star */
	d1.p1, d2.p2, d3.p3,
	f.small_vc
from
	dim1		d1,
	dim2		d2,
	dim3		d3,
	fact_tab	f
where
	d1.v1 = 'abc'
and	d2.v2 = 'def'
and	d3.v3 = 'ghi'
and	f.id1 = d1.id
and	f.id2 = d2.id
and	f.id3 = d3.id
;

alter session set events '10053 trace name context off';
set autotrace off

spool off
