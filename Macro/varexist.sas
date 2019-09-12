/*=====================================================================
Program Name            : varexist.sas
Purpose                 : Check for the existence of a specified
                          variable, optionally returning attributes.
SAS Version             : Unknown (probably SAS 8.2)
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 27APR2007
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

* Test data ;
data test;
   length dummy1 dummy2 $1 date 5 dummy4 dummy5 8;
   attrib date
      format=date9.
      informat=yymmdd8.
      label="This is a date variable"
   ;
   call missing(of _all_);
   date="01JAN1960"d;
run;

* Variable exists ;
%put EXISTS: %varexist(work.test,date);  * returns varnum, i.e. 3 ;

* Variable does not exist ;
%put EXISTS: %varexist(work.test,doesnotexist);  * returns 0 ;

* Dataset does not exist ;
%put EXISTS: %varexist(doesnotexist,doesnotexist);  * returns 0 ;

* Variable attributes ;
%put VARNUM:   %varexist(work.test,date,num);
%put LENGTH:   %varexist(work.test,date,len);
%put FORMAT:   %varexist(work.test,date,fmt);
%put INFORMAT: %varexist(work.test,date,infmt);
%put LABEL:    %varexist(work.test,date,label);
%put TYPE:     %varexist(work.test,date,type);

-----------------------------------------------------------------------
Notes:

This macro must be used in a context valid for a function call.

It returns an RVALUE, so it must be assigned to a variable,
i.e. be called on the right hand side of an equals sign.

Code copied from various postings to comp.soft-sys.sas.
---------------------------------------------------------------------*/

%macro varexist
/*---------------------------------------------------------------------
Check for the existence of a specified variable, optionally returning
attributes.
---------------------------------------------------------------------*/
(DATA          /* Source dataset (REQ).                              */
,VAR           /* Source variable (REQ).                             */
,INFO          /* Variable attribute (Opt).                          */
               /* If blank, a flag variable is returned indicating   */
               /* if the variable exists.                            */
               /* If specified, the variable attribute is returned.  */
               /* Valid values are:                                  */
               /*    NUM   = variable number                         */
               /*    LEN   = length of variable                      */
               /*    FMT   = format of variable                      */
               /*    INFMT = informat of variable                    */
               /*    LABEL = label of variable                       */
               /*    TYPE  = type of variable (N=numeric,C=character)*/
               /* Default is to return the variable number           */
);

%local macro parmerr dsis rc varnum;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0)
%parmv(VAR,          _req=1,_words=0)
%parmv(INFO,         _req=0,_words=0,_case=U,_val=NUM LEN FMT INFMT LABEL TYPE)

%if (&parmerr) %then %goto quit;

%*---------------------------------------------------------------------
Use the SYSFUNC macro to execute the SCL OPEN, VARNUM,
other variable information and CLOSE functions.
----------------------------------------------------------------------;
%let dsid = %sysfunc(open(&data));

%if (&dsid) %then %do;
   %let varnum = %sysfunc(varnum(&dsid,&var));

   %if (&varnum) %then %do;
      %if (%length(&info)) %then %do;
         %if (&info eq NUM) %then %do;
&varnum
         %end;
         %else %do;
%sysfunc(var&info(&dsid,&varnum))
         %end;
      %end;
      %else %do;
&varnum
      %end;
   %end;

   %else 0;

   %let rc = %sysfunc(close(&dsid));
%end;

%else 0;

%quit:
%mend;

/******* END OF FILE *******/