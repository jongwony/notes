rem
rem	Script:		bitmap_cost_06.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4 with 8K blocksize
rem		 9.2.0.6 with 8K blocksize
rem
rem	Not relevant to
rem		 8.1.7.4 with 8K blocksize
rem

start setenv
set timing on

drop table dim_table;
drop table fact_table;

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


create table fact_table 
nologging
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
select
	/*+ ordered use_nl(v2) */
	rownum			id,
	mod(rownum-1,10000)	dim_id,
	rpad('x',200)		padding
from
	generator	v1,
	generator	v2
where
	rownum <= 1000000
;


create table dim_table
as
select
	rownum - 1					id,
	'Dimension_' || lpad(rownum - 1,6,'0')		dim_name,
	'Parent_' || lpad(mod(rownum -1,100),3,'0')	par_name
from
	all_Objects
where
	rownum <= 10000
;

alter table dim_table 
add constraint dim_pk primary key(id)
;

create bitmap index fct_dim_name on fact_table(dim.dim_name)
from
	dim_table	dim,
	fact_table	fct
where
	dim.id = fct.dim_id
;

create bitmap index fct_dim_par on fact_table(dim.par_name)
from
	dim_table	dim,
	fact_table	fct
where
	dim.id = fct.dim_id
;

begin
	dbms_stats.gather_table_stats(
		user,
		'dim_table',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
.
/


begin
	dbms_stats.gather_table_stats(
		user,
		'fact_table',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
.
/

spool bitmap_cost_06

select	
	table_name,
	blocks,
	num_rows
from
	user_tables
where
	table_name in ('DIM_TABLE','FACT_TABLE')
;

column table_name format a10
column column_name format a12
break on table_name skip 1

select 
	table_name,
	column_name,
	num_nulls, 
	num_distinct, 
	density,
	low_value, 
	high_value
from
	user_tab_columns
where
	table_name in ('DIM_TABLE','FACT_TABLE')
order by
	table_name, column_name
;

column name format a12

select 
	index_name 		name,
	blevel,
	leaf_blocks,
	distinct_keys			keys,
	num_rows,
	clustering_factor		clu_fac, 
	avg_leaf_blocks_per_key		leaf_per_key, 
	avg_data_blocks_per_key		data_per_key
from
	user_indexes
where
	table_name in ('DIM_TABLE','FACT_TABLE')
order by 
	table_name, index_name
;

set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';


select
	count(fct.id)
from
	dim_table	dim,
	fact_table	fct
where
	dim.dim_name = 'Dimension_000001'
and	fct.dim_id = dim.id
;


select
	count(fct.id)
from
	dim_table	dim,
	fact_table	fct
where
	dim.par_name = 'Parent_001'
and	fct.dim_id = dim.id
;


prompt
prompt	Now with the indexes disabled
prompt

select	/*+ no_index(fct) */
	count(fct.id)
from
	dim_table	dim,
	fact_table	fct
where
	dim.dim_name = 'Dimension_000001'
and	fct.dim_id = dim.id
;


select	/*+ no_index(fct) */
	count(fct.id)
from
	dim_table	dim,
	fact_table	fct
where
	dim.par_name = 'Parent_001'
and	fct.dim_id = dim.id
;



prompt
prompt	Now with the indexes enabled, but with
prompt	a larger db_file_multiblock_read_count
prompt

alter session set db_file_multiblock_read_count = 20;

select
	count(fct.id)
from
	dim_table	dim,
	fact_table	fct
where
	dim.dim_name = 'Dimension_000001'
and	fct.dim_id = dim.id
;


select
	count(fct.id)
from
	dim_table	dim,
	fact_table	fct
where
	dim.par_name = 'Parent_001'
and	fct.dim_id = dim.id
;


rem	alter session set events '10053 trace name context off';
set autotrace off

spool off
