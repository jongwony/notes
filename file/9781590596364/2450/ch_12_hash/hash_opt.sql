rem
rem	Script:		hash_opt.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Simple example of optimal hash join
rem	The concept is joining a large number of
rem	order-line tables to a product description
rem	table - driving off the order lines.
rem
rem	For clarity, we give the tables the names:
rem		build_tab	which builds the hash cluster
rem		probe_tab	which probes the hash cluster
rem
rem	We have a fixed 1MB hash area size
rem
rem	The two tables are the same size, and there are
rem	some indexed access paths into both tables.
rem
rem	There are five queries 
rem
rem	Query 1
rem	We make the target data from the build_tab smaller
rem	than the target data in the probe_table, and select
rem	a small enough amount of data that the data set is
rem	acquired by index.
rem
rem	Query 2:
rem	The same query hinted to show that a nested loop
rem	was possible. The cost of the nested loop is much
rem	higher than the cost of the hash join
rem
rem	Query 3:
rem	The same query hinted to show that a sort/merge
rem	was possible. Note that by including a use_merge()
rem	hint for both tables, we allow Oracle to select the
rem	join order, but force a sort/merge whichever order
rem	is chosen. Note also that the join order chosen 
rem	is the one that allows Oracle to avoid a sort on
rem	the larger data set. (The second data set is ALWAYS
rem	sorted, even if it has been acquired in the right 
rem	order - if the first data set has been acquired in 
rem	order it is not sorted.)
rem
rem	Query 4:
rem	We make the target data from the build_tab smaller
rem	than the target data in the probe_table, and select
rem	a large enough amount of data that the data set is
rem	acquired by full tablescan
rem
rem	Query 5:
rem	We don't change the number of rows we want from the
rem	build_tab, but we request much longer rows from the
rem	build_tab, and shorter rows from probe_tab, with the
rem	effect that Oracle reverses the choice of table for
rem	creating the in-memory hash cluster.
rem
rem	The oddity of initrans 3 is to make sure that
rem	the tables are the same sizes in 8i and 9i.
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

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;

*/

create table probe_tab
initrans 3
nologging
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
select
	/*+ ordered use_nl(v2) */
	10000 + rownum				id,
	trunc(dbms_random.value(0,5000))	n1,	
	rpad(rownum,20)				probe_vc,
	rpad('x',500)				probe_padding
from
	generator	v1,
	generator	v2
where
	rownum <= 5000
;

alter table probe_tab add constraint pb_pk primary key(id);
		
create table build_tab
initrans 3
nologging
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
select
	/*+ ordered use_nl(v2) */
	rownum						id,
	10001 + trunc(dbms_random.value(0,5000))	id_probe,
	rpad(rownum,20)					build_vc,
	rpad('x',500)					build_padding
from
	generator	v1,
	generator	v2
where
	rownum <= 5000
;

alter table build_tab add constraint bu_pk    
	primary key(id);

alter table build_tab add constraint bu_fk_pb 
	foreign key (id_probe) references probe_tab;

create index bu_fk_pb on build_tab(id_probe);

--	analyze table build_tab compute statistics;
--	analyze table probe_tab compute statistics;

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


spool hash_opt

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


prompt
prompt	The query in the book
prompt

set autotrace traceonly explain

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


prompt
prompt	The same query, hinted to use a nested loop
prompt

select
	/*+ ordered use_nl(pb) index(pb)) */
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


prompt
prompt	The same query, hinted to use a sort/merge
prompt

select
	/*+ use_merge(bu) use_merge(pb) */
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


prompt
prompt	Get more data from the build table
prompt

select
	bu.build_vc,
	pb.probe_vc,
	pb.probe_padding
from
	build_tab	bu,
	probe_tab	pb
where
	bu.id between 1 and 750
and	pb.id = bu.id_probe
;


prompt
prompt	Get larger rows from the build_tab, and
prompt	the table changes roles to become the
prompt	second (probe) table.
prompt

