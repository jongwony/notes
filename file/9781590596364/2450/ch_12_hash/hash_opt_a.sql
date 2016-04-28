rem
rem	Script:		hash_opt_a.sql
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
rem	Re-run the first query from hash_opt
rem	but with the four different combinations
rem	of cpu costing and workarea policy.
rem
rem	We set the system statistics to emulate
rem	the multiblock read calculations of an
rem	8 block db_file_multiblock_read_count -
rem	which means setting MBRC = 6.59, and
rem	mreadtim = sreadtim + 0.001
rem
rem	We set the pga_aggregate_target to 20MB,
rem	which means 5% of it gets close to matching
rem	the 1MB of the manual test - but this didn't
rem	really work. The 10104 trace file shows that
rem	got about 800K, the 10053 trace file shows
rem	that Oracle considered 2MB as the limit.
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
	rpad('x',500)				probe_padding
from
	all_objects
where
	rownum <= 5000
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
	rpad('x',500)					build_padding
from
	all_objects
where
	rownum <= 5000
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



spool hash_opt_a

alter session set workarea_size_policy = manual;
alter session set hash_area_size = 1048576;

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';
rem	alter session set events '10104 trace name context forever';

prompt
prompt	No CPU costing, manual workarea policy
prompt

select
	bu.build_vc,
	pb.probe_vc,
	pb.probe_padding
from
	build_tab	bu,
	probe_tab	pb
where
	bu.id between 1 and 500
and	pb.id = bu.id_probe
;


alter system set pga_aggregate_target = 20971520 scope = memory;
alter session set workarea_size_policy = auto;

prompt
prompt	No CPU costing, automatic workarea policy
prompt

select
	bu.build_vc,
	pb.probe_vc,
	pb.probe_padding
from
	build_tab	bu,
	probe_tab	pb
where
	bu.id between 1 and 500
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
	bu.build_vc,
	pb.probe_vc,
	pb.probe_padding
from
	build_tab	bu,
	probe_tab	pb
where
	bu.id between 1 and 500
and	pb.id = bu.id_probe
;


alter session set workarea_size_policy = manual;

prompt
prompt	CPU costing, manual workarea policy
prompt

select
	bu.build_vc,
	pb.probe_vc,
	pb.probe_padding
from
	build_tab	bu,
	probe_tab	pb
where
	bu.id between 1 and 500
and	pb.id = bu.id_probe
;

set autotrace off

spool off

alter session set events '10053 trace name context off';
alter session set events '10104 trace name context off';

set doc off
doc

Content of the 10053 trace for the hash join.

No CPU, manual
--------------
HA Join
  Outer table: 
    resc: 42  cdn: 500  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB
    resc: 60  cdn: 5000  rcz: 527  deg:  1  resp: 60
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 4   Deg: 1
      hash_area:  128 (max=128)  buildfrag:  129             probefrag:   329 ppasses:    2
  Hash join   Resc: 106   Resp: 106

Final - All Rows Plan:
  JOIN ORDER: 1
  CST: 106  CDN: 500  RSC: 106  RSP: 106  BYTES: 278500
  IO-RSC: 106  IO-RSP: 106  CPU-RSC: 0  CPU-RSP: 0



No CPU, Auto
------------
HA Join
  Outer table: 
    resc: 42  cdn: 500  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB
    resc: 60  cdn: 5000  rcz: 527  deg:  1  resp: 60
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 4   Deg: 1
      hash_area:  60 (max=256)  buildfrag:  3                probefrag:   329 ppasses:    1
  Hash join   Resc: 106   Resp: 106

Final - All Rows Plan:
  JOIN ORDER: 1
  CST: 106  CDN: 500  RSC: 106  RSP: 106  BYTES: 278500
  IO-RSC: 106  IO-RSP: 106  CPU-RSC: 0  CPU-RSP: 0



CPU, Auto
---------
HA Join
  Outer table: 
    resc: 42  cdn: 500  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB
    resc: 60  cdn: 5000  rcz: 527  deg:  1  resp: 60
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 1   Deg: 1
      hash_area:  60 (max=256)  buildfrag:  3                probefrag:   329 ppasses:    1
  Hash join   Resc: 103   Resp: 103

Final - All Rows Plan:
  JOIN ORDER: 2
  CST: 104  CDN: 500  RSC: 103  RSP: 103  BYTES: 278500
  IO-RSC: 102  IO-RSP: 102  CPU-RSC: 14860894  CPU-RSP: 14860894



CPU, Manual
-----------
HA Join
  Outer table: 
    resc: 42  cdn: 500  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB
    resc: 60  cdn: 5000  rcz: 527  deg:  1  resp: 60
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 1   Deg: 1
      hash_area:  128 (max=128)  buildfrag:  3                probefrag:   329 ppasses:    1
  Hash join   Resc: 103   Resp: 103

Final - All Rows Plan:
  JOIN ORDER: 2
  CST: 104  CDN: 500  RSC: 103  RSP: 103  BYTES: 278500
  IO-RSC: 102  IO-RSP: 102  CPU-RSC: 14860894  CPU-RSP: 14860894


#
