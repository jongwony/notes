rem
rem	Script:		hash_one_bad.sql
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
rem	Run the query with 
rem		hash_area_size = 1.0M
rem	then	hash_area_size = 1.5M
rem
rem	You would not expect the cost to go up with
rem	the larger memory.
rem
rem	The oddity of initrans 3 is to make sure that
rem	the tables are the same sizes in 8i and 9i.
rem
rem	The switch to single block I/O is quite surprising
rem	in the 10104 trace. 
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



spool hash_one_bad

alter session set workarea_size_policy = manual;
alter session set hash_area_size = 1126400;

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';
rem	alter session set events '10104 trace name context forever';


--	precision boundary target for 10g
--	alter session set hash_area_size = 2179072;

--	precision boundary target for 9i
--	alter session set hash_area_size = 2059264;

--	precision boundary target for 8i
--	alter session set hash_area_size = 2195456;

prompt
prompt	Hash area size = 1100 KB
prompt

select
	/*+ ordered full(bu) full(pb) use_hash(pb) 1100 KB*/
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


prompt
prompt	Hash area size = 2200 KB
prompt

alter session set hash_area_size = 2252800;

--	precision target for 10g
--	alter session set hash_area_size = 2195456;

--	precision boundary target for 9i
--	alter session set hash_area_size = 2060288;

--	precision boundary target for 8i
--	alter session set hash_area_size = 2211840;


select
	/*+ ordered full(bu) full(pb) use_hash(pb) 2200 KB*/
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

alter session set events '10053 trace name context off';
alter session set events '10104 trace name context off';

spool off


set doc off
doc


Trace extracts at 1,100 KB (9.2)
--------------------------------
HA Join
  Outer table: 
    resc: 255  cdn: 2000  rcz: 1030  deg: 1  resp: 255
  Inner table: PROBE_TAB
    resc: 255  cdn: 10000  rcz: 1027  deg:  1  resp: 255
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 571   Deg: 1
      hash_area:  138 (max=138)  buildfrag:  255                probefrag:   1269 ppasses:    2
  Hash join   Resc: 1081   Resp: 1081
Join result: cost: 1081  cdn: 2000  rcz: 2057


Original memory: 1126400
Memory after all overhead: 1073525
Memory for slots: 1032192
Calculated overhead for partitions and row/slot managers: 41333
Hash-join fanout: 8
Number of partitions: 8
Number of slots: 14
Multiblock IO: 9
Block size(KB): 8
Cluster (slot) size(KB): 72
Minimum number of bytes per block: 8160
Bit vector memory allocation(KB): 32
Per partition bit vector length(KB): 4
Maximum possible row length: 1081
Estimated build size (KB): 2050
Estimated Row Length (includes overhead): 1050


Trace extracts at 2,200 KB (9.2)
--------------------------------
HA Join
  Outer table: 
    resc: 255  cdn: 2000  rcz: 1030  deg: 1  resp: 255
  Inner table: PROBE_TAB
    resc: 255  cdn: 10000  rcz: 1027  deg:  1  resp: 255
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 2259   Deg: 1
      hash_area:  275 (max=275)  buildfrag:  276                probefrag:   1269 ppasses:    2
  Hash join   Resc: 2769   Resp: 2769
Join result: cost: 2769  cdn: 2000  rcz: 2057


Original memory: 2252800
Memory after all overhead: 2244802
Memory for slots: 2146304
Calculated overhead for partitions and row/slot managers: 98498
Hash-join fanout: 8
Number of partitions: 8
Number of slots: 262
Multiblock IO: 1
Block size(KB): 8
Cluster (slot) size(KB): 8
Minimum number of bytes per block: 8160
Bit vector memory allocation(KB): 64
Per partition bit vector length(KB): 8
Maximum possible row length: 1081
Estimated build size (KB): 2050
Estimated Row Length (includes overhead): 1050


#

