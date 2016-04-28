rem
rem	Script:		hash_stream_d.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not tested
rem		 8.1.7.4
rem
rem	Re-run the query from hash_one.sql with
rem		cpu costing enabled
rem		workarea_size_policy = automatic
rem
rem	The minimum for pga_aggregate_target is 10M, which
rem	equates (on the 5% rule) to 512K, so we can't get
rem	down to the levels of the other tests.
rem
rem	There is an oddity in the 10053 trace files that the 
rem	hash_area seems to have a legal __reported__ maximum 
rem	of 10% of pga_aggregate_target rather than the 5% that
rem	is documented (and used for the sort_area_size).
rem	So I have assumed that 10% is actually the legal figure,
rem	
rem	The increment in hash_stream_b on hash_area_size was 8K
rem	so to hit the same step here, we increment by 80K
rem	We match the minimum 10MB here against 1MB in the
rem	hash_area_size test.
rem
rem	The oddity of initrans 3 was to make sure that
rem	the tables are the same sizes in 8i and 9i.
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


begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10.000);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/


delete from plan_table;
commit;

alter session set workarea_size_policy = auto;

spool hash_stream_d

begin
	for r in 0..512 loop

		execute immediate
		'alter system set pga_aggregate_target = ' || 
			(10485760 + r * 81920) ||
			' scope = memory';

		execute immediate
		'explain plan set statement_id = ''' ||
		to_char(r,'fm000') || ''' for ' ||
		'
		select
			--+ ordered full(bu) full(pb) use_hash(pb)
			bu.build_vc,
			bu.build_padding,
			pb.probe_vc,
			pb.probe_padding
		from
			test_user.build_tab	bu,
			test_user.probe_tab	pb
		where
			bu.id between 1 and 2000
		and	pb.id = bu.id_probe
		';

	end loop;
end;
.
/

define m_scan_cost = 510

select
	id, 
	pga_blocks, 
	hash_kb,
	total_cost,
	hash_cost,
	hash_cost - lag(hash_cost,1) over(order by id)	delta
from
	(
	select
		to_number(substr(statement_id,1,3))					id,
		(10485760 + 81920 * to_number(substr(statement_id,1,3))) /  8192	pga_blocks,
		(10485760 + 81920 * to_number(substr(statement_id,1,3))) / 10240	hash_kb,
		cost									total_cost,
		cost - &m_scan_cost							hash_cost
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


