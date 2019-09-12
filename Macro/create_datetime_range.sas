/*=====================================================================
Program Name            : create_datetime_range.sas
Purpose                 : Create min and max datetime values for a
                          given period
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 23OCT2007
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

%create_datetime_range;
   Creates &dt_beg and &dt_end macro variables with period of DAY
   based on the value of the DATETIME() function

=======================================================================

%create_datetime_range(,MONTH);
   Creates &dt_beg and &dt_end macro variables with period of MONTH
   based on the value of the DATETIME() function

=======================================================================

%create_datetime_range(25DEC2007);
   Creates &dt_beg and &dt_end macro variables with period of DAY
   based on the value of 25DEC2007.  Uses the anydtdtm informat
   to convert the date to a datetime value.

=======================================================================

%create_datetime_range(20071020);
   Creates &dt_beg and &dt_end macro variables with period of DAY based
   on the value of 20071020 (20OCT2007).  Uses the anydtdtm informat to
   convert the date to a datetime value.

=======================================================================

%create_datetime_range(01JAN1960:12:34:56);
   Creates &dt_beg and &dt_end macro variables with period of DAY based
   on the value of 01JAN1960:12:34:56.  Uses the anydtdtm informat to
   convert the date to a datetime value.

=======================================================================

%let datetime=%sysfunc(datetime());
%create_datetime_range(&datetime)
   This will NOT WORK.  The datetime parameter must be a datetime
   *string*, not datetime *value*.

=======================================================================

%let datetime=%sysfunc(datetime(),datetime20.);
%create_datetime_range(&datetime)
   But this *would* work.

If the data is specified as YYYYMM, you need to suffix that with a day,
i.e. 01, since 200709 is ambiguous, and would be interpretted as
20JUL2009.

For example:

data month_key;
   month_key = "200709";
run;

* create a macro variable ;
proc sql noprint;
   select month_key into :month_key separated by " " from month_key;
quit;

* now create datetime ranges ;
%create_datetime_range(&month_key.01);

-----------------------------------------------------------------------
Notes:

I could have also specified an informat parameter, but felt that the
anydtdtm informat meets all our needs.  This will cover any date /
datetime string of the format DATE, DATETIME, DDMMYY, JULIAN, MMDDYY,
MONYY, TIME, YYMMDD, or YYQ.

Note that you CANNOT specify an actual datetime value, since the
anydtdtm informat is hard coded.  IOW, if you have a macro variable
containing a date or datetime value, you'll first need to use a
date(time) format to convert it to a string of the above form.

If any error occurs, the macro variables will be unset.  This ensures
a warning in the calling program, which will call attention to
fixing the problem.

---------------------------------------------------------------------*/

%macro create_datetime_range
/*---------------------------------------------------------------------
Create min and max datetime values for a given time period
---------------------------------------------------------------------*/
(DATETIME      /* Input datetime (Opt).                              */
               /* If not specified, DATETIME() function is used.     */
,PERIOD        /* Datetime period (Opt).                             */
               /* If not specified, DAY is used.                     */
               /* Valid values are D DAY M MONTH and are case-       */
               /* insensitive.                                       */
);

%* unset macro variables from previous macro invocations ;
%symdel dt_beg dt_end / nowarn;

%local macro parmerr;
%let macro = &sysmacroname;

%* set default period if it was not specified ;
%if (&period eq ) %then %let period = D;

%* check input parameters ;
%parmv(PERIOD,       _req=1,_words=0,_case=U,_val=D DAY M MONTH)

%if (&parmerr) %then %goto quit;

%global dt_beg dt_end;

data _null_;
   if "&datetime" = "" then
      datetime = datetime();
   else
      datetime = input("&datetime",anydtdtm.);

   select (substr("&period",1,1));
      when("D") period = "dtday";
      when("M") period = "dtmonth";
   end;

   dt_beg = put(intnx(period,datetime,0,"B"),datetime20.-L);
   dt_end = put(intnx(period,datetime,0,"E"),datetime20.-L);

   call symput("dt_beg",trim(dt_beg));
   call symput("dt_end",trim(dt_end));
   call symput("_error_",put(_error_,best.-L));
run;

%if (&_error_ ne 0) %then %symdel dt_beg dt_end / nowarn;

%quit:

%mend;

/******* END OF FILE *******/
