/*=====================================================================
Program Name            : realloc_concat_libs.sas
Purpose                 : Reallocate concatenated libraries so that all
                          levels > 1 are allocated as readonly
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 23MAY2013
Program Version #       : 1.0

=======================================================================

Scott Bass (sas_l_739@yahoo.com.au)

This code is licensed under the Unlicense license.
For more information, please refer to http://unlicense.org/UNLICENSE.

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

=======================================================================

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

-----------------------------------------------------------------------
Notes:

Usually this macro is called as an initstmt for the Lev2 and Lev9
environments.  It must be an initstmt because the autoexec executes
before the metadata library allocations.  This macro must be called
after the metadata library allocations are completed.

---------------------------------------------------------------------*/

%macro realloc_concat_libs
/*---------------------------------------------------------------------
Reallocate concatenated libraries so that all levels > 1 are allocated
as readonly.
---------------------------------------------------------------------*/
;

%let options=%sysfunc(getoption(notes)) %sysfunc(getoption(source)) %sysfunc(getoption(nosource));
options nonotes nosource nosource2;
proc sql noprint;
   create table work._concat_libs_ as
   select 
      libname, path, engine, level
   from
      dictionary.libnames
   where
      level > 0 and libname ne "SASHELP"
   ;
run;

filename temp temp;

data _null_;
   set work._concat_libs_;
   file temp;
   by libname notsorted;
   if (level eq 1) then
      put "libname tmp" level '"' path +(-1) '";';
   else
      put "libname tmp" level '"' path +(-1) '" access=readonly;';
   if last.libname then do;
      put "libname " libname engine "(" @;
      do i=1 to level;
         put "tmp" i @;
      end;
      put +(-1) ");";
      do i=1 to level;
         put "libname tmp" i "clear;";
      end;
      put;
   end;
run;

proc delete data=work._concat_libs_;
run;

%include temp / nosource nosource2;
filename temp;
options &options;

%mend;

/******* END OF FILE *******/