rem
rem	Script:		hist_calc.sql
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
rem	The SQL typically run by Oracle (from 9i) when you call
rem	dbms_stats to generate a histogram on a column.  The
rem	analtyic function is used to generate the number of 
rem	buckets.
rem

start setenv
set timing off

select 
	min(minbkt),
	maxbkt,
	substrb(dump(min(val),16,0,32),1,120) minval,
	substrb(dump(max(val),16,0,32),1,120) maxval,
	sum(rep) sumrep, 
	sum(repsq) sumrepsq, 
	max(rep) maxrep, 
	count(*) bktndv 
from 
	(select 
		val,
		min(bkt) minbkt, 
		max(bkt) maxbkt, 
		count(val) rep, 
		count(val)*count(val) repsq 
		from 
			(select  /*+ 
					cursor_sharing_exact dynamic_sampling(0) 
					no_monitoring noparallel(t) noparallel_index(t) 
				*/ 
				"V10" val, 
				ntile(10) over (order by "V10") bkt  
			from 
				"TEST_USER"."T1" t  
			where "V10" is not null
			) 
		group by val
	) 
group by maxbkt 
order by maxbkt
;
