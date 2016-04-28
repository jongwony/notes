rem
rem	Script:		hack_stats.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Jun 2002
rem	Purpose:	Demo of modifying existing statistics
rem
rem	Last tested 
rem		10.0.1.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Needs some adjustment for 8.1
rem	Does not cater for partitioning
rem
rem	A quick and dirty way to change some stats on a 
rem	table, or move some stats from one table to another
rem	You can set the source and target values to reference
rem	the same thing if you want to
rem
rem	Statistics should have been collected on the object,
rem	the purpose of these scripts is to change some existing
rem	values, not generate a complete new set.
rem

start setenv

define m_source_table='t1'
define m_source_column='x'
define m_source_index='t1_btree'

define m_target_table=''
define m_target_column=''
define m_target_index=''

rem
rem	A convenient set to make the target match
rem	the source. Comment out when not needed.
rem

define m_target_table='&m_source_table'
define m_target_index='&m_source_index'
define m_target_column='&m_source_column'

declare

	m_numrows		number;
	m_numlblks		number;
	m_numdist		number;
	m_avglblk		number;
	m_avgdblk		number;
	m_clstfct		number;
	m_indlevel		number;
	m_guessq		number;

	m_numblks		number;
	m_avgrlen		number;

	srec			dbms_stats.statrec;
	m_distcnt		number;
	m_density		number;
	m_nullcnt		number;
	m_avgclen		number;

begin

/*
	--------------------------------------------------

	Index statistics

	The references to guessq will have to be deleted
	for Oracle 8i. This is the percentage guess for
	a secondary index on an IOT, and is not implemented
	until 9i. Unless the index is a secondary index,
	you will have to delete the references to guessq
	even in 9i and 10g.

	--------------------------------------------------

	dbms_stats.get_index_stats(
		ownname 	=> NULL,	
		indname		=> '&m_source_index.',
		numrows		=> m_numrows,
		numlblks	=> m_numlblks,
		numdist		=> m_numdist,
		avglblk		=> m_avglblk,
		avgdblk		=> m_avgdblk,
		clstfct		=> m_clstfct,
		indlevel	=> m_indlevel
--		indlevel	=> m_indlevel,
--		quessq		=> m_guessq
	); 

	m_indlevel := 3;
	m_numlblks := 1000;

	dbms_output.put_line('Changing statistics on index &m_source_index');
	dbms_stats.set_index_stats(
		ownname 	=> NULL,	
		indname		=> '&m_target_index.',
		numrows		=> m_numrows,
		numlblks	=> m_numlblks,
		numdist		=> m_numdist,
		avglblk		=> m_avglblk,
		avgdblk		=> m_avgdblk,
		clstfct		=> m_clstfct,
		indlevel	=> m_indlevel,
		quessq		=> m_guessq
	);

*/
/*
	--------------------------------------------------

	Table statistics

	--------------------------------------------------
*/

	dbms_stats.get_table_stats(
		ownname 	=> NULL,	
		tabname		=>'&m_source_table.',
		numrows		=> m_numrows,
		numblks		=> m_numblks,
		avgrlen		=> m_avgrlen
	);

	m_avgrlen := m_avgrlen + 25;

	dbms_output.put_line('Changing statistics on table &m_source_table');
	dbms_stats.set_table_stats(
		ownname 	=> NULL,	
		tabname		=>'&m_target_table.',
		numrows		=> m_numrows,
		numblks		=> m_numblks,
		avgrlen		=> m_avgrlen
	);


/*
	--------------------------------------------------

	Column statistics

	--------------------------------------------------

	dbms_stats.get_column_stats(
		ownname		=> NULL,
		tabname		=> '&m_source_table.',
		colname		=> '&m_source_column.', 
		distcnt		=> m_distcnt,
		density		=> m_density,
		nullcnt		=> m_nullcnt,
		srec		=> srec,
		avgclen		=> m_avgclen
	); 


	m_avgclen := m_avgclen + 30;

	dbms_output.put_line('Changing statistics on column &m_source_column');
	dbms_stats.set_column_stats(
		ownname		=> NULL,
		tabname		=> '&m_target_table.',
		colname		=> '&m_target_column.', 
		distcnt		=> m_distcnt,
		density		=> m_density,
		nullcnt		=> m_nullcnt,
		srec		=> srec,
		avgclen		=> m_avgclen
	); 

*/


--
--	Just in case you comment everything out
--
	null;

end;
/
