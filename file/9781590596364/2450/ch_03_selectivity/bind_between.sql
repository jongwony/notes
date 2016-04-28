rem
rem	Script:		bind_between.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem	Purpose:	Using binds with a between clause.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	Unbounded range scans against bind variables 
rem	use a fixed 5% as the selectivity.
rem	e.g.	ColumnX <= :bind_var
rem	
rem	However, 
rem		not (ColumnX <= :bind_var)
rem	also uses 5%.
rem
rem	Then
rem		column between :b1 and :b2
rem	is rewritten as
rem		column >= :b1
rem	    and	column <= :b2
rem	with a selectivity of 0.25%.  (5% of 5%)
rem
rem	So what happens with:
rem		not(column between :b1 and :b2)
rem
rem	Answer: The rewrite must be:
rem		column < :b1
rem	     or	column > :b2
rem
rem	But the normal 'or' bug that appears with
rem	in-lists also appears here, so Oracle works
rem	this out as:
rem		5% (column < :b1) +
rem		5% (column > :b2) -
rem		0.25% (column < :b1 and column > :b2) =
rem		9.75%
rem
rem	One a table of 20,000 rows, all three versions 
rem	showed 1,950 as the cardinality for
rem		not (id between :b1 and :b2)
rem
rem	Oracle 8 has the usual rounding difference on
rem		between :b1 and :b2
rem	with a cardinality of 51, where the other two
rem	versions produced a cardinality of 50
rem

start setenv
set timing off

execute dbms_random.seed(0);

drop table t1;
purge recyclebin

create table t1 as
select
	rownum	id
from
	all_objects
where	rownum <= 20000
;


analyze table t1 compute statistics;

variable b1 number
variable b2 number

set autotrace traceonly explain

select
	count(*) 
from	t1
where id between :b1 and :b2
;

select
	count(*) 
from	t1
-- where not (id between :b1 and :b2)
where id not between :b1 and :b2
;

set autotrace off

spool off
