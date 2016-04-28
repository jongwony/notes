rem
rem	Script:		hist_intro.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Introduction to histograms
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	It takes about 60 seconds at 2 GHz
rem
rem	Demonstrate what a 'height balanced histogram'
rem	really is. It's just a histogram - which means
rem	the AREA of each rectangle is the same.
rem
rem	For B buckets in the histogram, and R rows in the
rem	original table, the area of each rectangle is just
rem		R / B
rem
rem	The width of each rectangle is the range of values
rem	in that rectangle, and the height of the rectangle 
rem	is the average number of rows that would be selected
rem	by the predicate:
rem		column = {constant}
rem	for a value in that range.
rem

start setenv
set timing off

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

drop table kilo_row;
create table kilo_row as
select
	rownum 	id
from	all_objects 
where	rownum <= 1000
;

*/

create table t1 
as
with kilo_row as (
	select /*+ materialize */
		rownum 
	from all_objects
	where rownum <= 1000
)
select 
	trunc(7000 * dbms_random.normal)	normal
from
	kilo_row	k1,
	kilo_row	k2
where
	rownum <= 1000000
;

spool hist_intro

prompt
prompt	First we query the data directly
prompt

select 
	tenth						tenth, 
	min(normal)					low_val, 
	max(normal)					high_val,
	max(normal) - min(normal)			width,
	round(100000 / (max(normal) - min(normal)),2) 	height
from (
	select 
		normal,
		ntile(10) over (order by normal) tenth 
	from t1
)
group by tenth
order by tenth
;

prompt
prompt	Now generate a histogram with 10 buckets
prompt	and look at the results
prompt

alter session set sql_trace true;

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for columns normal size 10'
	);
end;
/


alter session set sql_trace false;

select
	rownum					tenth,
	prev					low_val,
	curr					high_val,
	curr - prev				width,
	round(100000 / (curr - prev) , 2)	height
from
	(
	select
		endpoint_value			curr,
		lag(endpoint_value,1) over (
			order by endpoint_number
		) 				prev
	from
		user_tab_histograms
	where
		table_name = 'T1'
	and	column_name = 'NORMAL'
	)
where
	prev is not null
order by
	curr
;


spool off


set doc off
doc

	The following is the actual SQL used by Oracle to generate
	generate a computed histogram for the NORMAL column. Note
	how the critical section in the middle matches the SQL I used
	to generate my graph (9i and 10g only, not 8i).

	There is some post-processing of the final set of
	numbers to create the full set of histogram figures
	for the data dictionary. In particular, there is a
	calculation that produces an adjusted value for column
	user_tab_columns.density.

select 
	min(minbkt),
	maxbkt,
	substrb(dump(min(val),16,0,32),1,120) minval,
	substrb(dump(max(val),16,0,32),1,120) maxval,
	sum(rep) sumrep, 
	sum(repsq) sumrepsq, 
	max(rep) maxrep, 
	count(*) bktndv, 
	sum(case when rep=1 then 1 else 0 end) unqrep 
from
	(
		select 	
			val,
			min(bkt) minbkt, 
			max(bkt) maxbkt, 
			count(val) rep, 
			count(val)*count(val) repsq 
		from (
			select  
				/*+ 
					cursor_sharing_exact 
					use_weak_name_resl 	-- 10g hint
					dynamic_sampling(0) 
					no_monitoring 
				*/ 
				"NORMAL" val, 
				ntile(10) over (order by "NORMAL") bkt  
			from "TEST_USER"."T1" t  
			where "NORMAL" is not null
		     ) 
		group by val
	) 
group by maxbkt 
order by maxbkt
;

#
