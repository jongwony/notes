rem
rem	Script:		treble_hash.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4 
rem		 9.2.0.6 
rem	Not relevant
rem		 8.1.7.4 
rem
rem	Disk space required:	ca. 50MB
rem
rem	Using MANUAL workareas (the only option with Oracle 8) the 
rem	memory increase (UGA and PGA) seems to be 3 x hash_area_size/2
rem	For example, with hash_area_size = 10M, the UGA and PGA went
rem	up by APPROXIMATELY 15MB each.  When the hash_area_size was 
rem	4MB, the increases were ABOUT 6MB.
rem
rem	With 	workarea_size_policy = automatic, 
rem	and	pga_aggregate_target = 200M (so that 5% of the maximum 
rem	was 10MB) the memory usage was a much more conservative 3.5MB
rem
rem	This script builds the tables needed
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

create table t1 
as
select
	rownum		id,
	to_char(rownum)	small_vc,
	rpad('x',100)	padding
from
	all_objects
where
	rownum <= 70
;

alter table t1 
	add constraint t1_pk primary key(id)
;

create table t2
as
select
	rownum		id,
	to_char(rownum)	small_vc,
	rpad('x',100)	padding
from
	all_objects
where
	rownum <= 70
;

alter table t2
	add constraint t2_pk primary key(id)
;

create table t3
as
select
	rownum		id,
	to_char(rownum)	small_vc,
	rpad('x',100)	padding
from
	all_objects
where
	rownum <= 70
;

alter table t3
	add constraint t3_pk primary key(id)
;

create table t4
nologging
as
select
	t1.id			id1,
	t2.id			id2,
	t3.id			id3,
	rpad(rownum,10)		small_vc,
	rpad('x',100)		padding
from
	t1, t2, t3
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


spool off
exit
