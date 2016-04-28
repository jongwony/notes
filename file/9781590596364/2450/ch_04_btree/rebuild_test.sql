rem
rem	Script:		rebuild_test.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2003
rem	Purpose:	Demonstrate that things can go wrong on rebuilds
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	We use random inserts to build an index on a table
rem	with 400,000 rows, and then add a further 100,000
rem	rows to the table.
rem
rem	In test one, we rebuild the index to pack it before
rem	adding the new data; in test two, we simply carry on
rem	building the data.
rem
rem	Which strategy leaves the index in better shape ?
rem
rem	To make life easy, we aim for a fairly fixed size 
rem	index entry (20 bytes) and easy arithmetic. With
rem	a block size of 8K we get 400 entries per block, so
rem	one thousand blocks for 400,000 entries when packed.
rem
rem	Entry size on a non-unique index consists of:
rem		rowindex	2
rem		lock byte	1
rem		flags		1
rem		col count	1
rem		rowid length	1
rem		rowid		6
rem		column length	1	(for each column)
rem		column data	N	(for each column)
rem
rem	So we need a numeric of 7 bytes - which means ca. 14 digits
rem	to build our 20 byte row entry.
rem
rem	Results:
rem	========
rem	In this case the rebuild has had a dramatic impact
rem	on the index, pushing it out to nearly twice the 
rem	size we would expect.
rem
rem	NOTE - this does not PROVE that it is a bad idea to
rem	rebuild indexes; it merely shows that sometimes the
rem	effect of rebuilding an index can be the opposite to
rem	what you might expect.  This test happens to smash the
rem	entire rebuilt index. In more realistic scenarios, you
rem	are more likely to smash a 'popular sub-section' of an
rem	index, which makes the statistics at the global index
rem	more likely to conceal the issue.
rem
rem	In a test on 10g, my results were:
rem		Leaf blocks before rebuild: 		  1452
rem		Leaf blocks immediately after rebuild:	  1114
rem		Saving:	338 blocks, 23.28%
rem
rem		Leaf blocks after further processing: 	  2227
rem		Leaf blocks with no intermediate rebuild: 1821
rem		Penalty: 406 blocks, 22.30%
rem
rem		Leaf blocks after further processing: 	  1393
rem
rem	Clearly, if the index is 2227 blocks when it could be 1393,
rem	we are much more likely to want to rebuild it again. But
rem	maybe we should just leave it running at around 30% wastage.
rem

start setenv
set feedback off

spool rebuild_test

Prompt	================================
prompt
prompt	Test 1.
prompt	Rebuild before adding extra data
prompt
prompt	================================


drop table t1;
begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;
end;
/


create table t1(n1 number(38));
create index i1 on t1(n1);

execute dbms_random.seed(0)

begin
	for i in 1..400000 loop
		insert into t1 values(
			trunc(power(10,14) * dbms_random.value)
		);
		commit;
	end loop;
end;
.
/

analyze index i1 validate structure;

select 
	'Leaf blocks before rebuild: ' || lf_blks 	leaf_blocks
from 	index_stats;

alter index i1 rebuild pctfree 10;

analyze index i1 validate structure;

select 
	'Leaf blocks immediately after rebuild: ' || lf_blks	leaf_blocks 
from 	index_stats;


begin
	for i in 1..100000 loop
		insert into t1 values(
			trunc(power(10,14) * dbms_random.value)
		);
		commit;
	end loop;
end;
.
/

analyze index i1 validate structure;

select 
	'Leaf blocks after further processing: ' || lf_blks 	leaf_blocks
from 	index_stats;


prompt
Prompt	================================
prompt
prompt	Test 2:
prompt	Without rebuilding.
prompt
prompt	================================

drop table t1;
begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;
end;
/

create table t1(n1 number(38));
create index i1 on t1(n1);

execute dbms_random.seed(0)

begin
	for i in 1..400000 loop
		insert into t1 values(
			trunc(power(10,14) * dbms_random.value)
		);
		commit;
	end loop;
end;
.
/

begin
	for i in 1..100000 loop
		insert into t1 values(
			trunc(power(10,14) * dbms_random.value)
		);
		commit;
	end loop;
end;
.
/

analyze index i1 validate structure;
select 
	'Leaf blocks with no intermediate rebuild: ' || lf_blks leaf_blocks
from 	index_stats;


alter index i1 rebuild pctfree 10;

analyze index i1 validate structure;

select 
	'Leaf blocks at end of test: ' || lf_blks	leaf_blocks 
from 	index_stats;


spool off
