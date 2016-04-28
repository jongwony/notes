rem
rem	Script:		date_oddity.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem
rem	We store date from 1st Jan 2000 to 31st Dec 2004.
rem	We choose to store this in three different forms, a correct
rem	date type, a numeric type, and a character type
rem
rem	What does this do to selectivity on a query
rem		"date_col between 30th Dec 2002 and 5th Jan 2003"
rem
rem	Histograms help. There are about 60 months and 60 gaps, 
rem	so we create N * 60 buckets as a 'guesstimate' of a good
rem	number of buckets.  The results here use a 120 bucket.
rem
rem	The cardinality is improved significantly on the character
rem	and numeric columns.
rem
rem	(Coincidentally, setting the bucket count to 125 in 9.2.0.6 made
rem	the real date column produce a much worse result. But that was a
rem	redundant histogram anyway).
rem

start setenv

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

create table t1 (
	d1		date,
	n1		number(8),
	v1		varchar2(8)
)
;

insert into t1 
select
	d1,
	to_number(to_char(d1,'yyyymmdd')),
	to_char(d1,'yyyymmdd')
from	(
	select
		to_date('31-Dec-1999') + rownum	d1
	from all_objects
	where
		rownum <= 1827
	)
;


commit;

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 1'
	);
end;
/

spool date_oddity

prompt	Lowest and highest dates

select min(d1), max(d1) from t1;

set autotrace traceonly explain;

prompt	Proper date column

select	*
from	t1
where 	d1 between to_date('30-Dec-2002','dd-mon-yyyy') 
	   and     to_date('05-Jan-2003','dd-mon-yyyy')
;

prompt	Numeric column

select	*
from	t1
where 	n1 between 20021230 and 20030105
;


prompt	Character column

select	*
from	t1
where 	v1 between '20021230' and '20030105'
;

set autotrace off

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 120'
	);
end;
/


set autotrace traceonly explain;

prompt	Now with a histogram of 120 buckets.
prompt	Proper date column

select	*
from	t1
where 	d1 between to_date('30-Dec-2002','dd-mon-yyyy') 
	   and     to_date('05-Jan-2003','dd-mon-yyyy')
;

prompt	Numeric column

select	*
from	t1
where 	n1 between 20021230 and 20030105
;


prompt	Character column

select	*
from	t1
where 	v1 between '20021230' and '20030105'
;

set autotrace off

select
	rownum					bucket,
	prev					low_val,
	curr					high_val,
	curr - prev				width,
	round( (1827/120) / (curr - prev) , 4)	height
from
	(
	select
		endpoint_value				curr,
		lag(endpoint_value,1) over (
			order by endpoint_number
		) 					prev
	from
		user_tab_histograms
	where
		table_name = 'T1'
	and	column_name = 'N1'
	)
where
	prev is not null
order by
	curr
;

spool off
