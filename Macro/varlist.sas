/*=====================================================================
Program Name            : varlist.sas
Purpose                 : Returns a string containing a space separated
                          list of variables in a dataset.
SAS Version             : Unknown (probably SAS 8.2)
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 06DEC2007
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

%put %varlist(sashelp.class);
   Returns the list of variables in SASHELP.CLASS.

options mprint;
proc sql;
   select %seplist(%varlist(SASHELP.CLASS),prefix=a.)
   from SASHELP.CLASS as a
   ;
quit;

   Returns the list of variables in SASHELP.CLASS,
   then use the %seplist macro to format this as a comma separated list.

-----------------------------------------------------------------------
Notes:

This macro must be used in a context valid for a function call.

It returns an RVALUE, so it must be assigned to a variable,
i.e. be called on the right hand side of an equals sign.

---------------------------------------------------------------------*/

%macro varlist
/*---------------------------------------------------------------------
Returns a string containing a space separated list of variables in a
dataset.
---------------------------------------------------------------------*/
(DATA          /* Source dataset (REQ).                              */
);

%local macro parmerr;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(data,_req=1,_words=0,_case=U)

%if (&parmerr) %then %goto quit;

%* open dataset for input ;
%let dsid=%sysfunc(open(&data,i));

%* if open failed, abort ;
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open &data);
   %goto quit;
%end;

%do i=1 %to %sysfunc(attrn(&dsid,nvars));
%sysfunc(varname(&dsid,&i))  /* do not indent this statement */
%end;
%let dsid=%sysfunc(close(&dsid));

%quit:
%mend;

/******* END OF FILE *******/
