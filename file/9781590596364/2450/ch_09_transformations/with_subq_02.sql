rem
rem	Script:		with_subq_02.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2004
rem	Purpose:	More complex sample of subquery factoring.
rem
rem	Last tested 
rem		10.1.0.4
rem		 9.2.0.6
rem
rem	Not relevant
rem		8.1.7.4 
rem
rem	This SQL was generated in response to a challenge from 
rem	Daniel Morgan to derive an answer to an old puzzle, viz:
rem
rem	Two mathematicians at a re-union.
rem		Do you have any children ?
rem		Yes, three.
rem
rem	How old are they ?
rem		Multiply their ages together and you get 36
rem
rem	That's not enough information to work out the answer
rem		Add their ages together and the answer is the
rem		same as the number of people in this room
rem
rem	That's still not enough information to work out the answer
rem		The oldest daughter has a pet hamster with a wooden leg.
rem
rem	Thank you. I've got the answer.
rem
rem	How many people were in the room, and how old are the three girls.
rem	
rem	The SQL is not designed to be efficient, only to show up
rem	the use of a feature, and some side-effects
rem
rem	Observations:
rem	Effects of running Oracle's explain plan - as is
rem	Effects of running Oracle's explain plan - with a dynamic sampling hint
rem	Effects of running Oracle's explain plan - with session level dynamic sampling
rem
rem	Comparing the execution plan with the 10053 trace of the query
rem	Comparing Oracle 9 with Oracle 10
rem	Noting the assumed number of rows in the generated temporary table(s)
rem

start setenv

spool with_subq_02

with age_list as (
	select	rownum age
	from	all_objects
	where	rownum <= 36
),
--	
--	The age_list generates one row per possible age (the product
--	of ages is 36, so we assume the oldest has to be at most 36.
\--
--	I ought to put in an explicit 36 for the final predicate, but
--	I've used the max(age) subquery so that I could avoid having
--	to repeat the literal value.
--
product_check as (
	select
		age1.age 			as youngest, 
		age2.age 			as middle, 
		age3.age 			as oldest,
		age1.age + age2.age + age3.age	as summed,
		age1.age * age2.age * age3.age	as product
	from
		age_list	age1,
		age_list	age2,
		age_list	age3
	where
		age2.age			>= age1.age
	and 	age3.age 			>= age2.age
	and	age1.age * age2.age * age3.age	= (
			select max(age) from age_list
		)
),
--	
--	The product_check generates one column into three, 
--	and generates all the possible combinations of triples,
--	with the columns going from youngest to oldest; and restricts
--	the list to the combinations which multiple up to 36.
--
--	Since we will also be adding up the three ages at some point,
--	we do it here so that the next subquery can name a single column.
--
summed_check as (
select 
	youngest, middle, oldest, summed, product
from
	(
	select
		youngest, middle, oldest, summed, product,
		count(*) over(partition by summed) ct
	from	product_check
	)
where	ct > 1
)
--	
--	The summed_check finds all sums which could be the result 
--	of more than one combination of ages. The answer must be one
--	of these, or the mathematician would not need another clue.
--
--	The final select statement restricts the list to those where
--	there is a single "oldest" girl. The only other option left
--	with the same sum was a row where the two older girls were
--	twins - Use of English eliminates them, not arithmetic. 
--
select 	
	* 
from	summed_check
where
	oldest > middle
;

spool off
