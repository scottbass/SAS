/*=====================================================================
Program Name            : date_impute.sas
Purpose                 : Impute partial dates
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 28JUL2010
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

data input_mm_format;
   length date 8 y m d $4;
   format date date9.;
   input  date yymmdd8. y m d;
   datalines;
20100728 2010  07    28
.        2010  07    UK
.        2010  UNK   28
.        2010  UK    UNK
.        UNK   07    28
.        UNK   07    UNK
.        UNK   UNK   UNK
;
run;

data output_mm_format;
   set input_mm_format;

   %date_impute(
      in_date=date
      ,in_y=y
      ,in_m=m
      ,in_d=d
      ,out_date=date_imputed
      ,out_flag=date_imputed_flag
      ,imp_y=year(date())
      ,imp_m=1
      ,imp_d=1
      ,month_fmt=mm
   );

   length date_imputed_flagc $3;
   date_imputed_flagc=ifc(date_imputed_flag,"Yes","No");
   format date_imputed is8601da.;
run;

Impute dates
When the input date variable DATE is missing
Where Y, M, and D are input character variables for year, month, and day
And month format is MM (01, 02, etc.)
Creating the output variable date_imputed
And also creating the output variable date_imputed_flag (SAS boolean value)
Using the rule "year(date())" for the imputed Year value
Using the rule "1" for the imputed Month value (this is the default)
Using the rule "1" for the imputed Day value (this is the default)
Derive the date_imputed_flagc variable in a post-processing step
And override the default output date format of date9 with is8601da.;

=======================================================================

data output_mm_format;
   set input_mm_format;

   * simulate an end date value in the source data ;
   end_date="01FEB2222"d;
*  end_date="01NOV2123"d;  * to test ifn logic ;

   %date_impute(
      in_date=
      ,in_y=y
      ,in_m=m
      ,in_d=d
      ,out_date=date_imputed
      ,out_flag=date_imputed_flag
      ,imp_y=.
      ,imp_m=ifn(month(end_date) le 8,1,9)
      ,imp_d=15
      ,month_fmt=mm
   );

   * if the date was imputed, implement these additional rules ;
   * if year was unknown, date cannot be imputed (remains missing) ;
   * if month and day were both unknown, set to end of year ;
   * if day was unknown, set to end of month ;
   if date_imputed_flag then do;
      if (not missing(date_imputed)) then do;
         if (__M_error and __D_error) then
            date_imputed=intnx("year",date_imputed,0,"E");
         else
         if (__D_error) then
            date_imputed=intnx("month",date_imputed,0,"E");
      end;
   end;
run;

Unconditionally impute dates (in_date parameter is missing)
Where Y, M, and D are input character variables for year, month, and day
And month format is MM (01, 02, etc.)
Creating the output variable date_imputed
And also creating the output variable date_imputed_flag (SAS boolean value)
Using the rule "." (missing) for the imputed Year value (this is the default)
Using the rule "ifn(month(end_date le 6),1,7)" for the imputed Month value
Using the rule "15" for the imputed Day value.
And post-processing the results to implement additional, more complex
   imputation rules.

=======================================================================

data input_mon_format;
   length date 8 y m d $4;
   input  date yymmdd8. y m d;
   datalines;
20100728 2010  JUL   28
.        2010  JUL   UK
.        2010  UNK   28
.        2010  UK    UNK
.        UNK   JUL   28
.        UNK   JUL   UNK
.        UNK   UNK   UNK
;
run;

data output_mon_format;
   set input_mon_format;

   %date_impute(
      in_date=date
      ,in_y=y
      ,in_m=m
      ,in_d=d
      ,out_date=date_imputed
      ,out_flag=date_imputed_flag
      ,imp_y=year(date())
      ,month_fmt=mon
   );

run;

Same output as first example, using input data where the format of the
Month variable is mon (Jan, FEB, Mar, etc.) instead of mm (01, 02, etc.)
Default values imp_m=1 and imp_d=1 were used.

-----------------------------------------------------------------------
Notes:

This macro must be called within a data step.

This macro resets the automatic data step error flag _error_.
Therefore, you should call this macro:
   1) Near the top of your data step, or
   2) In a dedicated data step where only date imputations are calculated.
Otherwise, this macro's resetting of the data step error flag variable
could mask other errors created by code outside this macro.

SAS's automatic putting of _all_ data step variables when _error_=1
takes place at the end of the data step (when "run;" is encountered)
so you are "safe" if you call this macro near the top of the data step.
Downstream code after this macro may still set the _error_ variable.

Code fragments can be used for the imputation rules as long as they
resolve to a syntactically correct assigment statement.
For example, from the above test cases:

   if missing(__Y) then __Y=year(date());
   if missing(__Y) then __Y=year(end_date);
   if missing(__M) then __M=ifn(month(end_date le 8),1,9);

If your required imputation rules cannot be specified per the above
requirements, you can still call this macro, then implement your own
imputation rules in post-processing using the derived variables
__Y, __M, __D.

OUT_DATE, IMP_Y, IMP_M, and IMP_D are all optional parameters.
However, if any of these parameters are blank, no imputation is done
other than creating the __Y, __M, and __D variables for further
post-processing after this macro.

By default no date imputation is done if the Year input variable
is missing (since the default value for IMP_Y=.).

---------------------------------------------------------------------*/

