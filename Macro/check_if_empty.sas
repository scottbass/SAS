/*=====================================================================
Program Name            : check_if_empty.sas
Purpose                 : Checks if the source dataset is empty.
SAS Version             : SAS 9.4
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 04MAR2016
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

* create test datasets ;
data empty not_empty;
   set sashelp.shoes (obs=30);
   output not_empty;
run;

* create test views ;
data not_empty_dsv / view=not_empty_dsv;
   set not_empty;
run;
data empty_dsv / view=empty_dsv;
   set empty;
run;

proc sql;
   create view not_empty_sql as
      select * from not_empty
   ;
   create view empty_sql as
      select * from empty
   ;
quit;

%put %check_if_empty(data=empty);         * should be 1 ;
%put %check_if_empty(data=not_empty);     * should be 0 ;

%put %check_if_empty(data=empty_dsv);     * should be 1 ;
%put %check_if_empty(data=not_empty_dsv); * should be 0 ;

%put %check_if_empty(data=empty_sql);     * should be 1 ;
%put %check_if_empty(data=not_empty_sql); * should be 0 ;

%put %check_if_empty(data=db_core.fsc_party_dim); * should be 0, works with Oracle tables too ;

%put %check_if_empty(data=not_empty(where=(region='XXX'))); * should be 1, no obs match where clause ;
%put %check_if_empty(data=doesnotexist);
%put %check_if_empty(data=doesnotexist(where=(region='XXX')));

data _null_;
   if %check_if_empty(data=empty) then
      put "Empty is empty";
   else
   if %check_if_empty(data=not_empty) then
      put "Not_empty is empty";
run;

%macro test;
   %let source=empty;
   %let empty=%check_if_empty(data=&source);
   %if &empty %then %put &source is empty.;

   %let source=not_empty;
   %let empty=%check_if_empty(data=&source);
   %if &empty %then %put &source is empty.;
%mend;
%test;

-----------------------------------------------------------------------
Notes:

This macro is a "pure macro" and returns an rvalue.  It must be on the
right side of an assignment statement, or otherwise used where an
rvalue is appropriate, eg. %put %check_if_empty(data=foo).

Returns 1 if the dataset/view/table is empty, 0 if not empty.
So, the programming logic is
"if <empty> then <empty processing>" or
"if not <empty> then <not empty processing>".

---------------------------------------------------------------------*/

%macro check_if_empty
/*---------------------------------------------------------------------
Checks if the source dataset is empty.
---------------------------------------------------------------------*/
(DATA=         /* Input dataset or view (REQ).                       */
);

%local macro parmerr dataset options;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows data set options */

%if (&parmerr) %then %goto quit;

%let pos=%index(&data,%str(%());
%if (&pos eq 0) %then %do;
   %let dataset=&data;
   %let options=;
%end;
%else %do;
   %let dataset=%substr(&data,1,&pos-1);
   %let options=%substr(&data,&pos);
%end;

%* additional error checking ;
%* check if the dataset exists ;
%if not (%sysfunc(exist(&dataset,data)) or %sysfunc(exist(&dataset,view))) %then %do;
   %parmv(_msg=&dataset does not exist)
   %goto quit;
%end;

%let dsid=%sysfunc(open(&dataset &options,I));
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open &dataset for input)
   %goto quit;
%end;
%let rc=%sysfunc(fetch(&dsid));
%let dsid=%sysfunc(close(&dsid));
%eval(not (&rc eq 0))

%quit:

%mend;

/******* END OF FILE *******/

