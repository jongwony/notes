rem
rem	Script:		template.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sep 2004
rem	Purpose:	Example for "Cost Based Oracle"
rem
rem	Last tested:
rem		10.1.0.4
rem		 9.2.0.6
rem		 8.1.7.4
rem
rem	Create a function that takes an input string
rem	and returns the numeric value that the optimizer 
rem	would use to represent it.
rem
rem	Inputs:
rem		The string
rem		The size limit if the string is to be 
rem		treated as a char() rather than varchar2()
rem
rem	Special note:
rem	This function will not work for multi-byte character sets.
rem

start setenv

create or replace function cbo_char_value (
	i_instring in varchar2,
	i_charsize in number default 0
) return number
as
	m_size	number;
	m_vc varchar2(15);
	m_n number := 0;
begin
	if i_charsize = 0 then 
		m_size := length(i_instring) ;
	else 
		m_size := i_charsize ;
	end if;

	m_vc := rpad(rpad(i_instring,m_size,' '),15,chr(0));

	for i in 1..15 loop

		dbms_output.put(ascii(substr(m_vc,i,1)));
		dbms_output.put(chr(9));
		dbms_output.put_Line(
			to_char(
				power(256,15-i) * ascii(substr(m_vc,i,1)),
				'999,999,999,999,999,999,999,999,999,999,999,999'
			)
		);
		m_n := m_n + power(256,15-i) * ascii(substr(m_vc,i,1));
	end loop;
	return	m_n;
end;
.
/

rem
rem	Example of use:
rem	Assumes the table from date_oddity.sql exists.
rem

select
	round(
		1827 * (
			2/1827 +
			(cbo_char_value('20030105') - cbo_char_value('20021230')) /
			(cbo_char_value('20041231') - cbo_char_value('20000101'))
		),2
	)	cardinality
from
	dual
;

spool off
