/*=====================================================================
Program Name            : age.sas
Purpose                 : Determines a person's age in <units>
                          based on a reference date
SAS Version             : SAS 8.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 30MAY2006
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

data _null_;
   dob = "25Dec60"d;
   end = "25Dec05"d;

   age1 = %age(dob);                   * age in years from today() ;
   age2 = %age(dob,end);               * age in years from 25Dec05 ;
   age3 = %age(dob,end,units=month);   * age in months from 25Dec05 ;
   age4 = %age(dob,units=day);         * age in days from today() ;

   put (dob end) (=date7. +1) (age1-age4) (=);
run;

-----------------------------------------------------------------------
Notes:

This macro must be used inside a data step, in a context valid
for a function call,

It returns an RVALUE, so it must be assigned to a variable,
i.e. be called on the right hand side of an equals sign.

Code copied from various postings to comp.soft-sys.sas.
---------------------------------------------------------------------*/

%macro age
/*---------------------------------------------------------------------
Determines a person's age in <units> (default = years)
based on a reference date.
---------------------------------------------------------------------*/
(BEGDATE       /* Beginning date (REQ).                              */
               /* Usually a person's DOB.                            */
,ENDDATE       /* End date (Opt).                                    */
               /* If not specified, TODAY() is used.                 */
,UNITS=YEAR    /* Units (REQ).                                       */
               /* Default is year.  Valid values are                 */
               /* Y YEAR M MONTH D DAY.                              */
);

%local macro parmerr enddate;
%let macro = &sysmacroname;

%* set default end date if it was not specified ;
%if (%superq(enddate) = %str( )) %then %let enddate = %sysfunc(today());

%* check input parameters ;
%parmv(BEGDATE,      _req=1,_words=0)
%parmv(ENDDATE,      _req=1,_words=0)
%parmv(UNITS,        _req=1,_words=0,_case=U,_val=Y YEAR M MONTH D DAY)

%if (&parmerr) %then %goto quit;

%if (%upcase(%substr(&units,1,1)) = Y) %then %do;
   floor((intck('month',&begdate,&enddate) - (day(&enddate)<day(&begdate)))/12)
%end;
%else
%if (%upcase(%substr(&units,1,1)) = M) %then %do;
   floor((intck('month',&begdate,&enddate) - (day(&enddate)<day(&begdate))))
%end;
%else
%if (%upcase(%substr(&units,1,1)) = D) %then %do;
   &enddate - &begdate
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
