-- Query clean display
set pagesize 0
set feedback off

-- SPOOL concatenation string in temp file
spool result.sql

-- col department_id format a20
SELECT DISTINCT('col '||COLUMN_NAME||' format a'||DATA_LENGTH) "--"
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME IN (SELECT TABLE_NAME FROM USER_TABLES)
AND DATA_TYPE LIKE 'VARCHAR2';

spool off

-- result.sql read/write access
!chmod -R 770 result.sql

-- append glogin.sql
!cat result.sql >> $ORACLE_HOME/sqlplus/admin/glogin.sql

-- remove temp file
!rm -rf result.sql

!echo $ORACLE_HOME/sqlplus/admin/glogin.sql is UPDATED.
!read -p " Press the Enter key SQL PLUS will be terminated."
!echo -----------------------------------\
!echo -- Please reconnect with SQLPlus.--\
!echo -----------------------------------\

-- session exit
exit

