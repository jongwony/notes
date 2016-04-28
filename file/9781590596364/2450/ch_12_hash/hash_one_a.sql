rem
rem	Script:		hash_one_a.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not tested:
rem		 8.1.7.4
rem
rem	Re-run the query from hash_one.sql
rem	but with the four different combinations
rem	of cpu costing and workarea policy.
rem
rem	We set the system statistics to emulate
rem	the multiblock read calculations of an
rem	8 block db_file_multiblock_read_count -
rem	which means setting MBRC = 6.59, and
rem	mreadtim = sreadtim + 0.001
rem
rem	To emulate the hash_area_size = 1 MB I set
rem	the pga_aggregate target to 20 MB as the
rem	maximum workarea size is supposed to be 5%
rem	of the pga_aggregate_target. The 10104 trace
rem	file showed that the join got about 800KB, but the 
rem	10053 trace file showed that Oracle considered 
rem	2MB as the limit - which is 2 x 5%. However, the
rem	5% was applied as the max area size for sorting,
rem	so perhaps the old rule that 'hash area defaults
rem	to 2 x sort area' still has some effect.
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



spool hash_one_a


alter session set workarea_size_policy = manual;

-- alter session set hash_area_size = 1048576;
alter session set hash_area_size = 1572864;
-- alter session set hash_area_size = 2097152;


rem	set autotrace traceonly explain

alter session set events '10053 trace name context forever';
rem	alter session set events '10104 trace name context forever';

prompt
prompt	No CPU costing, manual workarea policy
prompt

select
	/*+ ordered full(bu) full(pb) */
	/* ordered full(bu) full(pb) use_hash(pb) */
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
;



-- alter system set pga_aggregate_target = 20971520 scope = memory;
alter system set pga_aggregate_target = 31457280 scope = memory;
-- alter system set pga_aggregate_target = 41843040 scope = memory;

alter session set workarea_size_policy = auto;

prompt
prompt	No CPU costing, automatic workarea policy
prompt

select
	/*+ ordered full(bu) full(pb) */
	/* ordered full(bu) full(pb) use_hash(pb) */
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
;



begin
	dbms_stats.set_system_stats('MBRC',6.59);
	dbms_stats.set_system_stats('MREADTIM',10.001);
	dbms_stats.set_system_stats('SREADTIM',10.000);
	dbms_stats.set_system_stats('CPUSPEED',1000);
end;
/

alter system flush shared_pool;

begin

	begin		execute immediate 'alter session set "_optimizer_cost_model"=cpu';
	exception	when others then null;
	end;

end;
/


prompt
prompt	CPU costing, automatic workarea policy
prompt

select
	/*+ ordered full(bu) full(pb) */
	/* ordered full(bu) full(pb) use_hash(pb) */
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
;



alter session set workarea_size_policy = manual;

prompt
prompt	CPU costing, manual workarea policy
prompt

select
	/*+ ordered full(bu) full(pb) */
	/* ordered full(bu) full(pb) use_hash(pb) */
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
;


set autotrace off

spool off

alter session set events '10053 trace name context off';
alter session set events '10104 trace name context off';


