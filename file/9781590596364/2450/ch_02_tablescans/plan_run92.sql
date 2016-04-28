rem
rem	Script:		plan_run92.sql
rem	Author:		Jonathan Lewis
rem	Dated:		1991 (original)
rem	Purpose:	Framework for Explain Plan. Version 9.2 only
rem
rem
rem	Usage:
rem	Write an SQL statement into a script called target.sql. This statement
rem	should start on the first line of the file and end with a semi-colon.
rem	Then execute plan_run9.sql
rem
rem	Preparation:
rem	============
rem	Connect to the SYSTEM (or other suitably privileged) account 
rem	Copy the $ORACLE_HOME/rdbms/admin/utlxplan.sql
rem	Change the CREATE TABLE statement to CREATE GLOBAL TEMPORARY TABLE
rem	with the option "on commit preserve rows"
rem	Add the lines (if needed):
rem		create public synonym plan_table for plan_table
rem		grant all on plan_table to public		
rem

start setenv
set timing off
set linesize 180

column plan		format a160	heading 'Plan'
column id	 	format 999	heading 'Id'
column parent_id 	format 999	heading 'Par'
column position 	format 999	heading 'Pos'
column object_instance 	format 999	heading 'Ins'

column state_id new_value m_statement_id
select userenv('sessionid') state_id from dual;

explain plan
set statement_id = '&m_statement_id'
for
@target

set feedback off
spool &m_statement_id


select
	id,
	parent_id,
	position,
	object_instance,
	rpad(' ',2*level) ||
	operation || ' ' ||
	decode(optimizer,null,null,
		'(' || lower(optimizer) || ') '
	)  ||
	object_type || ' ' ||
	object_owner || ' ' ||
	object_name || ' ' ||
	decode(options,null,null,'('||lower(options)||') ') ||
	other_tag || ' ' ||
	decode(partition_id,null,null,
		'Pt id: ' || partition_id || ' '
	)  ||
	decode(partition_start,null,null,
		'Pt Range: ' || partition_start || ' - ' ||
		partition_stop || ' '
	) ||
	decode(distribution,null,null, 
		'Distribution: ' || distribution || ' '
	) ||
	decode(nvl(cost,0) + nvl(cardinality,0) + nvl(bytes,0),
		0,null,
		'Old Cost (' || nvl(cost,0) || ',' || nvl(cardinality,0) || ',' || nvl(bytes,0) || ') ' 
	) ||
	decode(nvl(io_cost,0) + nvl(cpu_cost,0) + nvl(temp_space,0),
		0,null,
		'New Cost (' || nvl(io_cost,0) || ',' || nvl(cpu_cost,0) || ',' || nvl(temp_space,0) || ') '
	) ||
	decode(search_columns, null,null,
		'(Columns ' || search_columns || ') '
	)  ||
	decode(access_predicates,null,null,
		'Access (' || access_predicates || ') '
	) ||
	decode(filter_predicates,null,null,
		'Filter (' || substr(filter_predicates,1,3800) || ') '
	) 								plan
from
	plan_table
start with
		id = 0 
	and	statement_id = '&m_statement_id'
connect by
		(	parent_id = prior id
		 and	statement_id = prior statement_id
		)
	or
		( 	id = 0
		 and	prior nvl(object_name, ' ') like 'SYS_LE%' 
		 and	nvl(statement_id, ' ') = prior nvl(object_name, ' ')
		)
order siblings by
	id, position
;

rem	*****************************************
rem
rem	Dump remote code, PQ slave code etc. but 
rem	only for lines which have something there
rem	And it's going to lose recursive SQL.
rem
rem	*****************************************

column object_node format a12
column other format a150
set long 20000

select
	id, object_node, other
from
	plan_table
where
	statement_id = '&m_statement_id'
and	other is not null
order by
	id;

select
	id, remarks 
from	
	plan_table
where
	statement_id = '&m_statement_id'
and	remarks is not null
;

spool off

rem
rem	Use the truncate if you have a private, 
rem	permanent plan_table. This is good if 
rem	you have to worry about recursive SQL
rem

rem	truncate table plan_table;

rem
rem	Use the delete if you have a public
rem	permanent plan_table.  It is less 
rem	efficient, but cleans up the mess.
rem
rem	If the table is a GTT with ON COMMIT,
rem	then the data will disappear when we
rem	terminate the session anyway.
rem

delete from plan_table 
where statement_id = '&m_statement_id';

rem
rem	Thanks to recursive SQL for temp tables, you need to do this
rem

rem	delete from plan_table;
commit;

prompt
prompt Output file is &m_statement_id..lst
prompt

