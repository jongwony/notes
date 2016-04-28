rem
rem	Script:		hash_stream_a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Re-run the query from hash_one.sql in
rem 	Oracle 8i emulation mode - viz:
rem		cpu costing disabled
rem		workarea_size_policy = manual
rem
rem	Test for a range of values for hash_area_size
rem
rem	The oddity of initrans 3 is to make sure that
rem	the tables are the same sizes in 8i and 9i.
rem
rem	The highlights of this output are:
rem
rem		At a point where the hash_area_size roughly
rem		matches the size of the build input, i.e.
rem		where you should get an optimal, in-memory
rem		hash join, the cost goes up dramatically.
rem
rem		After going to an optimal join, the cost
rem		falls as the memory is further increased -
rem		but after you get to optimal you have
rem		eliminated all extra I/O, so the cost should
rem		no longer drop
rem

start setenv

set pagesize 100
set linesize 1024
set trimspool on

execute dbms_random.seed(0)

drop table build_tab;
drop table probe_tab;


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


create table probe_tab
initrans 3
nologging
as
select
	10000 + rownum				id,
	trunc(dbms_random.value(0,5000))	n1,	
	rpad(rownum,20)				probe_vc,
	rpad('x',1000)				probe_padding
from
	all_objects
where
	rownum <= 10000
;

alter table probe_tab add constraint pb_pk primary key(id);
		
create table build_tab
initrans 3
nologging
as
select
	rownum						id,
	10001 + trunc(dbms_random.value(0,5000))	id_probe,
	rpad(rownum,20)					build_vc,
	rpad('x',1000)					build_padding
from
	all_objects
where
	rownum <= 10000
;

alter table build_tab add constraint bu_pk    
	primary key(id);

alter table build_tab add constraint bu_fk_pb 
	foreign key (id_probe) references probe_tab;

create index bu_fk_pb on build_tab(id_probe);


begin
	dbms_stats.gather_table_stats(
		user,
		'build_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'probe_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/



delete from plan_table;
commit;

alter session set workarea_size_policy = manual;

spool hash_stream_a

begin
	for r in 8..512 loop

		execute immediate
		'alter session set hash_area_size = ' || (r * 8192);

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || ''' for ' ||
		'
		select
			/*+ ordered full(bu) full(pb) use_hash(pb) */
			bu.build_vc,
			bu.build_padding,
			pb.probe_vc,
			pb.probe_padding
		from
			build_tab	bu,
			probe_tab	pb
		where
			bu.id between 1 and 2000
		and	pb.id = bu.id_probe
		';

	end loop;
end;
.
/

rem
rem	Scan cost identified by checking the 10053 trace file
rem	for the sum of the costs of scanning the two tables
rem	(I ran a short loop the first time to get this).
rem

define m_scan_cost=510

select
	id, 
	hash_blocks, 
	hash_kb,
	total_cost,
	hash_cost,
	hash_cost - lag(hash_cost,1) over(order by id)	delta
from
	(
	select
		to_number(substr(statement_id,1,3))		id,
		1 * to_number(substr(statement_id,1,3))		hash_blocks,
		8 * to_number(substr(statement_id,1,3))		hash_KB,
		cost						total_cost,
		cost - &m_scan_cost				hash_cost
	from
		plan_table
	where
		id = 0
	order by
		statement_id
	)
order by id
;

delete from plan_table;
commit;

spool off


