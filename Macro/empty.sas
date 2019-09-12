/*=====================================================================
Program Name            : empty.sas
Purpose                 : Checks if the source dataset is empty.
SAS Version             : SAS 9.4
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 04MAR2016
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

%put %empty(data=empty);         * should be 1 ;     
%put %empty(data=not_empty);     * should be 0 ;

%put %empty(data=empty_dsv);     * should be 1 ;    
%put %empty(data=not_empty_dsv); * should be 0 ;

%put %empty(data=empty_sql);     * should be 1 ;
%put %empty(data=not_empty_sql); * should be 0 ;

%put %empty(data=db_core.fsc_party_dim); * should be 0, works with Oracle tables too ;

%put %empty(data=not_empty(where=(region='XXX'))); * should be 1, no obs match where clause ;
%put %empty(data=doesnotexist);
%put %empty(data=doesnotexist(where=(region='XXX')));

data _null_;
   if %empty(data=empty) then
      put "Empty is empty";
   else
   if %empty(data=not_empty) then
      put "Not_empty is empty";
run;      
   
%macro test;
   %let source=empty;
   %let empty=%empty(data=&source);
   %if &empty %then %put &source is empty.;
   
   %let source=not_empty;
   %let empty=%empty(data=&source);
   %if &empty %then %put &source is empty.;
%mend;
%test;

-----------------------------------------------------------------------
Notes:

This macro is a "pure macro" and returns an rvalue.  It must be on the 
right side of an assignment statement, or otherwise used where an 
rvalue is appropriate, eg. %put %empty(data=foo).

Returns 1 if the dataset/view/table is empty, 0 if not empty.
So, the programming logic is 
"if <empty> then <empty processing>" or
"if not <empty> then <not empty processing>".

---------------------------------------------------------------------*/

%macro empty
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

