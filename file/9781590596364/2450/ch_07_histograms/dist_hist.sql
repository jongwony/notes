rem
rem	Script:		dist_hist.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Whichever copy of the T1 table is considered the 
rem	'remote' table, does not get its histogram used.
rem
rem	In a simple remote query on one table, cardinality = 22
rem	In a simple join, cardinality on both copies is 22
rem	In a distributed join (one local, one remote) the local
rem	cardinality is 22, the remote cardinality is 41
rem
rem	NOTE - this example uses the ANALYZE command to generate
rem	a default histogram because this happens to show the
rem	huge variation in row counts. If you switch to dbms_stats
rem	to gather table stats, you will find that the values are
rem		local 45 remote 41 instead of
rem		local 22 remote 41
rem
rem	You will need to do something like the following to create
rem	the necessary loopback database link:
rem
rem	create public database link d817@loopback using 'd817';
rem	create public database link d920@loopback using 'd920';
rem	create public database link d10g@loopback using 'd10g';
rem
rem	Then choose the link you want to use.
rem

define m_target=d817@loopback
define m_target=d10g@loopback
define m_target=d920@loopback

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
	skew,	skew2,	padding
)
as
select r1, r2, rpad('x',200) 
from
(
	select /*+ no_merge */
		rownum r1
	from all_objects 
	where rownum <= 80
)	v1,	
(
	select /*+ no_merge */
		rownum r2
	from all_objects 
	where rownum <= 80
)	v2
where r2 <= r1
order by r2,r1
;

alter table t1 modify skew not null;
alter table t1 modify skew2 not null;

create index t1_skew on t1(skew);

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 75'
	);
end;
.


analyze table t1 compute statistics 
	for table 
	for all indexes 
	for all columns size 75
;

spool dist_hist

set autotrace traceonly explain

select
	home.skew2,
	away.skew2,
	home.padding,
	away.padding
from
	t1		home,
	t1@&m_target	away
where
	home.skew = 5
and	away.skew = 5
and	home.skew2 = away.skew2
;

select	/*+ driving_site(away) */
	home.skew2,
	away.skew2,
	home.padding,
	away.padding
from
	t1		home,
	t1@&m_target	away
where
	home.skew = 5
and	away.skew = 5
and	home.skew2 = away.skew2
;

select
	home.skew2,
	away.skew2,
	home.padding,
	away.padding
from
	t1		home,
	t1		away
where
	home.skew = 5
and	away.skew = 5
and	home.skew2 = away.skew2
;

set autotrace off

spool off
