rem
rem	Script:		c_ts_test.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Create tablespaces for "Cost Based Oracle"
rem
rem	Versions Tested:
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Pick the version
rem	Check the base directory name
rem
rem	WARNING:
rem	This script drops tablespaces - make sure that the
rem	ones it drops don't contain any useful information
rem
rem	REMEMBER:
rem	You have to set up a db_XXk_cache_size for each of
rem	the non-standard block sizes you want to use or 
rem	this script will give you Oracle error:
rem
rem		ORA-29339: tablespace block size nnnnn does not match configured block sizes
rem
rem	Some platforms do not support a 32K block size
rem	Do not try to set a db_xxk_cache_size for your
rem	default block size.
rem
rem	The 'drop tablespace' commands may results in 
rem	Oracle error:
rem		ORA-00959: tablespace 'XXXXXXXX' does not exist
rem

rem
rem	define m_dir='z:\oracle\oradata\D10g\'
rem	define m_dir='z:\oracle\oradata\D920\'
rem

spool c_ts_test

drop tablespace test_2k      including contents and datafiles;
drop tablespace test_4k      including contents and datafiles;
drop tablespace test_8k      including contents and datafiles;
drop tablespace test_8k_assm including contents and datafiles;
drop tablespace test_16k     including contents and datafiles;
drop tablespace test_32k     including contents and datafiles;


create tablespace test_2k
blocksize 2K
datafile '&m_dir.\test_2k.dbf' size 193m reuse
extent management local 
uniform size 1M
segment space management manual
;


create tablespace test_4k
blocksize 4K
datafile '&m_dir.\test_4k.dbf' size 193m reuse
extent management local 
uniform size 1M
segment space management manual
;


create tablespace test_8k
blocksize 8K
datafile '&m_dir.\test_8k.dbf' size 193m reuse
extent management local 
uniform size 1M
segment space management manual
;


create tablespace test_8k_assm
blocksize 8K
datafile '&m_dir.\test_8k_assm.dbf' size 193m reuse
extent management local 
uniform size 1M
segment space management auto
;


create tablespace test_16k
blocksize 16K
datafile '&m_dir.\test_16k.dbf' size 193m reuse
extent management local 
uniform size 1M
segment space management manual
;


create tablespace test_32k
blocksize 32K
datafile '&m_dir.\test_32k.dbf' size 385m reuse
extent management local 
uniform size 1M
segment space management manual
;


/*

alter user test_user quota unlimited on test_2k;
alter user test_user quota unlimited on test_4k;
alter user test_user quota unlimited on test_8k;
alter user test_user quota unlimited on test_8_assm;
alter user test_user quota unlimited on test_16k;

alter user test_user default tablespace test_8k;

*/

spool off
