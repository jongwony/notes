rem
rem	Script:		char_value.sql
rem	Author:		Jonathan Lewis
rem	Dated:		Sept 2003
rem	Purpose:	Demonstration script for Cost Based Oracle'.
rem
rem	Versions tested 
rem		10.1.0.2
rem		 9.2.0.4
rem		 8.1.7.4
rem
rem	Notes:
rem	Create a function to accept an input string and
rem	return the numeric value that Oracle would use
rem	as the endpoint_value for that string in user_tab_histograms
rem

start setenv
set timing off

create or replace function char_value(i_vc varchar2) return number
is
	m_vc varchar2(15) := substr(rpad(i_vc,15,chr(0)),1,15);
	m_n number := 0;
begin
	for i in 1..15 loop
/*
		dbms_output.put(ascii(substr(m_vc,i,1)));
		dbms_output.put(chr(9));
		dbms_output.put_Line(
			to_char(
				power(256,15-i) * ascii(substr(m_vc,i,1)),
				'999,999,999,999,999,999,999,999,999,999,999,999'
			)
		);
*/
		m_n := m_n + power(256,15-i) * ascii(substr(m_vc,i,1));
	end loop;


--	dbms_output.put_line(to_char(m_n,'999,999,999,999,999,999,999,999,999,999,999,999'));


	m_n := round(m_n, -21);

--	dbms_output.put_line(to_char(m_n,'999,999,999,999,999,999,999,999,999,999,999,999'));

	return m_n;
end;
/


spool char_value

rem
rem	Sample of use:
rem	

column id format 999,999,999,999,999,999,999,999,999,999,999,999

select 
	'Aardvark'		text,
	char_value('Aardvark')	id 
from dual;

spool off
