rem
rem	Script:		view_merge_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		September 2002
rem	Purpose:	Demonstrate complex view merging.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	This shows the change in execution path available when Oracle
rem	is allowed to merge predicates into 'complex' views.
rem
rem	The manual (9.2 Perf Guide p.2-37) points out that 
rem	When a view contains one of the following structures, 
rem	it can be merged into a referencing query block only if 
rem	Complex View Merging is enabled:
rem		A GROUP BY clause
rem		A DISTINCT operator in the select list
rem
rem	In this example with 9.2 we see:
rem		With _complex_view_merging = true,  we join then group by
rem		With _complex_view_merging = false, we group by then join
rem
rem	The default for Oracle 8 is FALSE
rem	The default for Oracle 9 is TRUE
rem	The default for Oracle 10 is TRUE, but Oracle 10 works
rem	out the cost of the two different approaches and will
rem	choose the cheaper option. (Run with 10053 trace to see
rem	the different options that appear in the trace files).
rem

start setenv

drop table t2;
drop table t1;

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

create table t1 (
	id_par		number(6)	not null,
	vc1		varchar2(32)	not null,
	vc2		varchar2(32)	not null,
	padding		varchar2(100)
);

alter table t1 add constraint t1_pk primary key (id_par);

create table t2 (
	id_ch		number(6)	not null,
	id_par		number(6)	not null,
	val		number(6,2),
	padding		varchar2(100)
);

alter table t2 add constraint t2_pk primary key (id_ch);
alter table t2 add constraint t2_fk_t1 foreign key (id_par) references t1;

insert into t1
select 
	rownum,
	vc1,
	vc2,
	rpad('x',100)
from
	(
		select 
			lpad(trunc(sqrt(rownum)),32)	vc1,
			lpad(rownum,32)			vc2
		from all_objects
		where rownum <= 32
	)
;

commit;

insert into t2
select
	rownum,
	d1.id_par,
	rownum,
	rpad('x',100)
from
	t1	d1,
	t1	d2
;

commit;

begin
	dbms_stats.gather_table_stats(
		user,
		't1',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		't2',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

create or replace view avg_val_view AS
select 
	id_par, avg(val) avg_val_t1 
from	t2
group by
	id_par
;


spool view_merge_01

set autotrace traceonly explain

prompt
prompt	Baseline example
prompt	Default value for _complex_view_merging
prompt	Query unhinted
prompt

select
	t1.vc1, avg_val_t1
from
	t1, avg_val_view
where	
	t1.vc2 = lpad(18,32)
and	avg_val_view.id_par = t1.id_par
;

alter session set "_complex_view_merging"=true;

prompt
prompt	Complex view merging enabled
prompt	Query unhinted
prompt

select
	t1.vc1, avg_val_t1
from
	t1, avg_val_view
where	
	t1.vc2 = lpad(18,32)
and	avg_val_view.id_par = t1.id_par
;

prompt
prompt	Complex view merging enabled
prompt	no_merge hint applied
prompt

select
	/*+ no_merge (avg_val_view) */
	t1.vc1, avg_val_t1
from
	t1, avg_val_view
where	
	t1.vc2 = lpad(18,32)
and	avg_val_view.id_par = t1.id_par
;


alter session set "_complex_view_merging"=false;

prompt
prompt	Complex view merging disabled
prompt	Query unhinted
prompt

select
	t1.vc1, avg_val_t1
from
	t1, avg_val_view
where	
	t1.vc2 = lpad(18,32)
and	avg_val_view.id_par = t1.id_par
;


prompt
prompt	Complex view merging disabled
prompt	Query hinted to merge - doesn't work
prompt

select
	/*+ merge(avg_val_view) */
	t1.vc1, avg_val_t1
from
	t1, avg_val_view
where	
	t1.vc2 = lpad(18,32)
and	avg_val_view.id_par = t1.id_par
;


set autotrace off

alter session set "_complex_view_merging"=true;

spool off
