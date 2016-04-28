rem
rem	Script:		template.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Original Concept from Metalink  5th April 2005
rem	Performance forum as follows: 9.2.0.5
rem
rem	In this case, we can change the execution plan
rem	by creating and analyzing a bitmap index on 
rem	grandparent(small_vc_gp) - even though the plan
rem	doesn't use it !!
rem
rem	The change in the 10g plan is very small - index scan
rem	instead of tablescan on the grandparent table.
rem
rem	The change in 8i and 9i is huge.
rem

start setenv

set timing off

define m_pad=1600

drop table child;
drop table parent;
drop table grandparent;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

--	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
--	exception	when others then null;
--	end;

--	begin		execute immediate 'execute dbms_stats.delete_system_stats';
--	exception	when others then null;
--	end;

	begin
		dbms_stats.set_system_stats('MBRC',8);
		dbms_stats.set_system_stats('MREADTIM',20);
		dbms_stats.set_system_stats('SREADTIM',10);
		dbms_stats.set_system_stats('CPUSPEED',500);
	exception
		when others then null;
	end;

	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

--	begin		execute immediate 'alter session set workarea_size_policy = auto';
--	exception	when others then null;
--	end;

end;
/

alter session set sort_area_size=262144;
alter session set hash_area_size=524288;


/*
	IDs will be 1 to 1000
*/

create table grandparent 
as
select 
	rownum			id,
	trunc((rownum-1)/5)	small_num_gp,
	rpad(rownum,10)		small_vc_gp,
	rpad(rownum,&m_pad)	padding_gp
from all_objects 
where rownum <= 1000
;

/*
	Each GP has two (scattered) children here
	Parent IDs are 1 to 2,000
*/

create table parent 
as
select 
	1+mod(rownum,1000)	id_gp,
	rownum			id,
	trunc((rownum-1)/5)	small_num_p,
	rpad(rownum,10)		small_vc_p,
	rpad(rownum,&m_pad)	padding_p
from all_objects 
where rownum <= 2000
;

/*
	Simple trick to get 5 (clustered) children per parent
	Child IDs are 1 to 10,000
*/

create table child 
as
select 
	id_gp,
	id			id_p,
	rownum			id,
	trunc((rownum-1)/5)	small_num_c,
	rpad(rownum,10)		small_vc_c,
	rpad(rownum,&m_pad)	padding_c
from 
	parent	p,
	(
		select /*+ no_merge */ rownum 
		from parent p 
		where rownum <= 5
	)	d
;


create unique index gp_pk on grandparent(id);
create unique index p_pk on parent(id_gp, id) compress 1;
create unique index c_pk on child(id_gp, id_p, id) compress 2;

alter table grandparent add constraint gp_pk primary key (id);
alter table parent add constraint p_pk primary key (id_gp,id);
alter table child add constraint c_pk primary key (id_gp,id_p,id);

alter table parent add constraint p_fk_gp foreign key (id_gp) references grandparent;
alter table child add constraint c_fk_p foreign key (id_gp, id_p) references parent;

create bitmap index gp_bi on grandparent(small_vc_gp);


begin
	dbms_stats.gather_table_stats(
		user,
		'grandparent',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

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


spool delete_anomaly

set autotrace traceonly explain;

delete 
	from grandparent g 
where	not exists (
		select 0 
		from 
			parent	p,
			child	c
		where
			p.small_vc_p = 'xx'
		and	p.id_gp = g.id
		and	c.id_gp = p.id_gp
		and	c.id_p = p.id
	) 
and	not exists (
		select 0 
		from 
			parent	p,
			child	c
		where
			p.small_vc_p = 'yy'
		and	p.id_gp = g.id
		and	c.id_gp = p.id_gp
		and	c.id_p = p.id
	) 
and 	(
	   exists (
		select 0 
		from 
			parent	p
		where
			p.small_vc_p = 'xx'
		and	p.id_gp = g.id
		) 
	or exists (
		select 0 
		from 
			parent	p
		where
			p.small_vc_p = 'yy'
		and	p.id_gp = g.id
		)
	)
; 

set autotrace off
rollback;

spool off

set doc off
doc

Execution plan 1: 
Note the total cost is much less than the sum of all costs.

Execution Plan
----------------------------------------------------------
   0      DELETE STATEMENT Optimizer=CHOOSE (Cost=3 Card=1 Bytes=3)
   1    0   DELETE OF 'GRANDPARENT'
   2    1     FILTER
   3    2       INDEX (FULL SCAN) OF 'GP_PK' (UNIQUE) (Cost=3 Card=1 Bytes=3)
   4    3         NESTED LOOPS (Cost=5 Card=1 Bytes=22)
   5    4           TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=16)
   6    5             INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)
   7    4           INDEX (RANGE SCAN) OF 'C_PK' (UNIQUE) (Cost=1 Card=1 Bytes=6)
   8    3         NESTED LOOPS (Cost=5 Card=1 Bytes=22)
   9    8           TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=16)
  10    9             INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)
  11    8           INDEX (RANGE SCAN) OF 'C_PK' (UNIQUE) (Cost=1 Card=1 Bytes=6)
  12    2       TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=13)
  13   12         INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)
  14    2       TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=13)
  15   14         INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)


After creating and analyzing a bitmap index on grandparent(small_vc_gp)

Execution Plan
----------------------------------------------------------
   0      DELETE STATEMENT Optimizer=CHOOSE (Cost=50 Card=1 Bytes=13)
   1    0   DELETE OF 'GRANDPARENT'
   2    1     FILTER
   3    2       TABLE ACCESS (FULL) OF 'GRANDPARENT' (Cost=40 Card=1 Bytes=13)
   4    2       NESTED LOOPS (Cost=5 Card=1 Bytes=22)
   5    4         TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=16)
   6    5           INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)
   7    4         INDEX (RANGE SCAN) OF 'C_PK' (UNIQUE) (Cost=1 Card=1 Bytes=6)
   8    2       NESTED LOOPS (Cost=5 Card=1 Bytes=22)
   9    8         TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=16)
  10    9           INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)
  11    8         INDEX (RANGE SCAN) OF 'C_PK' (UNIQUE) (Cost=1 Card=1 Bytes=6)
  12    2       TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=13)
  13   12         INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)
  14    2       TABLE ACCESS (BY INDEX ROWID) OF 'PARENT' (Cost=4 Card=1 Bytes=13)
  15   14         INDEX (RANGE SCAN) OF 'P_PK' (UNIQUE) (Cost=2 Card=2)


It doesn't use the index - but it changes the plan.

#

