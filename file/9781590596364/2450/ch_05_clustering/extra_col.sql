rem
rem	Script:		extra_col.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	Create a table of 'product movements', which includes the
rem	obvious index on movement_date. There are 500 movements
rem	per day, with a random selection from 60 product codes.
rem
rem	The table has a high pctfree to reduce the volume redo needed
rem	to make the table large.
rem
rem	Given the code for a very common query, we then change the 
rem	index to include the product_id and quantity.
rem

start setenv

execute dbms_random.seed(0)

alter session set "_optimizer_skip_scan_enabled"=false;

drop table t1;

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

create table t1
as
select
	sysdate + trunc((rownum-1) / 500)	movement_date,
	trunc(dbms_random.value(1,60.999))	product_id,
	trunc(dbms_random.value(1,10.000))	qty,
	lpad(rownum,10)				small_vc,
	rpad('x',100)				padding
from
	all_objects
where
	rownum <= 10000
;


create index t1_i1 on t1(movement_date);
begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool extra_col

select
	blocks,
	num_rows
from
	user_tables 
where 
	table_name = 'T1';

select
	index_name, blevel, leaf_blocks, clustering_factor
from
	user_indexes
where	
	table_name = 'T1'
;

set autotrace traceonly explain

select
	sum(qty)
from
	t1
where
	movement_date = trunc(sysdate) + 7
and	product_id = 44
;


select
	product_id, max(small_vc)
from
	t1
where
	movement_date = trunc(sysdate) + 7
group by
	product_id
;

set autotrace off

drop index t1_i1;
create index t1_i1 on t1(movement_date, product_id);
begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

select
	index_name, blevel, leaf_blocks, clustering_factor
from
	user_indexes
where	
	table_name = 'T1'
;

set autotrace traceonly explain


select
	sum(qty)
from
	t1
where
	movement_date = trunc(sysdate) + 7
and	product_id = 44
;


select
	product_id, max(small_vc)
from
	t1
where
	movement_date = trunc(sysdate) + 7
group by
	product_id
;

set autotrace off


spool off
