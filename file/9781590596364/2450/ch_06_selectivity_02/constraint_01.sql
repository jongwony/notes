rem
rem	Script:		constraint_01.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Mar 2004
rem	Purpose:	Oracle generating predicates from constraints
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant 
rem		 8.1.7.4
rem
rem	Acknowledgement:
rem		Vadim Tropashko for bringing this to my
rem		attention in one of this articles on
rem		www.dbazine.com
rem
rem	The cost based optimizer can use constraints to add
rem	extra options for access paths.  Typically NOT NULL
rem	and UNIQUE constraints make the most difference, but 
rem	in principle any constraint could add value.
rem
rem	This does not work if the constraints are deferrable.
rem
rem	Under 9.2, the following code uses the constraint 
rem			colX = upper(colX) 
rem	to make an index available on the predicate
rem		where	upper(colX) = {const}
rem
rem	This works ONLY IF the column is also declared as
rem	a mandatory (not null) column - it isn't even sufficient
rem	if you create a table-level constraint to enforce not null.
rem
rem	However, if {const} is a bind variable in version 10, then
rem	the index is not used.  (It is used for literals). 
rem	This last observation means that if you switch from 
rem	"cursor_sharing = exact" to "cursor_sharing = force"
rem	you will suddenly find that some of your queries
rem	stop using indexes.  Be careful when testing
rem	this, as if the SQL with the literal is still in
rem	the library cache, then it will be used BEFORE
rem	bind variable substitution takes place.
rem
rem	There was a bug in early 9.2 which means you could get
rem	the wrong answer if the constraint caused the generated
rem	predicate to do a null comparison. So the code was changed
rem	in 10g (possibly back-ported to 9.2.0.6) so that the predicate 
rem	is generated ONLY IF it will not cause a comparison with null
rem
rem	Event 10195 is related to predicate generation from constraints.
rem

start setenv
set timing off

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
	id	number, 
	v1	varchar2(40),
	constraint t1_ck_v1 check (v1=upper(v1)) 
	-- deferrable
);


rem
rem	A table level not-null constraint will not work
rem	A column-level declaration is needed
rem

alter table t1 modify v1 not null;
--	alter table t1 add constraint t1_ck check (v1 is not null);

begin
	dbms_random.seed(0);
	for n in 1..10000 loop
		insert into t1 (id, v1) values (n, dbms_random.string('U', 30));
	end loop;
end;
/

create index t1_i1 on t1(v1);

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

 
variable bind_var varchar2(30)
exec :bind_var := 'SMITH'

spool constraint_01

set autotrace traceonly explain

rem	alter session set events '10053 trace name context forever';

prompt
prompt	Predicate: upper(v1) = upper('SMITH')
prompt

select
	*
from	t1 
where 
	upper(v1) = upper('SMITH');

prompt
prompt	Predicate: upper(v1) = 'SMITH'
prompt

select
	*
from	t1 
where 
	upper(v1) = 'SMITH';

prompt
prompt	Predicate: upper(v1) = upper(:bind_var)
prompt	Uses index in 9.2, but not in 10.1.0.4
prompt

select
	*  
from	t1
where
	upper(v1) = upper(:bind_var);

prompt
prompt	Predicate: upper(v1) = :bind_var
prompt	Uses index in 9.2, but not in 10.1.0.4
prompt

select
	*  
from	t1
where
	upper(v1) = :bind_var;

set autotrace off

spool off

alter session set events '10053 trace name context off';


set doc off
doc


#
