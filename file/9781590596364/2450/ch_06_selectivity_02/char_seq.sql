rem
rem	Script:		char_seq.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.4
rem		10.1.0.2	-- NOTE especially
rem		 9.2.0.6
rem		 9.2.0.4	-- NOTE especially
rem		 8.1.7.4
rem
rem	Notes:
rem	The side effects of using a zero-padded character instead
rem	of a number - particuarly with sequence numbers.
rem
rem	Although most systems will probably only every execute
rem	queries like 'id_column = {string constant}' you do see
rem	cases where range-based queries on this type of column
rem	are used.
rem
rem	9.2.0.6 introduces an optimimsation trick which (I think)
rem	goes like this:  if the low value and high value on the
rem	column stats look like numbers, and the predicate values
rem	look like numbers, then calculate the selectivity as if
rem	the column really is a number
rem
rem	Because of this, there is a secondary code option (which
rem	will break the function-based index test) that prefixes
rem	the number with the letter 'A' to re-introduce the problem.
rem
rem	Fortunately, if you use meaningless sequences like this,
rem	you probably won't be doing large range scans - but what
rem	if you have (say) a convention that purchase orders should
rem	be of the form:  'POyyyymmnnnnnn' where yyyy is the year,
rem	mm is the month number, and nnnnnn is a sequence number ?
rem	How will Oracle cope with 'get me all the POs for June 2004 ?
rem	if you phrase it as:
rem		where id between 'PO200306000000' and 'PO200306999999'
rem	Of course, this is just falling back to the generic
rem	'leading edge of character strings' problem.
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
where	rownum <= 2000
;

*/

create table t1 
nologging
pctfree 0
as
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 2000
)
select
	/*+ ordered use_nl(v2) */
	trunc((rownum-1)/10000)		grp_id,
	lpad(rownum,18,'0')		id
--	'A' || lpad(rownum, 17, '0')	id
from
	generator	v1,
	generator	v2
where
	rownum <= 2000000
;

spool char_seq

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


select	
	column_name, num_distinct, density
from	user_tab_columns
where	table_name = 'T1'
;

set autotrace traceonly explain

prompt
prompt	Base data with simple statistics
prompt

select
	*
from t1
where
--	id between 'A00000000000060000'
--	   and	   'A00000000000070000'
	id between '000000000000060000'
	   and	   '000000000000070000'
;


set autotrace off

begin
	dbms_stats.gather_table_stats(
		ownname			=> user,
		tabname			=> 't1',
		cascade			=> true,
		estimate_percent	=> null, 
		method_opt		=>'for all columns size 75'
	);
end;
/

set autotrace traceonly explain

prompt
prompt	Histogram with 75 buckets created on ID column
prompt

select
	*
from t1
where
--	id between 'A00000000000060000'
--	   and	   'A00000000000070000'
	id between '000000000000060000'
	   and	   '000000000000070000'
;

set autotrace off

create index t1_i1 on t1(grp_id, to_number(id));

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

set autotrace traceonly explain

prompt
prompt	Virtual column created on to_number(ID) by
prompt	including the expression in an index. NOT
prompt	just as the single column in the index.
prompt	No histogram
prompt

select
	*
from t1
where	
	to_number(id) between 60000 and 70000
;


set autotrace off

spool off
