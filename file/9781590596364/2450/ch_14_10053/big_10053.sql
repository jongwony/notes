rem
rem	Script:		big_10053.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Data build for a simple 10053 trace.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	10053 trace files don't get really interesting until you 
rem	do at least a four table join.  (And really need seven to
rem	show off some of the features)
rem
rem	We have four tables here whose names tell you the expected
rem	join order. But we have fiddled around with the data sizes
rem	to avoid making Oracle's first choice the right one.
rem
rem	E.g: We have adjusted the rpad() columns and set the number
rem	of rows to make table grandparent more expensive to scan than 
rem	table parent. On the other hand, we have a condition on table 
rem	grandparent which limits the number of rows returned.
rem
rem	We set up some 'reasonable' CPU costing figures. These won't
rem	push the plan too far from a 'no cpu costing' plan.
rem

start setenv

define m_pad=1600

drop table child;
drop table parent;
drop table grandparent;
drop table greatgrandparent;

begin
	dbms_stats.set_system_stats('MBRC',8);
	dbms_stats.set_system_stats('MREADTIM',20);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',500);
end;
/


begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
end;
/

/*
	IDs will be 1 to 1000
*/

create table greatgrandparent 
nologging
as
select 
	rownum			id,
	trunc((rownum-1)/5)	small_num_ggp,
	rpad(rownum,10)		small_vc_ggp,
	rpad(rownum,&m_pad)	padding_ggp
from all_objects 
where rownum <= 1000
;

/*
	Each GGP has two (scattered) children here
	GrandParent IDs are 1 to 2,000
*/

create table grandparent as
select 
	1+mod(rownum,1000)	id_ggp,
	rownum			id,
	trunc((rownum-1)/5)	small_num_gp,
	rpad(rownum,10)		small_vc_gp,
	rpad(rownum,&m_pad)	padding_gp
from all_objects 
where rownum <= 2000
;


/*
	And again to get 5 (clustered) children per grandparent
	Parent IDs are 1 to 10,000
*/

create table parent
nologging
as
select 
	id_ggp,
	id			id_gp,
	rownum			id,
	trunc((rownum-1)/5)	small_num_p,
	rpad(rownum,10)		small_vc_p,
	rpad(rownum,&m_pad)	padding_p
from 
	grandparent	gp,
	(
		select /*+ no_merge */ rownum 
		from grandparent gp 
		where rownum <= 5
	)	d
;


/*
	And again to get 4 (clustered) children per parent
	Children IDs are 1 to 40,000
*/

create table child 
nologging
as
select 
	id_ggp,
	id_gp,
	id			id_p,
	rownum			id,
	trunc((rownum-1)/4)	small_num_c,
	rpad(rownum,10)		small_vc_c,
	rpad(rownum,&m_pad)	padding_c
from 
	parent	p,
	(
		select /*+ no_merge */ rownum 
		from parent p 
		where rownum <= 4
	)	d
;


create unique index ggp_pk on greatgrandparent(id);
create unique index gp_pk on grandparent(id_ggp,id) compress 1;
create unique index p_pk on parent(id_ggp, id_gp, id) compress 2;
create unique index c_pk on child(id_ggp, id_gp, id_p, id) compress 3;

alter table greatgrandparent add constraint ggp_pk primary key (id);
alter table grandparent add constraint gp_pk primary key (id_ggp, id);
alter table parent add constraint p_pk primary key (id_ggp, id_gp, id);
alter table child add constraint c_pk primary key (id_ggp, id_gp, id_p, id);

alter table grandparent add constraint gp_fk_ggp foreign key (id_ggp) references greatgrandparent;
alter table parent add constraint p_fk_gp foreign key (id_ggp, id_gp) references grandparent;
alter table child add constraint c_fk_p foreign key (id_ggp, id_gp, id_p) references parent;

begin
	dbms_stats.gather_table_stats(
		user,
		'greatgrandparent',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

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

spool big_10053

alter session set events '10053 trace name context forever';
alter session set events '10132 trace name context forever';

select 
	count(ggp.small_vc_ggp),
	count(gp.small_vc_gp),
	count(p.small_vc_p),
	count(c.small_vc_c)
from 
	greatgrandparent	ggp, 
	grandparent		gp, 
	parent			p,
	child			c
where	ggp.small_num_ggp between 100 and 150
/*				*/
and	gp.id_ggp = ggp.id
and	gp.small_num_gp between 110 and 130
/*				*/
and	p.id_gp = gp.id
and	p.id_ggp = gp.id_ggp
and	p.small_num_p between 110 and 130
/*				*/
and	c.id_p = p.id
and	c.id_gp = p.id_gp
and	c.id_ggp = p.id_ggp
and	c.small_num_c between 200 and 215
;

alter session set events '10053 trace name context off';
alter session set events '10132 trace name context off';

spool off
