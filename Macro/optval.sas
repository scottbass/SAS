/*=====================================================================
Program Name            : optval.sas
Purpose                 : Returns value of option
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 01MAY2007
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

* print current options ;
%put %optval(missing) %optval(ls) %optval(ps);

* save values of current options, then change options ;
%let options = %optval(missing) %optval(ls) %optval(ps);
%put &options;

options missing="$" ls=70 ps=20;
%put %optval(missing) %optval(ls) %optval(ps);

* use new value of missing option ;
data _null_;
   x=.;
   put x=;
run;

* restore options to original values ;
options &options;
%put %optval(missing) %optval(ls) %optval(ps);

-----------------------------------------------------------------------
Notes:

---------------------------------------------------------------------*/

%macro optval
/*---------------------------------------------------------------------
Returns value of option
---------------------------------------------------------------------*/
(OPTNAME       /* Option name (REQ).                                 */
,KEYWORD=N     /* Return value in a KEYWORD= format? (Opt)           */
               /* If Y, the KEYWORD parameter is passed to the       */
               /* getoption function.                                */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(OPTNAME,      _req=1,_words=0,_case=N)
%parmv(KEYWORD,      _req=1,_words=0,_case=Y,_val=0 1)

%if (&parmerr) %then %goto quit;

%if (&keyword) %then %do;
   %sysfunc(getoption(&optname,keyword))
%end;
%else %do;
   %sysfunc(getoption(&optname))
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
