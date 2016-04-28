This archive contains the scripts listed in each of the chapters
of Cost Based Oracle: Fundamentals. 

There are notes in the scripts that may expand on the comments made 
in the chapters; there are a few files which are not mentioned in
the chapters.

In most cases, you should start a new session before running a script,
otherwise parameter changes from previously run scripts may affect the
outcome of the current script.  There are, however, a few cases where 
you are required to run a couple of scripts one after the other; and 
when this is the case, you are told about it in the script.

The top level directory holds the init.ora files for 8i, 9i, and 10g
that I used on a laptop to prepare some of the tests. You will need 
to adjust references to file names and directories (such as the 
control_files parameter) if you want to copy these init.ora files
into place.  Otherwise you may wish to cut and paste into your 
own init.ora file, or use alter system calls to change your spfile.

If you do choose to transfer values into your existing configuration
file, remember that you may have non-default settings for other
parameters that might affect the optimizer.

