rem
rem	Script:		c_skew_freq_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Demo of histogram affecting access path 
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	The algorithm for the table means that the value of skew
rem	will behave as follows if you set m_demo_size = 250
rem		1	will appear once
rem		2	will appear twice
rem		3	will appear three times
rem			...
rem		250	will appear 250 times
rem
rem	dbms_stats will NOT be able to collect a frequency
rem	histogram on this number of distinct values. SO we
rem	use SQL to collect the right numbers, and the various
rem	get, prepare, and set stats procedures in dbms_stats
rem	to write the histogram into the data dictionary.
rem
rem	For a frequency histogram, you have to set:
rem
rem	epc:		End Point Count
rem	bkvals:		(Ordered list) Number of occurences of each value in the column
rem	m_val_array:	(Ordered list) Values that appear in the column
rem
rem	NOTE - the pl/sql reference manual suggests the array can cope with 256 values.
rem	and the array definiton in dbmsstat.sql allows for a size of 256, but the
rem	analyze command won't go above 254 buckets, and 'for columns X size 254' is the
rem	maximum accepted, so the safe option is to block this prepare_column_stats at
rem	a maximum of 254 end points.
rem
rem	The call to set_column_stats leaves the density unchanged,
rem	in our example we analyze for simple stats, so density - 1/num_distinct
rem	we have to change it to be 1/(2*num_rows)
rem
rem	We could sum the array bkvals to find the number if we wanted to.
rem	This code does it the lazy way, and counts the table (again)
rem

start setenv 

define m_demo_size=250

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


rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;



create table t1 (
	skew		not null,	
	padding
)
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	/*+ ordered use_nl(v2) */
	v1.id,
	rpad('x',400)
from
	generator	v1,
	generator	v2
where
	v1.id <= &m_demo_size
and	v2.id <= &m_demo_size
and	v2.id <= v1.id
order by 
	v2.id,v1.id
;

rem
rem	Get simple table statss
rem

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

spool c_skew_freq_02


declare

	m_statrec		dbms_stats.statrec;
	m_val_array		dbms_stats.numarray;

--	m_val_array		dbms_stats.datearray;
--	m_val_array		dbms_stats.chararray;		-- 32 byte char max
--	m_val_array		dbms_stats.rawarray;		-- 32 byte raw max
	
	m_distcnt		number;
	m_density		number;
	m_nullcnt		number;
	m_avgclen		number;

begin

	dbms_stats.get_column_stats(
		ownname		=> NULL,
		tabname		=> 'T1',
		colname		=> 'SKEW', 
		distcnt		=> m_distcnt,
		density		=> m_density,
		nullcnt		=> m_nullcnt,
		srec		=> m_statrec,
		avgclen		=> m_avgclen
	); 

--
--	Load column information into the two critical arrays
--

	select 
		skew, 
		count(*)
	bulk collect 
	into
		m_val_array, 
		m_statrec.bkvals
	from
		t1
	group by
		skew
	order by
		skew
	;

	m_statrec.epc		:= m_val_array.count;

	--
	--	Should terminate here if the count exceeds 254
	--

	dbms_stats.prepare_column_values(
		srec	=> m_statrec,
		numvals	=> m_val_array			
	);

	select
		1/ (2 * count(*))
	into
		m_density
	from
		t1;

	dbms_stats.set_column_stats(
		ownname		=> NULL,
		tabname		=> 'T1',
		colname		=> 'SKEW', 
		distcnt		=> m_distcnt,
		density		=> m_density,
		nullcnt		=> m_nullcnt,
		srec		=> m_statrec,
		avgclen		=> m_avgclen
	); 

end;
/


spool off
