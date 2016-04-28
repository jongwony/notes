rem
rem	Script:		col_order.sql
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
rem	Create a table with two columns that we will index.
rem		The clustered column has tight clusters of data.
rem		The scattered column has evenly scattered data.
rem
rem	The table has a high pctfree to reduce the volume redo needed
rem	to make the table large.
rem

start setenv

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
pctfree 90
pctused 10
as
select
	trunc((rownum-1)/ 100)	clustered,
	mod(rownum - 1, 100)	scattered,
	lpad(rownum,10)		small_vc
from
	all_objects
where
	rownum <= 10000
;


spool col_order


create index t1_i1_good on t1(clustered, scattered);
create index t1_i2_bad  on t1(scattered, clustered);

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
	blocks,
	num_rows
from
	user_tables 
where 
	table_name = 'T1'
;

select
	index_name, blevel, leaf_blocks, clustering_factor
from
	user_indexes
where	
	table_name = 'T1'
;

set autotrace traceonly explain

select
	/*+ index(t1 t1_i1_good) */
	count(small_vc)
from
	t1
where
	scattered = 50
and	clustered between 1 and 5
;

select
	/*+ index(t1 t1_i2_bad) */
	count(small_vc)
from
	t1
where
	scattered =50
and	clustered between 1 and 5
;

set autotrace off

spool off
