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

Copyright (c) 2016 Scott Bass

https://github.com/scottbass/SAS/tree/master/Macro

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