%macro date_impute
/*---------------------------------------------------------------------
Impute partial dates
---------------------------------------------------------------------*/
(IN_DATE=      /* Input date variable (Opt).                         */
               /* If specified, dates are imputed only if the date   */
               /* variable is not missing.  This variable is often a */
               /* SAS date variable, but could also be a date        */
               /* character string, where the same logic above still */
               /* applies.                                           */
,IN_Y=         /* Input Year variable (REQ).                         */
               /* Should be a character variable,                    */
               /* use "put(year,best.-L)" to convert.                */
,IN_M=         /* Input Month variable (REQ).                        */
               /* Should be a character variable,                    */
               /* use "put(month,best.-L)" to convert.               */
,IN_D=         /* Input Day variable (REQ).                          */
               /* Should be a character variable,                    */
               /* use "put(day,best.-L)" to convert.                 */
,OUT_DATE=     /* Output imputed date variable (Opt).                */
               /* No format is applied, apply format in calling code.*/
,OUT_FLAG=     /* Output imputed date flag variable (Opt).           */
               /* If specified, the flag variable is created         */
               /* indicating if the date was imputed.                */
,IMP_Y=.       /* Imputation rule for Year variable (Opt).           */
               /* The default value is "." (missing) which means by  */
               /* default no date imputation is done if the IN_Y     */
               /* value is not a valid numeric value.                */
,IMP_M=1       /* Imputation rule for Month variable (Opt).          */
,IMP_D=1       /* Imputation rule for Day variable (Opt).            */
,MONTH_FMT=MM  /* Input Month variable format (REQ).                 */
               /* Valid values are MM (01, 02, etc.) or MON          */
               /* (Jan, Feb, etc.).  Default is MM.                  */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%_parmv(IN_DATE,     _req=0,_words=0,_case=U)
%_parmv(IN_Y,        _req=1,_words=0,_case=U)
%_parmv(IN_M,        _req=1,_words=0,_case=U)
%_parmv(IN_D,        _req=1,_words=0,_case=U)
%_parmv(OUT_DATE,    _req=0,_words=0,_case=N)
%_parmv(OUT_FLAG,    _req=0,_words=0,_case=N)
%_parmv(IMP_Y,       _req=0,_words=1,_case=N)
%_parmv(IMP_M,       _req=0,_words=1,_case=N)
%_parmv(IMP_D,       _req=0,_words=1,_case=N)
%_parmv(MONTH_FMT,   _req=1,_words=0,_case=U,_val=MM MON)

%if (&parmerr) %then %goto quit;

%* check if OUT_DATE, IMP_Y, IMP_M, or IMP_D are blank ;
%let no_impute=%eval((%superq(out_date) eq ) or (%superq(imp_y) eq ) or (%superq(imp_m) eq ) or (%superq(imp_d) eq ));

* create working variables ;
attrib __Y        length=8  label="Derived Year Value";
attrib __M        length=8  label="Derived Month Value";
attrib __D        length=8  label="Derived Day Value";

attrib __Y_error  length=8  label="Derived Year Error Flag";
attrib __M_error  length=8  label="Derived Month Error Flag";
attrib __D_error  length=8  label="Derived Day Error Flag";

* derive working variables ;
__Y=input(&in_y, ? best.);
__Y_error=_error_;
_error_=0;

%* if MONTH_FORMAT is MON, use the MONYY. informat and a dummy year value to derive the month number ;
%if (&month_fmt eq MON) %then %do;
   __M=input(cats(&in_m,"9999"), ? monyy.);
   __M_error=_error_;
   if not missing(__M) then __M=month(__M);
   _error_=0;
%end;
%else %do;
   __M=input(&in_m, ? best.);
   __M_error=_error_;
   _error_=0;
%end;

__D=input(&in_d, ? best.);
__D_error=_error_;
_error_=0;

%* if imputation flag variable is desired, derive it now before applying imputation rules ;
%if (&out_flag ne ) %then %do;
   * derive imputation flag variable ;
   &out_flag=(nmiss(__Y,__M,__D) ne 0);
%end;

%* if no imputation is desired, bail out ;
%if (&no_impute) %then %goto quit;

* apply partial date imputation rules ;

%* if IN_DATE is specified, only impute dates if IN_DATE is missing ;
%* otherwise unconditionally impute dates ;
%if (&in_date ne ) %then %do;
if missing(&in_date) then do;
%end;
   if missing(__Y) then __Y=&imp_y;
   if missing(__M) then __M=&imp_m;
   if missing(__D) then __D=&imp_d;

   * derive imputed date ;
   if (nmiss(__M,__D,__Y) eq 0) then &out_date=mdy(__M,__D,__Y);
   format &out_date date9.;
%if (&in_date ne ) %then %do;
end;
%end;

%quit:

%mend;

/******* END OF FILE *******/
