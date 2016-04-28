rem
rem	Script:		dependent.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Selectivity Issues - dependent columns
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Test conditions:
rem		Locally managed tablespace
rem		Uniform extent size 1M
rem		Block size 8K
rem		Segment space management MANUAL
rem
rem	This is  the demonstraton data from the first B-tree chapter,
rem	but we update the N2 column to match the N1 column.
rem

start setenv


drop table t1;

execute dbms_random.seed(0);

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

create table t1 
nologging
as
select
	trunc(dbms_random.value(0,25))	n1,
	rpad('x',40)			ind_pad,
	trunc(dbms_random.value(0,20))	n2,
	lpad(rownum,10,'0')		small_vc,
	rpad('x',200)			padding
from
	all_objects
where
	rownum  <= 10000
;

update t1 set n2 = n1;

create index t1_i1 on t1(n1, ind_pad, n2) 
nologging
pctfree 91
;

begin
	dbms_stats.gather_table_stats(
		ownname => user,
		tabname	=> 'T1',
		cascade	=> true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

spool dependent

select	
	table_name,
	blocks,
	num_rows
from	user_tables
where	table_name = 'T1'
;

select 
	num_rows, distinct_keys,
	blevel, leaf_blocks, clustering_factor, 
	avg_leaf_blocks_per_key, avg_data_blocks_per_key
from
	user_indexes
where	table_name = 'T1'
and	index_name = 'T1_I1'
;

select 
	column_name,
	num_nulls, num_distinct, density,
	low_value, high_value
from
	user_tab_columns
where	table_name = 'T1'
and	column_name in ('N1','N2','IND_PAD')
order by
	column_name
;


set autotrace traceonly explain

select
	/*+ index(t1) */
	small_vc
from
	t1
where
	n1	= 2
and	ind_pad	= rpad('x',40)
and	n2	= 2
;

set autotrace off
set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever, level 65535';

select
	/*+ index(t1) dynamic_sampling(t1 1) */
	small_vc
from
	t1
where
	n1	= 2
and	ind_pad	= rpad('x',40)
and	n2	= 2
;

rem	alter session set events '10053 trace name context off';

set autotrace off

spool off



set doc off
doc

===============================================================

Trace file from 9.2.0.6
=======================

SELECT 
	/*+ ALL_ROWS IGNORE_WHERE_CLAUSE */ 
	NVL(SUM(C1),0), NVL(SUM(C2),0) 
FROM 
	(
		SELECT /*+ IGNORE_WHERE_CLAUSE NOPARALLEL("T1") */ 
			1 AS C1, 
			CASE 
				WHEN 
					"T1"."N1"=2 
				    AND "T1"."IND_PAD"='x                                       ' 
				    AND "T1"."N2"=2 
				THEN 1 
				ELSE 0 
			END AS C2 
		FROM "T1" SAMPLE BLOCK (8.355795) "T1"
) SAMPLESUB

*** 2005-04-25 16:52:11.531
** Executed dynamic sampling query:
    level : 1
    sample pct. : 8.355795
    actual sample size : 837
    filtered sample card. : 37
    orig. card. : 10000
    block cnt. : 371
    max. sample block cnt. : 32
    sample block cnt. : 31
    min. sel. est. : 0.0016
** Using dynamic sel. est. : 0.04420550

=====================================================


Trace file from 10.1.0.4
========================
SELECT /
	* OPT_DYN_SAMP */ 
	/*+ ALL_ROWS IGNORE_WHERE_CLAUSE NO_PARALLEL(SAMPLESUB) NO_PARALLEL_INDEX(SAMPLESUB) */ 
	NVL(SUM(C1),0), NVL(SUM(C2),0), NVL(SUM(C3),0) 
FROM 
	(SELECT 
		/*+ IGNORE_WHERE_CLAUSE NO_PARALLEL("T1") FULL("T1") NO_PARALLEL_INDEX("T1") */ 
		1 AS C1, 
		CASE 
			WHEN 
				"T1"."N1"=2 
			    AND "T1"."IND_PAD"='x                                       ' 
			    AND "T1"."N2"=2 
			THEN 1 
			ELSE 0 
		END AS C2, 
		CASE 
			WHEN 
				"T1"."N2"=2 
			    AND "T1"."IND_PAD"='x                                       ' 
			    AND "T1"."N1"=2 
			THEN 1 
			ELSE 0 
		END AS C3 
	FROM "T1" SAMPLE BLOCK (8.355795 , 1) SEED (1) "T1"
	) SAMPLESUB

** Executed dynamic sampling query:
    level : 1
    sample pct. : 8.355795
    actual sample size : 891
    filtered sample card. : 35
    filtered sample card. (index T1_I1): 35
    orig. card. : 10000
    block cnt. table stat. : 371
    block cnt. for sampling: 371
    max. sample block cnt. : 32
    sample block cnt. : 31
    min. sel. est. : 0.00160000
    index T1_I1 selectivity est.: 0.03928171
** Using single table dynamic sel. est. : 0.03928171

=====================================================


Trace file from 10.1.0.2 when there is no index on the table
============================================================
(This sample taken at level 2)
==============================

SELECT /* OPT_DYN_SAMP */ /*+ ALL_ROWS IGNORE_WHERE_CLAUSE NO_PARALLEL(SAMPLESUB) NO_PARALLEL_INDEX(SAMPLESUB) */ 
	NVL(SUM(C1),0), NVL(SUM(C2),0) 
FROM 	(
	SELECT /*+ IGNORE_WHERE_CLAUSE NO_PARALLEL("T1") FULL("T1") NO_PARALLEL_INDEX("T1") */ 
		1 AS C1, 
		CASE WHEN "T1"."N1"=2 AND "T1"."IND_PAD"='x                                       ' AND "T1"."N2"=2 
			THEN 1 
		ELSE 0 
		END AS C2 
	FROM "T1" SAMPLE BLOCK (16.981132 , 1) SEED (1) "T1"
	) SAMPLESUB

*** 2004-11-05 12:00:32.689
** Executed dynamic sampling query:
    level : 2
    sample pct. : 16.981132
    actual sample size : 2025
    filtered sample card. : 89
    orig. card. : 10000
    block cnt. table stat. : 371
    block cnt. for sampling: 371
    max. sample block cnt. : 64
    sample block cnt. : 63
    min. sel. est. : 0.00160000
** Using single table dynamic sel. est. : 0.00890000
  TABLE: T1  Alias: T1     
    Original Card: 10000  Rounded Card: 89  Computed Card: 89.00
  Access Path: table-scan  Resc:  58  Resp:  58
  BEST_CST: 58.00  PATH: 2  Degree:  1



Trace file from 10.1.0.2 when there is an index on the table
============================================================
(This sample taken at level 2)
==============================

** Dynamic sampling initial checks returning TRUE (level = 2).
** Dynamic sampling index access candidate : T1_I1
*** 2004-11-05 11:53:39.615
** Generated dynamic sampling query:
    query text : 
SELECT /* OPT_DYN_SAMP */ /*+ ALL_ROWS NO_PARALLEL(SAMPLESUB) NO_PARALLEL_INDEX(SAMPLESUB) */ 
	NVL(SUM(C1),0), NVL(SUM(C2),0), NVL(SUM(C3),0) 
FROM	(
	SELECT /*+ NO_PARALLEL("T1") INDEX("T1" T1_I1) NO_PARALLEL_INDEX("T1") */ 
		1 AS C1, 1 AS C2, 1 AS C3  
		FROM "T1" "T1" 
		WHERE "T1"."N1"=2 
		AND "T1"."IND_PAD"='x                                       ' 
		AND "T1"."N2"=2 AND ROWNUM <= 2500
	) SAMPLESUB

*** 2004-11-05 11:53:39.685
** Executed dynamic sampling query:
    level : 2
    sample pct. : 100.000000
    actual sample size : 10000
    filtered sample card. : 403
    filtered sample card. (index T1_I1): 403
    orig. card. : 10000
    block cnt. table stat. : 371
    block cnt. for sampling: 371
    max. sample block cnt. : 4294967295
    sample block cnt. : 371
    min. sel. est. : 0.00160000
    index T1_I1 selectivity est.: 0.04030000
** Using single table dynamic sel. est. : 0.04030000
  TABLE: T1  Alias: T1     
    Original Card: 10000  Rounded Card: 403  Computed Card: 403.00
  Access Path: index (equal)
    Index: T1_I1
    rsc_cpu: 0   rsc_io: 295
    ix_sel:  4.0300e-002    ix_sel_with_filters:  4.0300e-002
  BEST_CST: 295.00  PATH: 4  Degree:  1


#