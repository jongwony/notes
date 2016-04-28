rem
rem	Script:		hash_one.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Scaling hash_opt.sql up so that neither
rem	table can hash in memory, and end up 
rem	doing a onepass workarea execution.
rem
rem	Build_tab hashed in memory at 500 rows, with
rem	only 30 bytes involved per row. We push this
rem	up to 2,000 rows and ca. 1,000 bytes per row.
rem
rem	This gives us 2MB of data, and 1MB of memory,
rem	which is bad enough to go onepass, but not so
rem	bad that we go to multipass.
rem
rem	The oddity of initrans 3 is to make sure that
rem	the tables are the same sizes in 8i and 9i.
rem
rem	You will notice that the cost for 8i and 10g
rem	is 1081 (+/-2), but it is 1127 for 9i. This
rem	is because the CBO is using a calculated EIGHT
rem	blocks for the hash_multiblock_io_count in
rem	9i (despite the run-time reporting 9), whereas
rem	8i and 10g are using NINE for their arithmetic.
rem
rem	Note - the cost can be affected by setting the
rem	_hash_multiblock_io_count (which became hidden
rem	in 9i).  
rem
rem	The default value is 0, which is taken to cost 
rem	as if it were 8, but seems to use a cluster size 
rem	of 9 - possibly this is a run-time vs. optimizer
rem	time thing.
rem

start setenv

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


/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;



create table probe_tab
initrans 3
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
	10000 + rownum				id,
	trunc(dbms_random.value(0,5000))	n1,	
	rpad(rownum,20)				probe_vc,
	rpad('x',1000)				probe_padding
from
	generator	v1,
	generator	v2
where
	rownum <= 10000
;

alter table probe_tab add constraint pb_pk primary key(id);
		
create table build_tab
initrans 3
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
	rownum						id,
	10001 + trunc(dbms_random.value(0,5000))	id_probe,
	rpad(rownum,20)					build_vc,
	rpad('x',1000)					build_padding
from
	generator	v1,
	generator	v2
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
	begin		execute immediate 'alter session set workarea_size_policy = manual';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set hash_area_size = 1048576';
	exception	when others then null;
	end;

end;
/


spool hash_one

select
	table_name, blocks, avg_row_len
from	user_tables
where	table_name in ('BUILD_TAB','PROBE_TAB')
;


select
	table_name, column_name, avg_col_len
from
	user_tab_columns
where	
	table_name in ('BUILD_TAB','PROBE_TAB')
order by
	table_name, column_name
;


set autotrace traceonly explain

rem
rem	The query in the book
rem

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
/

set autotrace off
spool off


prompt	About to generate trace file

set termout off

alter session set events '10053 trace name context forever';
alter session set events '10104 trace name context forever';

select
	/*+ ordered full(bu) full(pb) use_hash(pb) traced */
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

alter session set events '10104 trace name context off';
alter session set events '10053 trace name context off';

set termout on


set doc off
doc

Extracts from the 10053 and 10104 trace files:
==============================================

Oracle 8i
---------
HA Join
  Outer table: 
    resc: 254  cdn: 2001  rcz: 1030  deg: 1  resp: 254
  Inner table: PROBE_TAB
    resc: 254  cdn: 10000  rcz: 1027  deg:  1  resp: 254
  Hash join one ptn:  571   Deg:  1
      hash_area:  128   buildfrag:  255   probefrag:   1269               ppasses:    2
  Hash join   Resc: 1079   Resp: 1079
Join result: cost: 1079  cdn: 2001  rcz: 2057


Original memory: 1048576
Calculated length of build rows: 1050
Memory after hash table overhead: 981196
Calculated overhead for partitions and row/slot managers: 1256
Number of partitions: 8
Number of slots: 13
Cluster (slot) size: 73728
Block size: 8192
Minimum number of bytes per block: 8160
Multiblock IO: 9
Bit vector memory allocation: 52428
Per partition bit vector length: 4096
Maximum possible row length: 1081
Estimated Cardinality: 1962
Estimated Row Length (includes overhead): 1050
Estimated Input Size: 2061030


Oracle 9i
---------
HA Join
  Outer table: 
    resc: 255  cdn: 2000  rcz: 1030  deg: 1  resp: 255
  Inner table: PROBE_TAB
    resc: 255  cdn: 10000  rcz: 1027  deg:  1  resp: 255
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 617   Deg: 1
      hash_area:  128 (max=128)  buildfrag:  255                probefrag:   1269 ppasses:    2
  Hash join   Resc: 1127   Resp: 1127
Join result: cost: 1127  cdn: 2000  rcz: 2057


Original memory: 1048576
Memory after all overhead: 999238
Memory for slots: 958464
Calculated overhead for partitions and row/slot managers: 40774
Hash-join fanout: 8
Number of partitions: 8
Number of slots: 13
Multiblock IO: 9
Block size(KB): 8
Cluster (slot) size(KB): 72
Minimum number of bytes per block: 8160
Bit vector memory allocation(KB): 32
Per partition bit vector length(KB): 4
Maximum possible row length: 1081
Estimated build size (KB): 2050
Estimated Row Length (includes overhead): 1050


Oracle 10g
----------
HA Join
  Outer table: 
    resc: 255  cdn: 2000  rcz: 1030  deg: 1  resp: 255
  Inner table: PROBE_TAB  Alias: PB
    resc: 255  cdn: 10000  rcz: 1027  deg:  1  resp: 255
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 571   Deg: 1
    hash_area: 128 (max=128)  buildfrag: 255  probefrag: 1269 ppasses: 2
  Hash join   Resc: 1081   Resp: 1081
Join result: cost: 1081  cdn: 2000  rcz: 2057



Join Type: INNER join
Original hash-area size: 999306
Memory for slot table: 958464
Calculated overhead for partitions and row/slot managers: 40842
Hash-join fanout: 8
Number of partitions: 8
Number of slots: 13
Multiblock IO: 9
Block size(KB): 8
Cluster (slot) size(KB): 72
Minimum number of bytes per block: 8160
Bit vector memory allocation(KB): 32
Per partition bit vector length(KB): 4
Maximum possible row length: 1057
Estimated build size (KB): 2046
Estimated Build Row Length (includes overhead): 1048



#

