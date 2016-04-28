rem
rem	Script:		scalar_sub_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		July 2005
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Quick way to find the size of the hash table.
rem	It's much easier with scalar subqueries than
rem	it was with filter subqueries.
rem
rem	In 10g, the size of the hash table is MEMORY based,
rem	not count-based. It is affected by the internal 
rem	size of the inputs and outputs, and there is a hidden
rem	parameter _query_execution_cache_max_size that controls
rem	the limit of the available memory
rem
rem	For varchar functions, the size of the output (the
rem	function return value) is 4,000 bytes, and the 
rem	default hash table size was only 16 - the cache size
rem	seemed to be 64KB - and this parameter had exactly
rem	the right default value.
rem
rem	Experimenting with _query_execution_cache_max_size
rem	and setting a large value for the number of test
rem	rows, it seems the largest number of entries you
rem	are alowed in the hash table is 16,384
rem
rem	You could increase the hash table size by putting
rem	an explicit substr() around the return. This would
rem	appear to be a valid optimization method to use in 
rem	some special cases.
rem

start setenv

define target=&m_row_count
rem	define target=16384

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

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;


rem
rem	Since I know the hash table is 1024 (9i/10g)
rem	I have allowed only a small spare capacity
rem	(Actually it had to be bigger than I thought
rem	to avoid hash collisions)
rem

create table t1 
nologging		-- adjust as necessary
pctfree 10		-- adjust as necessary
pctused 90		-- adjust as necessary
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
	rownum			n1,
	lpad(rownum,16,'0')	v16,
	lpad(rownum,32,'0')	v32
from
	generator	v1,
	generator	v2
where
	rownum <= &target
;

insert /*+ append */ into t1
select * from t1;

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


create or replace package pack1 as

	g_ct	number(10) := 0;

	function f_n(i in number)   return number;
	function f_v(i in varchar2) return varchar2;

end;
.
/


create or replace package body pack1 as

function f_n(i in number)   return number
is
begin
	pack1.g_ct := pack1.g_ct + 1;
	return i;
end
;


function f_v(i in varchar2) return varchar2
is
begin
	pack1.g_ct := pack1.g_ct + 1;
	return i;
end
;

end;
.
/

spool scalar_sub_03

prompt
prompt	Start with the function returning a number
prompt	The hash table size varies with the size of the input type.
prompt

execute pack1.g_ct := 0;

select
	count(distinct x)
from	(
	select	/*+ no_merge */
		(select pack1.f_n(n1) from dual) x
	from
		t1
	)
;

execute dbms_output.put_line('Hash table size: ' || ( 2 * &target - pack1.g_ct))


execute pack1.g_ct := 0;

select
	count(distinct x)
from	(
	select	/*+ no_merge */
		(select pack1.f_n(v16) from dual) x
	from
		t1
	)
;

execute dbms_output.put_line('Hash table size: ' || ( 2 * &target - pack1.g_ct))


execute pack1.g_ct := 0;

select
	count(distinct x)
from	(
	select	/*+ no_merge */
		(select pack1.f_n(v32) from dual) x
	from
		t1
	)
;

execute dbms_output.put_line('Hash table size: ' || ( 2 * &target - pack1.g_ct))

prompt
prompt	Now we use the function returning a string
prompt	The hash table size is suddenly very small
prompt	NB the return is 4000 bytes, the hash table size is 16
prompt	So perhaps the hash table is actually 64KB.
prompt

execute pack1.g_ct := 0;

select
	count(distinct x)
from	(
	select	/*+ no_merge */
		(select pack1.f_v(v16) from dual) x
	from
		t1
	)
;

execute dbms_output.put_line('Hash table size: ' || ( 2 * &target - pack1.g_ct))


execute pack1.g_ct := 0;

select
	count(distinct x)
from	(
	select	/*+ no_merge */
		(select pack1.f_v(v32) from dual) x
	from
		t1
	)
;

execute dbms_output.put_line('Hash table size: ' || ( 2 * &target - pack1.g_ct))


execute pack1.g_ct := 0;

select
	count(distinct x)
from	(
	select	/*+ no_merge */
		(select substr(pack1.f_v(v32),1,80) from dual) x
	from
		t1
	)
;

execute dbms_output.put_line('Hash table size: ' || ( 2 * &target - pack1.g_ct))


spool off
