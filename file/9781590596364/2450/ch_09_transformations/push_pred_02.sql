rem
rem	Script:		push_pred_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2002
rem	Purpose:	Demo of join predicate pushing
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	In the UNION ALL we get 'partition view',
rem	even though partition_view_enabled = false
rem
rem	In 10.1.0.2, the UNION, gets 'PUSHED PREDICATE'
rem	But this stops in 10.1.0.4
rem
rem	In all cases, the n2 (non-join) filter predicate
rem	has been pushed into the view - but this is a
rem	case of transitive closure, not predicate pushing
rem

start setenv

drop table t3;
drop table t2;
drop table t1;

begin
	begin		execute immediate 'purge recyclebin';
	exception	when others then null;
	end;

	begin		execute immediate 'execute dbms_stats.delete_system_stats';
	exception	when others then null;
	end;

	begin		execute immediate 'alter session set "_optimizer_cost_model"=io';
	exception	when others then null;
	end;

end;
/


create table t1 (
	n1,
	n2,
	padding
)
as
select 
	rownum,
	rownum,
	rpad('x',100)
from
	all_objects
where
	rownum <= 1000
;		

create table t2 (
	n1,
	n2,
	padding
)
as
select 
	rownum,
	rownum,
	rpad('x',100)
from
	all_objects
where
	rownum <= 1000
;		

create table t3 (
	n1,
	n2,
	padding
)
as
select 
	rownum,
	rownum,
	rpad('x',100)
from
	all_objects
where
	rownum <= 1000
;		


alter table t1 add constraint t1_pk primary key (n1);
alter table t2 add constraint t2_pk primary key (n1);
alter table t3 add constraint t3_pk primary key (n1);


begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T1',
		cascade		 => true,
		estimate_percent => null,
		method_opt 	 => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T2',
		cascade		 => true,
		estimate_percent => null,
		method_opt 	 => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		ownname		 => user,
		tabname		 =>'T3',
		cascade		 => true,
		estimate_percent => null,
		method_opt 	 => 'for all columns size 1'
	);
end;
/

create or replace view v_union_all as
select n1, n2, padding from t1
union all
select n1, n2, padding from t2
;

create or replace view v_union as
select n1, n2, padding from t1
union
select n1, n2, padding from t2
;

spool push_pred_02

set autotrace traceonly explain

prompt
prompt	Joining into the UNION ALL
prompt

select 
	t3.n2, 
	v1.n2
from
	t3,
	v_union_all	v1
where
	t3.n2 between 10 and 12
and	v1.n1 = t3.n1
and	v1.n2 = t3.n2
;

prompt
prompt	Joining into the UNION
prompt

select 
	t3.n2, 
	v1.n2
from
	t3,
	v_union	v1
where
	t3.n2 between 10 and 12
and	v1.n1 = t3.n1
and	v1.n2 = t3.n2
;

prompt
prompt	Hinting union_all as strongly as possible
prompt

select 
	/*+ ordered push_pred use_nl(v1) */
	t3.n2, 
	v1.n2
from
	t3,
	v_union_all	v1
where
	t3.n2 between 10 and 12
and	v1.n1 = t3.n1
and	v1.n2 = t3.n2
;


prompt
prompt	Hinting union as strongly as possible
prompt

select 
	/*+ ordered push_pred use_nl(v1) */
	t3.n2, 
	v1.n2
from
	t3,
	v_union		v1
where
	t3.n2 between 10 and 12
and	v1.n1 = t3.n1
and	v1.n2 = t3.n2
;


set autotrace off

spool off

