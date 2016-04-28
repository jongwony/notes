rem
rem	Script:		unnest_cost_03.sql
rem	Author:		Jonathan Lewis
rem	Dated:		July 2004
rem	Purpose:	Investigation of FILTER and UNEST operations
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Does Oracle 10 choose a filter for a not in
rem	subquery. It should do based on costing. But 
rem	sometimes things seem to get pre-empted.
rem
rem	It was possible to rig a query where 9i and 10g
rem	had a cheaper cost for the FILTER - and they 
rem	both took hash joins. But in fact, these were
rem	anti-joins - which suggests that there is some
rem	'heuristic' decision (i.e. rule) which promotes
rem	anti-joins over simple unnesting.
rem
rem	If you disable anto-joins, using 
rem		alter session set "_always_anti_join"=off
rem	then the filter is chosen by default.
rem
rem	Interesting note - the hash_aj hint allowed 
rem	Oracle 10 to do a RIGHT ANTI join - which is
rem	what it wanted to do by default.
rem

start setenv
set timing off

define m_main_scale = 5000
define m_filter_size = 16

drop table main_tab; 
drop table filter_tab;

begin
	execute immediate 'purge recyclebin';
exception
	when others then null;
end;
/

create table main_tab (
	n number	not null, 
	v varchar2(100)
);

create table filter_tab (
	n number	not null, 
	v varchar2(100)
)
pctfree 99
pctused 1
;

begin 
	for f in 1..10 * &m_filter_size loop
		insert into filter_tab values (f,rpad('a',100));
	end loop; 
	commit; 
end;
/

create unique index filter_tab_i1 on filter_tab (n);

begin
	dbms_stats.gather_table_stats(
		user,
		'filter_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool unnest_cost_03


truncate table main_tab;
begin 
	for f1 in 1..&m_main_scale loop 
		for f2 in 1..&m_filter_size loop
			insert into main_tab values (f2,rpad('a',100));
		end loop; 
	end loop; 
	commit; 
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'main_tab',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

set autotrace traceonly explain

prompt	NO_UNNEST

select
	count(m.v) 
from
	main_tab m
where	m.n not in (
		select	/*+ no_unnest */
			n 
		from
			filter_tab f 
		where	
			f.v like 'a%'
	)
;

prompt	NL_aj

select
	count(m.v) 
from
	main_tab m
where	m.n not in (
		select	/*+ nl_aj */
			n
		from
			filter_tab f 
		where	
			f.v like 'a%'
	)
;

prompt	MERGE_aj

select
	count(m.v) 
from
	main_tab m
where	m.n not in (
		select	/*+ merge_aj */
			n 
		from
			filter_tab f 
		where	
			f.v like 'a%'
	)
;

prompt	HASH_aj

select
	count(m.v) 
from
	main_tab m
where	m.n not in (
		select	/*+ hash_aj */
			n 
		from
			filter_tab f 
		where	
			f.v like 'a%'
	)
;

prompt	No hint

select
	count(m.v) 
from
	main_tab m
where	m.n not in (
		select
			n
		from
			filter_tab f 
		where	
			f.v like 'a%'
	)
;

set autotrace off

spool off


set doc off
doc


#

