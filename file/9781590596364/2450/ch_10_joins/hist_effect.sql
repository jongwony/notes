rem
rem	Script:		hist_effect.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Sometimes a histogram can cause a disaster on joins.
rem	We have a (small) currency table, and lots of orders
rem	in various currencies.
rem

start setenv

execute dbms_random.seed(0)

drop table currencies;
drop table orders;

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

/*

rem
rem	8i code to build scratchpad table
rem	for generating a large data set
rem

*/

drop table generator;
create table generator as
select
	rownum 	id
from	all_objects 
where	rownum <= 3000
;


create table orders (
	id	 	not null,
	currency_id	not null,
	currency_vc	not null,
	small_vc,
	padding
)
nologging		-- adjust as necessary
pctfree 10		-- adjust as necessary
pctused 90		-- adjust as necessary
as
/*
with generator as (
	select	--+ materialize
		rownum 	id
	from	all_objects 
	where	rownum <= 3000
)
*/
select
	/*+ ordered use_nl(v2) */
	rownum			id,
	1			currency_id,
	'01'			currency_vc,
	lpad(rownum,10,'0')	small_vc,
	rpad('x',100)		padding
from
	generator	v1,
	generator	v2
where
	rownum <= 300000
;

update orders set currency_id =  2 where currency_id = 1 and rownum <= 25000;
update orders set currency_id =  3 where currency_id = 1 and rownum <=  5000;
update orders set currency_id =  4 where currency_id = 1 and rownum <=  4000;
update orders set currency_id =  5 where currency_id = 1 and rownum <=  3000;
update orders set currency_id =  6 where currency_id = 1 and rownum <=  2000;
update orders set currency_id =  7 where currency_id = 1 and rownum <=  2000;
update orders set currency_id =  8 where currency_id = 1 and rownum <=  1000;
update orders set currency_id =  9 where currency_id = 1 and rownum <=  1000;
update orders set currency_id = 10 where currency_id = 1 and rownum <=  1000;

commit;

update orders set currency_vc = lpad(currency_id,2,'0') where currency_id != 1;

commit;


create table currencies (
	id		number		not null,
	name		varchar2(10)	not null,
	constraint c_pk primary key(id)
)
;

insert into currencies values( 1,'USD');
insert into currencies values( 2,'GBP');
insert into currencies values( 3,'DKR');
insert into currencies values( 4,'EUR');
insert into currencies values( 5,'005');
insert into currencies values( 6,'006');
insert into currencies values( 7,'007');
insert into currencies values( 8,'008');
insert into currencies values( 9,'009');
insert into currencies values(10,'010');
insert into currencies values(11,'011');
insert into currencies values(12,'012');
commit;


begin
	dbms_stats.gather_table_stats(
		user,
		'orders',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'orders',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 75'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'currencies',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for all columns size 1'
	);
end;
/

begin
	dbms_stats.gather_table_stats(
		user,
		'currencies',
		cascade => true,
		estimate_percent => null,
		method_opt => 'for columns currency_id size 75'
	);
end;
/


spool hist_effect

select 
	table_name, column_name, density
from	user_tab_columns
where	table_name in ('ORDERS','CURRENCIES')
order by
	table_name, column_id
;


set autotrace traceonly explain

select
	count(*)
from
	currencies	c,
	orders		o
where
	c.id = 'EUR'
and	o.currency_id = c.id
;

set autotrace off

spool off
