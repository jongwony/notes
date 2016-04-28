rem
rem	Script:		hash_stream_b.sql
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
rem		workarea_size_policy = manual
rem
rem	We use a set of values for the system statistics
rem	that get close to emulating the traditional costing
rem
rem	Test for a range of values for hash_area_size
rem
rem	The oddity of initrans 3 was to make sure that
rem	the tables are the same sizes in 8i and 9i.
rem
rem	The report at the end of the script uses analytic 
rem	functions to produce changes between rows. This 
rem	will not work with standard edition.  If you are
rem	running standard edition, you will need to extract
rem	the in-line view that reports the base figures and
rem	run just that.
rem
rem	Notes -
rem		If you change the MBRC - the cost of the hash
rem		component does not change (the driving tablescan
rem		costs do change, of course).
rem
rem		If you change the ratio of mreadtim to sreadtim,
rem		then the cost of the hash component of the hash
rem		join does change - so some part of the hash
rem		activity is demed to be using multiblock reads.
rem
rem		If you change the CPUspeed, the cost of the hash
rem		component changes in a rational fashion.
rem
rem		The jump discontinuities in the cost of the hash
rem		component probably relate to a change in the estimated 
rem		value to be used for the _hash_multiblock_io_count.
rem
rem		There may be another jump discontinuity in the cost
rem		where the number of partitions for the hash table 
rem		changes.
rem
rem	NOTE ESPECIALLY
rem		The numbers behave reasonably well for one-pass
rem		and in-memory hash joins. But they go badly wrong
rem		for multipass.  I think the ppasses value gets
rem		lost somewhere, so the "One ptn Resc" is not multiplied
rem		up appropriatately.
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

alter session set workarea_size_policy = manual;

spool hash_stream_b

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
rem	The constant in the hash_cost column is something I had to
rem	discover after running the script once, and checking the
rem	autotrace output for the cost of the two tablescans after
rem	getting to the steady state value for total_cost
rem

define	m_scan_cost = 512

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


