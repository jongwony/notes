rem
rem	Script:		free_lists.sql
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
rem	Create a table and procedure to populate it.
rem
rem	The procedure uses a sequence, and current system date.
rem	to generate 200 rows per day for 26 days.
rem
rem	The table has a high pctfree to reduce the volume redo needed
rem	to make the table large.
rem
rem	We will run copies of the procedure from five separate sessions.
rem	We use dbms_lock to synchronise the sessions so that they start
rem	simultaneously. (It would be better practice to use allocate_unique
rem	to get a lock handle, but I know there are no other users of the
rem	dbms_lock package on the system).
rem
rem	In this example, we set freelists to the number of expected 
rem	concurrent inserts to avoid contention on the table blocks,
rem	then discover the hideous impact this has on the clustering factor.
rem
rem	You may get lucky in your test, and find that all five processes
rem	acquire 'their own' separate freelists. This is not guaranteed
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
storage (freelists 5)
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
prompt	From five different sessions, execute a call to procedure 
prompt	t1_load with a different tag for each session, e.g.
prompt		execute t1_LOAD('a')
prompt
prompt	These will all suspend, waiting to acquire a share lock that
prompt	this progam is holding in exclusive mode. When all five sessions
prompt	have called the procedure, press return in this screen to allow them
prompt	to continue

accept x

commit;

accept x prompt "Press return again ONLY when the processes have all completed "

spool free_lists


rem
rem	Report how many times five processes have collided on a block
rem	The first column is the number of different processes that
rem	have insertde into a block, the second is the number of blocks
rem	with that many hits. If you are lucky, you could get the result
rem		1	745
rem	It is possible, though, that a couple of processes have collided
rem	on a free list, so 3 processes have their own separate work area
rem	in the table, and two of them share.  In this case, the figures 
rem	might look more like:
rem		1	450
rem		2	300
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
