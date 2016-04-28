rem
rem	Script:		prefetch_test_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2001
rem	Purpose:	Example for Cost Based Oracle.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem	
rem	Not relevant
rem		 8.1.7.4 
rem
rem	You have to supply the number of rows in the 
rem	driving table as the first input parameter to
rem	the script.
rem
rem	With cpu costing (system statistics) enabled,
rem	there are breakpoints in the number of rows in
rem	the driving table where the plan changes from the
rem	classical nested loop to the new nested loop -
rem	using an index range scan on the PK index, even
rem	though there will be only one row to fetch from
rem	the inner table for each row in the outer.
rem
rem	Try 319 and 320 as possible row counts in 9i
rem	I got a range scan on 319, and a unique scan on 320
rem
rem	WARNING
rem	Start a new session before you run this script,
rem	or other test cases may have left the cpu costing
rem	feature disabled for the session
rem

start setenv

drop table driver;
drop table target;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;
end;
/

begin
	dbms_stats.set_system_stats('MBRC',8);
	dbms_stats.set_system_stats('MREADTIM',20);
	dbms_stats.set_system_stats('SREADTIM',10);
	dbms_stats.set_system_stats('CPUSPEED',500);
end;
/


create table driver (
	id,
	xref,
	padding
)
nologging
as
select 
	rownum,
	rownum,
	rpad('x',20)
from
	all_objects
where 
	rownum <= &1
;

alter table driver add constraint d_pk
primary key(id)
;

create table target (
	id,
	small_vc,
	padding
)
as
select
	rownum,
	to_char(rownum),
	rpad('x',20)
from
	all_objects
where 
	rownum <= 3000
;

alter table target add constraint t_pk
primary key (id)
;

begin
	dbms_stats.gather_table_stats(
		user,
		'driver',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'target',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/


spool prefetch_test_02

set autotrace traceonly explain
rem	alter session set events '10132 trace name context forever';
rem	alter session set events '10053 trace name context forever';

select 
	/*+ ordered use_nl(t) index(t) full(d) */
	d.id, t.small_vc
from
	driver	d,
	target	t
where
	t.id = d.xref
and	t.padding is not null
;

alter session set events '10053 trace name context off';
alter session set events '10132 trace name context off';
set autotrace off


spool off


set doc off
doc

The most significant difference in the 10053 traces:

	When we take the UNIQUE scan option, the CPU cost (CPU-RSC) is 
	7,010,825:  this is close to 320 * 21,694 (from index (unique))

	When we take the RANGE scan option, the CPU cost is
	4,988,372:  this is close to 319 * 15,423 (from index (eq-unique))

The differences are:
	7,010,825 - (320 * 21,694) = 68,745
	4,988,372 - (319 * 15,423) = 68,435
which you can assume equate to the CPU cost of the tablescan of
the driving table, with one extra row introducing a slight error.

 
Full NL section for 320 - unique scan
-------------------------------------
NL Join
  Outer table: cost: 3  cdn: 320  rcz: 8  resp:  2

  Access path: index (unique)
      Index: T_PK
  TABLE: TARGET
      RSC_CPU: 21694   RSC_IO: 1
  IX_SEL:  3.3333e-004  TB_SEL:  3.3333e-004
    Join:  resc: 323  resp: 323

  Access path: index (eq-unique)
      Index: T_PK
  TABLE: TARGET
      RSC_CPU: 15423   RSC_IO: 1
  IX_SEL:  0.0000e+000  TB_SEL:  0.0000e+000
    Join:  resc: 323  resp: 323
  Best NL cost: 324  resp: 323

Join cardinality:  320 = outer (320) * inner (3000) * sel (3.3333e-004)  [flag=0]
Join result: cost: 324  cdn: 320  rcz: 37

Best so far: TABLE#: 0  CST:          3  CDN:        320  BYTES:       2560
Best so far: TABLE#: 1  CST:        324  CDN:        320  BYTES:      11840

Final - All Rows Plan:
  JOIN ORDER: 1
  CST: 324  CDN: 320  RSC: 323  RSP: 323  BYTES: 11840
  IO-RSC: 322  IO-RSP: 322  CPU-RSC: 7010825  CPU-RSP: 7010825



Full NL cost section for 319 - range scan
-----------------------------------------
Final - All Rows Plan:
  JOIN ORDER: 1
  CST: 322  CDN: 319  RSC: 322  RSP: 322  BYTES: 11803
  IO-RSC: 321  IO-RSP: 321  CPU-RSC: 4988372  CPU-RSP: 4988372

#
