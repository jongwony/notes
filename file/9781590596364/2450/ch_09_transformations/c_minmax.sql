rem
rem	Script:		c_minmax.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Demo 8.1 min/max optimisation
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem

start setenv

drop table min_max;

create table min_max
nologging
as
select 
	trunc((rownum-1)/10)	id_par,
	rownum			id_ch,
	rpad('X',100)		padding
from
	all_objects
where rownum <= 5000
;

create index mm_pk on min_max(id_par, id_ch);

alter table min_max
add constraint mm_pk
primary key (id_par, id_ch)
.

analyze table min_max compute statistics;

spool c_minmax

set autotrace traceonly explain

prompt
prompt	Driving subquery
prompt

select 
	/*+ no_merge */
	* 
from 
	min_max mm1
where
	mm1.id_par in (
		select	mm2.id_par 
		from	min_max mm2 
		where	id_ch = 40
);	


set autotrace off

spool off