select
	bu.build_vc,
	bu.build_padding,		-- long rows from build_tab
	pb.probe_vc
from
	build_tab	bu,
	probe_tab	pb
where
	bu.id between 1 and 750
and	pb.id = bu.id_probe
;

set autotrace off
spool off


prompt
prompt	The query in the book - generating trace files
prompt

set termout off

alter session set events '10104 trace name context forever';
alter session set events '10053 trace name context forever';
alter session set events '10132 trace name context forever';

select
	/*+ traced */
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

alter session set events '10132 trace name context off';
alter session set events '10053 trace name context off';
alter session set events '10104 trace name context off';

set termout on


set doc off
doc

Extracts from the 10053 and 10104 trace files:
==============================================

Oracle 8i
---------
HA Join
  Outer table: 
    resc: 42  cdn: 501  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB
    resc: 59  cdn: 5000  rcz: 527  deg:  1  resp: 59
  Hash join one ptn:  6   Deg:  1
      hash_area:  128   buildfrag:  129   probefrag:   329               ppasses:    2
  Hash join   Resc: 107   Resp: 107
Join result: cost: 107  cdn: 501  rcz: 557


Original memory: 1048576
Calculated length of build rows: 50
Memory after hash table overhead: 754657
Calculated overhead for partitions and row/slot managers: 1408
Number of partitions: 8
Number of slots: 15
Cluster (slot) size: 49152
Block size: 8192
Minimum number of bytes per block: 8160
Multiblock IO: 6
Bit vector memory allocation: 52428
Per partition bit vector length: 4096
Maximum possible row length: 557
Estimated Cardinality: 300
Estimated Row Length (includes overhead): 50
Estimated Input Size: 15030



Oracle 9i
---------
HA Join
  Outer table: 
    resc: 42  cdn: 500  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB
    resc: 60  cdn: 5000  rcz: 527  deg:  1  resp: 60
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 4   Deg: 1
      hash_area:  128 (max=128)  buildfrag:  129                probefrag:   329 ppasses:    2
  Hash join   Resc: 106   Resp: 106
Join result: cost: 106  cdn: 500  rcz: 557


Original memory: 1048576
Memory after all overhead: 1012977
Memory for slots: 860160
Calculated overhead for partitions and row/slot managers: 152817
Hash-join fanout: 8
Number of partitions: 8
Number of slots: 15
Multiblock IO: 7
Block size(KB): 8
Cluster (slot) size(KB): 56
Minimum number of bytes per block: 8160
Bit vector memory allocation(KB): 32
Per partition bit vector length(KB): 4
Maximum possible row length: 557
Estimated build size (KB): 24
Estimated Row Length (includes overhead): 50



Oracle 10g
----------
HA Join (swap)
  Outer table: 
    resc: 42  cdn: 500  rcz: 30  deg: 1  resp: 42
  Inner table: PROBE_TAB  Alias: PB
    resc: 60  cdn: 5000  rcz: 527  deg:  1  resp: 60
    using join:8 distribution:2 #groups:1
  Hash join one ptn Resc: 5   Deg: 1
    hash_area: 128 (max=128)  buildfrag: 129  probefrag: 329 ppasses: 2
  Hash join   Resc: 107   Resp: 107
Join result: cost: 107  cdn: 500  rcz: 557


Join Type: INNER join
Original hash-area size: 995029
Memory for slot table: 835584
Calculated overhead for partitions and row/slot managers: 159445
Hash-join fanout: 8
Number of partitions: 8
Number of slots: 17
Multiblock IO: 6
Block size(KB): 8
Cluster (slot) size(KB): 48
Minimum number of bytes per block: 8160
Bit vector memory allocation(KB): 32
Per partition bit vector length(KB): 4
Maximum possible row length: 557
Estimated build size (KB): 22
Estimated Build Row Length (includes overhead): 46


#
