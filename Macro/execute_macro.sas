/*=====================================================================
Program Name            : execute_macro.sas
Purpose                 : Execute a macro if the macro exists.
                          If the macro does not exist do nothing.
SAS Version             : SAS 9.4
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 28SEP2015
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

This macro replaces the default fcf_execute_macro that comes with AML,
and works around a bug in the SAS-supplied macro.

The SAS-supplied macro checks for the existance of a macro in 
WORK.SASMACR and SOURCE.SASMACR only.  However, on Linux, esp. in EG
(and DI Studio?), compiled macros are saved to WORK.SASMAC1 instead of
WORK.SASMACR.

See http://support.sas.com/kb/36/360.html

---------------------------------------------------------------------*/

%macro execute_macro(macroname);
   %let debug=0;

   %if (%superq(macroname) eq ) %then %return;
   %let fullname=&macroname;
   %let macroname=%scan(&macroname,1,%str(%());

   %* Is the macro pre-compiled in work.sasmacr (or work.sasmac1, work.sasmac2, etc) ;
   %if (%sysmacexist(&macroname)) %then %do;
      %put SYSMACEXIST: &macroname;
      %&fullname
      %return;
   %end;

   %* Is SASMSTORE active?  If so, is the macro pre-compiled there? ;
   %* Assume the SASMSTORE catalog name is sasmacr ;
   %let option_mstored   = %sysfunc(getoption(mstored));
   %let option_sasmstore = %sysfunc(getoption(sasmstore));
   %if (&debug) %then %put &=option_sasmstore &=option_mstored;
   %if ((&option_mstored eq MSTORED) and (%length(&option_sasmstore) gt 0)) %then %do;
      %if (%sysfunc(cexist(&option_sasmstore..sasmacr.&macroname..MACRO))) %then %do;
         %put SASMSTORE: %upcase(&option_sasmstore..&macroname..MACRO);
         %&fullname
         %return;
      %end;
   %end;

   %* Is it an autocall macro? ;
   %let rx1=%sysfunc(prxparse(/^\%str(%()(.*)\%str(%))$/));  %* remove leading and trailing parentheses ;
   %let rx2=%sysfunc(prxparse(/('.*?'|".*?"|\S+)/));  %* return single|double-quoted string, or non-space tokens ;
   %if (&debug) %then %put &=rx1 &=rx2;

   %* Get sasautos setting ;
   %let sasautos=%sysfunc(strip(%sysfunc(getoption(sasautos))));
   %if (&debug) %then %put &=sasautos;

   %* Remove leading and trailing parentheses if present ;
   %if (%sysfunc(prxmatch(&rx1,%superq(sasautos)))) %then %let sasautos=%sysfunc(prxposn(&rx1,1,%superq(sasautos)));
   %if (&debug) %then %put &=sasautos;

   %* Now parse the sasautos setting ;
   %let start=1;
   %let stop=%length(%superq(sasautos));
   %let position=0;
   %let length=0;
   %syscall prxnext(rx2, start, stop, sasautos, position, length);
   %if (&debug) %then %put &=start &=stop &=position &=length;

   %do %while (&position gt 0);
      %let found = %substr(%superq(sasautos), &position, &length);
      %if (&debug) %then %put &=found &=position &=length;

      %if (%superq(found) eq %str(,)) %then %goto skip;

      %* If a physical pathname then allocate a temporary fileref ;
      %* If a fileref then just use that one ;
      %if (%sysfunc(indexc(&found,%str(%"%')))) %then %do;
         %let fileref=________;
         %let rc=%sysfunc(filename(fileref,&found));
      %end;
      %else %do;
         %let fileref=&found;
      %end;

      %let dir_handle=%sysfunc(dopen(&fileref));
      %if (&dir_handle ne 0) %then %do;
         %let mem_handle=%sysfunc(mopen(&dir_handle,&macroname..sas,i));
         %if (&mem_handle ne 0) %then %do;
            %put SASAUTOS: %sysfunc(pathname(&fileref))/&macroname..sas;
            %&fullname
            %goto cleanup;
            %return;  %* should never execute but does not hurt ;
         %end;
         %let rc=%sysfunc(dclose(&dir_handle));
         %if (&fileref eq ________) %then %let rc=%sysfunc(filename(&fileref));
      %end;

      %* Next token ;
      %skip:
      %syscall prxnext(rx2, start, stop, sasautos, position, length);      
   %end;

   %cleanup: 
   %if (&mem_handle ne 0) %then %let rc=%sysfunc(fclose(&mem_handle));
   %if (&dir_handle ne 0) %then %let rc=%sysfunc(dclose(&dir_handle));
   %if (&fileref eq ________) %then %let rc=%sysfunc(filename(&fileref));

   %syscall prxfree(rx1);
   %syscall prxfree(rx2);
   %return;
%mend;

/******* END OF FILE *******/
