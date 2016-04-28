rem
rem	Script:		fake_hist.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	If you want to fake a histogram, don't forget
rem	to make the rest of the statistics consistent
rem	with the histogram.
rem
rem	In particular, the num_rows in the table, and
rem	the density for the column
rem
rem	We create a very skewed table with 10 rows,
rem	then generate a genuine histogram on it. Then
rem	observe what happens when we start playing 
rem	around with a few other figures.
rem

start setenv

execute dbms_random.seed(0)

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



create table t1 (
	id	 	not null,
	currency_id	not null,
	small_vc
)
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
	rownum			id,
	1			currency_id,
	lpad(rownum,10,'0')	small_vc
from
	generator	v1,
	generator	v2
where
	rownum <= 300000
;

update t1 set currency_id =  2 where currency_id = 1 and rownum <= 25000;
update t1 set currency_id =  3 where currency_id = 1 and rownum <=  5000;
update t1 set currency_id =  4 where currency_id = 1 and rownum <=  4000;
update t1 set currency_id =  5 where currency_id = 1 and rownum <=  3000;
update t1 set currency_id =  6 where currency_id = 1 and rownum <=  2000;
update t1 set currency_id =  7 where currency_id = 1 and rownum <=  2000;
update t1 set currency_id =  8 where currency_id = 1 and rownum <=  1000;
update t1 set currency_id =  9 where currency_id = 1 and rownum <=  1000;
update t1 set currency_id = 10 where currency_id = 1 and rownum <=  1000;

commit;


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

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 75'
	);
end;
/


spool fake_hist

select
	num_rows
from
	user_tables
where
	table_name = 'T1'
;


select 
	column_name, num_nulls, density
from	user_tab_columns
where	table_name = 'T1'
order by
	table_name, column_id
;

select
	endpoint_value,
	endpoint_number
from
	user_tab_histograms
where
	table_name = 'T1'
and	column_name = 'CURRENCY_ID'
order by
	endpoint_value
;


set autotrace traceonly explain


prompt	Baseline: 
prompt		num_rows		300,000 rows
prompt		Max endpoint_number	300,000
prompt		density			1/600,000 (0.000016667)
prompt		num_nulls		0
prompt		histogram entry		1,000
prompt	Should see CARD = 1000

select 
	*
from 
	t1 
where 
	currency_id = 10;


prompt	Use hack_stats in another session to change num_rows to 150,000
prompt	Should see CARD = 500
accept	x prompt 'Then press return'

/

prompt	Reset num_rows to 300,000 and set num_nulls to 200,000
prompt	Should see CARD = 333
accept	x prompt 'Then press return'

/

prompt	Reset num_nulls to 0 and set density to 0.01
prompt	Should see CARD = 3,000
accept	x prompt 'Then press return'

/

set autotrace off

spool off
