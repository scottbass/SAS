/*=====================================================================
Program Name            : check_if_empty.sas
Purpose                 : Checks if the source dataset is empty and,
                          if so, prints a message to the print file.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 06AUG2010
Program Version #       : 1.0

=======================================================================

Modification History    :

Programmer              : Scott Bass
Date                    : 08MAR2011
Change/reason           : Added OUT= and TEXT= parameters
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* create test datasets ;
data empty not_empty;
   set sashelp.shoes (obs=30);
   output not_empty;
run;

* create test views ;
data v_empty / view=v_empty;
   set sashelp.shoes;
   stop;
run;

proc sql;
   create view v_not_empty as
      select * from sashelp.shoes (obs=30)
   ;
quit;

-----------------------------------------------------------------------

options ps=20 ls=80 nonumber nodate;
title "Test of check_if_empty macro";

* check empty dataset with default text;
* only the macro invocation will print output ;
* the proc print does not print output since the dataset is empty. ;
%check_if_empty(data=empty);
proc print data=empty noobs;
run;

=======================================================================

* check empty dataset but do not print any output ;
* this will create the &_empty_ macro variable ;
* and _empty_ dataset, but allows the calling program ;
* to print whatever it wants, in this case a msg to the log ;
%check_if_empty(data=empty,print=N);
%put %sysfunc(ifc(&_empty_,Dataset is empty,Dataset is not empty));
proc print data=empty noobs;
run;

* now print the output dataset ;
* the macro would do this automatically if PRINT=Y ;
proc print data=_empty_ noobs;
run;

=======================================================================

* check non-empty dataset but do not print any output ;
* this will create the &_empty_ macro variable ;
* and _empty_ dataset, but allows the calling program ;
* to print whatever it wants, in this case a msg to the log ;
%check_if_empty(data=not_empty,print=N);
%put %sysfunc(ifc(&_empty_,Dataset is empty,Dataset is not empty));
proc print data=not_empty noobs;
run;

=======================================================================

* check empty dataset with non-default text;
%check_if_empty(data=empty,var=mytext,text=%nrstr(No Observations Were Found/in the %upcase(&data) dataset.));
proc print data=empty noobs;
run;

%check_if_empty(data=empty,var=mytext,text=%nrstr(No Observations Were Found~in the %upcase(&data) dataset.),justify=left,split=~);
proc print data=empty noobs;
run;

%check_if_empty(data=empty,var=mytext,text=%nrstr(No Observations Were Found^in the %upcase(&data) dataset.),justify=right,split=^);
proc print data=empty noobs;
run;

* check non-empty dataset with non-default text ;
%check_if_empty(data=not_empty,var=mytext,text=%nrstr(No Observations Were Found/in the %upcase(&data) dataset.));
proc print data=not_empty noobs;
run;

=======================================================================

* check using views ;

* change linesize option ;
options ls=64;

* empty ;
%check_if_empty(data=v_empty,out=);  * this generates an error, empty view requires output dataset ;

=======================================================================

%check_if_empty(data=v_empty);  * this works, default output dataset=_empty_ ;
proc print data=v_empty;
run;

=======================================================================

* not empty ;
%check_if_empty(data=v_not_empty,out=testing);  * remember, OUT= dataset only created when DATA= dataset is empty ;
proc print data=v_not_empty;
run;

=======================================================================

* where clause applied, non-empty result ;
%check_if_empty(data=not_empty (where=(product="Men's Dress")));
proc print data=not_empty;
   where product="Men's Dress";  * use the same where clause as the input dataset!!! ;
run;

=======================================================================

* where clause applied, empty result ;
%check_if_empty(data=not_empty (where=(region="Does Not Exist")));
proc print data=not_empty;
   where region="Does Not Exist";  * use the same where clause as the input dataset!!! ;
run;

-----------------------------------------------------------------------
Notes:

This macro always returns the global macro variable &_empty_ to indicate
whether the source dataset was empty or not.  It also always creates the
dataset _empty_ with text for printing, when the input dataset is empty.

If the PRINT parameter is No, no printing is done, and the calling
program can use the &_empty_ macro variable or the _empty_ dataset
to print whatever it wants.

This macro will work with SAS datasets, data step views, SQL views,
or when a where clause is applied.

If the OUT= parameter is blank, the DATA= dataset will be overwritten
if it is empty.  This is usually used with PRINT=N, and when the
source dataset is used in downstream processing (for example within
another macro).  By default, OUT=_empty_.

If the input dataset (DATA= parameter) is an empty view, OUT= must be
specified or an error will result.

If a where clause is applied, make sure you use the same where clause
in both the "empty check" and the actual output generation code.  See
examples above.

The WIDTH specification must be less than or equal to the current
linesize options.  Since the default WIDTH=80, if the linesize option
is less than 80, either decrease WIDTH or increase the linesize option.

---------------------------------------------------------------------*/

