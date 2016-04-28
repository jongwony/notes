rem
rem	Script:		book_subq.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Nov 2004
rem	Purpose:	Demonstration that subqueries don't always tranform
rem
rem	Last tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	10g can turn the 'not exists' into a hash anti-join
rem	without a hint. 9i does it only if hinted (unnest)
rem	in this example. This is odd, since _unnest_subquery
rem	defaults to true and _unnest_notexists_sq = SINGLE
rem

start setenv

execute dbms_random.seed(0)

drop table sales;
drop table books;

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


rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 2000
;



create table sales
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 5000
)
*/
select
	trunc(7000*dbms_random.normal)	book_key,
	rownum				sale_id,
	rpad('x',200)			padding
	/*+ ordered use_nl(v2) */
from
	generator	v1,
	generator	v2
where
	rownum <= 100000
;

create table books
as
select 
	book_key, 
	rpad('x',200)	padding
from (
	select book_key from sales
	union
	select rownum from all_objects
	where rownum <= 2000
)
;

create unique index bk_pk on books(book_key);

alter table books 
	add constraint bk_pk primary key(book_key);


create unique index sl_pk on sales(book_key, sale_id);

alter table sales 
	add constraint sl_pk primary key(book_key, sale_id);

alter table sales 
	add constraint sl_fk_bk foreign key (book_key) references books(book_key)

begin
	dbms_stats.gather_table_stats(
		user,
		'books',
		cascade=>true, 
		estimate_percent => null, 
		method_opt=> 'for all columns size 1'
	);

	dbms_stats.gather_table_stats(
		user,
		'sales',
		cascade=>true, 
		estimate_percent => null, 
		method_opt=> 'for all columns size 1'
	);
end;
/


spool book_subq

set autotrace traceonly explain

prompt
prompt	The NOT IN subquery.
prompt

select	book_key
from	books
where	book_key NOT IN (
		select book_key from sales
	)
;
 

prompt
prompt	The equivalent NOT EXISTS subquery.
prompt

select	book_key
from	books
where	NOT EXISTS (
		select	null 
		from	sales
		where	sales.book_key = books.book_key
	)
;


set autotrace off

spool off

