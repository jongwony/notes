rem
rem	Script:		star_trans.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	For generating a large table in 8i, comment
rem	out the "WITH ... AS" section of code in the
rem	create table statement, and re-instate the 
rem	'create table generator' code.
rem
rem	You will need about 600MB of free space (and the
rem	partitioning option) to run this test.
rem
rem	The break point for temporary table transformation can be
rem	modified by the hidden parameter _temp_tran_block_threshold
rem	which defaults to 100 blocks. However, there are further
rem	considerations in the use of temporary tables for the dimensions
rem	which have something to do with partitioning.
rem

start setenv

drop table dim_23;
drop table dim_31;
drop table dim_53;

drop table fact1;

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

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;


create table fact1 (
	id,
	mod_23,
	mod_31,
	mod_53,
	small_vc,
	padding
)
partition by range (id) (
	partition p_0500000 values less than( 500001),
	partition p_1000000 values less than(1000001),
	partition p_1500000 values less than(1500001),
	partition p_2000000 values less than(2000001)
)
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
	rownum				id,
	20 * mod(rownum - 1, 23)	mod_23,
	20 * mod(rownum - 1, 31)	mod_31,
	20 * mod(rownum - 1, 53)	mod_53,
	lpad(rownum - 1,20,'0')		small_vc,
	rpad('x',200)			padding
from
	generator	v1,
	generator	v2
where
	rownum <= 2000000
;


alter table fact1 modify mod_23   not null;
alter table fact1 modify mod_31   not null;
alter table fact1 modify mod_53   not null;
alter table fact1 modify small_vc not null;
alter table fact1 modify padding  not null;


create bitmap index fact1_23 on fact1(mod_23) local;
create bitmap index fact1_31 on fact1(mod_31) local;
create bitmap index fact1_53 on fact1(mod_53) local;


begin
	dbms_stats.gather_table_stats(
		user,
		'fact1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
.
/

rem
rem	The columns with the name rep_XX will
rem	have 20 repetitions for each value.
rem

create table dim_23
as
select
	rownum - 1		id_23,
	mod(rownum - 1,23)	rep_23,
	lpad(rownum - 1,20)	vc_23,
	rpad('x',2000)		padding_23
from
	all_objects
where
	rownum <= 23 * 20
;

alter table dim_23 add constraint dim_23_pk primary key(id_23);

begin
	dbms_stats.gather_table_stats(
		user,
		'dim_23',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

create table dim_31
as
select
	rownum - 1		id_31,
	mod(rownum - 1,31)	rep_31,
	lpad(rownum - 1,20)	vc_31,
	rpad('x',2000)		padding_31
from
	all_objects
where
	rownum <= 31 * 20
;

alter table dim_31 add constraint dim_31_pk primary key(id_31);

begin
	dbms_stats.gather_table_stats(
		user,
		'dim_31',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

create table dim_53
as
select
	rownum - 1		id_53,
	mod(rownum - 1,53)	rep_53,
	lpad(rownum - 1,20)	vc_53,
	rpad('x',2000)		padding_53
from
	all_objects
where
	rownum <= 53 * 20
;

alter table dim_53 add constraint dim_53_pk primary key(id_53);

begin
	dbms_stats.gather_table_stats(
		user,
		'dim_53',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool star_trans

set autotrace traceonly explain;

alter session set star_transformation_enabled = false;

prompt	star_transformation_enabled = false

select
--	count(*)
	dim_23.vc_23, 
	dim_31.vc_31, 
	dim_53.vc_53, 
	fact1.small_vc
from
	dim_23,
	dim_31,
	dim_53,
	fact1
where
	fact1.mod_23 = dim_23.id_23
and	dim_23.rep_23 = 10
/*				*/
and	fact1.mod_31 = dim_31.id_31
and	dim_31.rep_31 = 10
/*				*/
and	fact1.mod_53 = dim_53.id_53
and	dim_53.rep_53 = 10
;

alter session set star_transformation_enabled = true;

prompt	star_transformation_enabled = true

select
--	count(*)
	dim_23.vc_23, 
	dim_31.vc_31, 
	dim_53.vc_53, 
	fact1.small_vc
from
	dim_23,
	dim_31,
	dim_53,
	fact1
where
	fact1.mod_23 = dim_23.id_23
and	dim_23.rep_23 = 10
/*				*/
and	fact1.mod_31 = dim_31.id_31
and	dim_31.rep_31 = 10
/*				*/
and	fact1.mod_53 = dim_53.id_53
and	dim_53.rep_53 = 10
;

alter session set star_transformation_enabled = temp_disable;

prompt	star_transformation_enabled = temp_disable

select
--	count(*)
	dim_23.vc_23, 
	dim_31.vc_31, 
	dim_53.vc_53, 
	fact1.small_vc
from
	dim_23,
	dim_31,
	dim_53,
	fact1
where
	fact1.mod_23 = dim_23.id_23
and	dim_23.rep_23 = 10
/*				*/
and	fact1.mod_31 = dim_31.id_31
and	dim_31.rep_31 = 10
/*				*/
and	fact1.mod_53 = dim_53.id_53
and	dim_53.rep_53 = 10
;


set autotrace off

spool off
