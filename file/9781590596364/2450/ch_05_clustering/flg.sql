rem
rem	Script:		flg.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Notes:
rem	Extend freelists.sql to demonstrate the effects
rem	of multiple free lists groups. This will require
rem	quite a lot of concurrent processes for the best
rem	effect, as the setting for freelists and freelist
rem	groups should be relatively co-prime.  (i.e. they
rem	don't need to be prime numbers, but they should have
rem	no common divisor).
rem
rem	Create the table with freelists 2 and freelist groups 3
rem	Then run copies of the procedure from 12 separate sessions.
rem

start setenv

alter session set "_optimizer_skip_scan_enabled"=false;

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

create table t1(
	date_ord	date		constraint t1_dto_nn	not null,
	seq_ord		number(6)	constraint t1_sqo_nn	not null,
	small_vc	varchar2(10)
)
pctfree 90
pctused 10
storage (freelists 2 freelist groups 3)
;

drop sequence t1_seq;
create sequence t1_seq;

create or replace procedure t1_load(i_tag varchar2) as

m_date	date;	

begin
	dbms_output.put_line( 
		dbms_lock.request(
			1,dbms_lock.s_mode, release_on_commit => true
		)
	);
	commit;
	for i in 0..25 loop
		m_date :=  trunc(sysdate) + i;

		for j in 1..200 loop
			insert into t1 values(
				m_date,
				t1_seq.nextval,
				i_tag || j
			);
			commit;
			dbms_lock.sleep(0.01);
		end loop;
	end loop;
end;
/


begin
	dbms_output.put_line( 
		dbms_lock.request(
			1,dbms_lock.x_mode, 
			release_on_commit=>true
		)
	);
end;
/

prompt
prompt	From twelve different sessions, execute a call to procedure 
prompt	t1_load with a different tag for each session, e.g.
prompt		execute t1_LOAD('a')
prompt
prompt	These will all suspend, waiting to acquire a share lock that
prompt	this progam is holding in exclusive mode. When all twelve sessions
prompt	have called the procedure, press return in this screen to allow
prompt	them to continue

accept x

commit;

accept x prompt "Press return again ONLY when the processes have all completed "

spool flg


rem
rem	Report how many times N processes have collided on a block
rem	The first column is the number of different processes that
rem	have insertde into a block, the second is the number of blocks
rem	with that many hits. If you are lucky, you could get the result
rem	something like:
rem		2	1795
rem	You might want to repeat the test - connecting a couple of new
rem	sessions then disconnecting a couple of old ones - until you 
rem	can get a less balanced result, for example
rem		1        152
rem		2       1198
rem		3        449
rem

select	ct, count(*)
from
	(
	select block, count(*) ct
	from
		(
		select 
			distinct dbms_rowid.rowid_block_number(rowid) block,
			substr(small_vc,1,1)
		from t1
		)
	group by block
	)
group by ct
;


create index t1_i1 on t1(date_ord, seq_ord);
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

select
	blocks,
	num_rows
from
	user_tables 
where 
	table_name = 'T1';

select
	index_name, blevel, leaf_blocks, clustering_factor
from
	user_indexes
where	
	table_name = 'T1'
;

set autotrace traceonly explain

select
	count(small_vc)
from
	t1
where
	date_ord = trunc(sysdate) + 7
;

set autotrace off

spool off
