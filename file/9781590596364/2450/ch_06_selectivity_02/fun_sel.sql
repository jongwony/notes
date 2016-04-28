rem
rem	Script:		fun_sel.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Some effects of 
rem		function(col) = constant
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

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;



create table t1 
nologging		-- adjust as necessary
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
	rownum				id,
	dbms_random.string('l',4)	small_vc,
	rpad('x',50)			padding
from
	generator	v1,
	generator	v2
where
	rownum <= 100000
;


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

create or replace function my_upper(i_v in varchar2)
return varchar2
as
begin
	return upper(i_v);
end;
/

create or replace function my_upper2(i_v in varchar2)
return varchar2
as
begin
	return upper(i_v);
end;
/


spool fun_sel


set autotrace traceonly explain
rem	alter session set events '10053 trace name context forever';
rem	alter session set events '10132 trace name context forever';


prompt 	mod(id,2) = 0

select 
	* 
from
	t1
where
	mod(id,2) = 0
;


prompt 	mod(id,1000) = 0

select 
	* 
from
	t1
where
	mod(id,1000) = 0
;


prompt 	NOT mod(id,1000) = 0

select 
	* 
from
	t1
where
	mod(id,1000) != 0
;


prompt 	mod(id,1000) > 10 

select 
	* 
from
	t1
where
	mod(id,1000) > 10
;


prompt 	mod(id,1000) = -1 

select 
	* 
from
	t1
where
	mod(id,1000) = -1
;


prompt 	mod(id,1000) between 10 and 20

select 
	* 
from
	t1
where
	mod(id,1000) between 10 and 20
;


prompt 	mod(id,1000) in (1,3,5)

select 
	* 
from
	t1
where
	mod(id,1000) in (1,3,5)
;



prompt 	upper(small_vc) = 'AAAA'

select 
	* 
from
	t1
where
	upper(small_vc) = 'AAAA'
;


prompt 	not upper(small_vc) = 'AAAA'

select 
	* 
from
	t1
where
	upper(small_vc) != 'AAAA'
;


prompt 	upper(small_vc) = 'ZZZZ'

select 
	* 
from
	t1
where
	upper(small_vc) = 'ZZZZ'
;



prompt 	upper(small_vc) > 'AAAA'

select 
	* 
from
	t1
where
	upper(small_vc) > 'AAAA'
;


prompt 	not upper(small_vc) > 'AAAA'

select 
	* 
from
	t1
where
	not upper(small_vc) > 'AAAA'
;

prompt 	upper(small_vc) between'AAAA' and 'ZZZZ'

select 
	* 
from
	t1
where
	upper(small_vc) between 'AAAA' and 'ZZZZ'
;


prompt 	not upper(small_vc) between'AAAA' and 'ZZZZ'

select 
	* 
from
	t1
where
	not upper(small_vc) between 'AAAA' and 'ZZZZ'
;


prompt 	PL/SQL functions: my_upper(small_vc) = 'MTKF'

select 
	* 
from
	t1
where
	my_upper(small_vc) = 'MTKF'
;


prompt 	Deterministic pl/sql functions: my_upper2(small_vc) = 'MTKF'

select 
	* 
from
	t1
where
	my_upper2(small_vc) = 'MTKF'
;


prompt 	PL/SQL functions: my_upper(small_vc) > 'MTKF'

select 
	* 
from
	t1
where
	my_upper(small_vc) > 'MTKF'
;


prompt 	PL/SQL functions: my_upper(small_vc) between 'MTKF' and 'MTKG'

select 
	* 
from
	t1
where
	my_upper(small_vc) between 'MTKF' and 'MTKG'
;


set autotrace off

spool off
