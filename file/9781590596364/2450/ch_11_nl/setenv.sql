rem
rem	Script:		setenv.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Set up various SQL*Plus formatting commands.
rem
rem	Notes:
rem

set pause off

set serveroutput on size 1000000 format wrapped
rem	exec dbms_java.set_output(1000000)

set doc off
doc
	Sections of documentation end with a line starting with #
#

set linesize 120
set trimspool on
set pagesize 24
set arraysize 25
set long 20000

set autotrace off

clear breaks
ttitle off
btitle off

column owner format a15
column segment_name format a20
column table_name format a20
column index_name format a20
column object_name format a20
column partition_name format a20
column subpartition_name format a20
column column_name format a20
column constraint_name format a20

column low_value format a24
column high_value format a24

column parent_id_plus_exp	format 999
column id_plus_exp		format 990
column plan_plus_exp 		format a90
column object_node_plus_exp	format a10
column other_plus_exp		format a90
column other_tag_plus_exp	format a29

column os_username		format a30
column terminal			format a24
column userhost			format a24
column client_id		format a24

column statistic_name format a35

column namespace format a20
column attribute format a20

column time_now noprint new_value m_timestamp

select to_char(sysdate,'hh24miss') time_now
from dual;

set feedback off
commit;
set feedback on

set verify off
set timing off

alter session set optimizer_mode = all_rows;

spool log