%macro check_if_empty
/*---------------------------------------------------------------------
Checks if the source dataset is empty and (optionally) prints a message
to the print file.
---------------------------------------------------------------------*/
(DATA=         /* Input dataset or view (REQ).                       */
,OUT=_EMPTY_   /* Output dataset (Opt).                              */
               /* Default is _EMPTY_.                                */
               /* If not specified,_the input dataset is overwritten.*/
               /* If the input dataset is a view, OUT must be        */
               /* specified or an error will result                  */
,VAR=text      /* Variable name in output dataset (REQ).             */
,TEXT=No Observation Found
               /* Text to print if the input dataset is empty. (REQ).*/
,WIDTH=        /* Text output width (Opt).                           */
               /* If not specified, the current linesize is used.    */
,JUSTIFY=CENTER/* Text justification (REQ). Default is CENTER.       */
               /* Valid values are LEFT CENTER RIGHT.                */
,SPLIT=/       /* PROC REPORT split character (REQ).  Default is /.  */
,PRINT=Y       /* Print standard output? (REQ).  Default is Y.       */
               /* If Y, the standard output from this macro is       */
               /* printed.                                           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows data set options */
%parmv(OUT,          _req=0,_words=0,_case=N)  /* no data set options on output dataset */
%parmv(VAR,          _req=1,_words=0,_case=U)
%parmv(TEXT,         _req=1,_words=1,_case=N)
%parmv(WIDTH,        _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(JUSTIFY,      _req=1,_words=0,_case=U,_val=LEFT CENTER RIGHT)
%parmv(SPLIT,        _req=1,_words=0,_case=N)
%parmv(PRINT,        _req=1,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* if OUT is blank, set it to DATA ;
%* be careful if input dataset options are specified, ;
%* that are incorrect for output datasets. ;
%if (%superq(out) eq ) %then %let out=%superq(data);

%* if WIDTH is blank, set it to the current linesize ;
%if (&width eq ) %then %let width=%sysfunc(getoption(ls));

%* delete the _empty_ dataset from previous macro invocations ;
proc datasets lib=work nowarn nolist;
   delete _empty_;
quit;

%global _empty_;
%let _empty_=1;
data _null_;
   set &data;
   call symputx("_empty_",0);
   stop;
run;

%* unfortunately, PROC REPORT does not honor the justification when FLOW is on ;
%* so, hack a solution by parsing on the SPLIT character ;
%if (&_empty_) %then %do;
   data &out;
      length &var $&width temp $5000;
      temp="&text";
      i=1;
      &var=scan(temp,i,"&split");
      do while(&var ne "");
         output;
         i+1;
         &var=resolve(scan(temp,i,"&split"));
      end;
      keep &var;
   run;

   %if (&print) %then %do;
      proc report data=&out nowindows headskip split="&split";
         column &var;
         define &var / display width=&width &justify ' ';
      run;
   %end;
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
