/*=====================================================================
Program Name            : stp_seplist.sas
Purpose                 : Transform stored process (STP) multi-select
                          macro variable array into a separated list
                          output.
SAS Version             : SAS 9.2
Input Data              : Series of macro variables created by a STP.
Output Data             : Separated list output

Macros Called           : parmv, seplist

Originally Written by   : Scott Bass
Date                    : 24APR2012
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

* simulate macro variable output from a stored process ;
* this is the format from prompt type Text, Multiple Values ;

* multiple character values ;
%let chr0=3;
%let chr1=foo;
%let chr2=bar;
%let chr3=blah blah blah;
%let chr_count=3;

* multiple numeric values ;
%let num0=5;
%let num1=1;
%let num2=2;
%let num3=3;
%let num4=4;
%let num5=5;
%let num_count=5;

* single character values ;
* (SAS is really braindead in the way it implemented a single value macro "array" ;
%let single=braindead;
%let single_count=1;

%put %stp_seplist(chr);
%put %stp_seplist(chr,&chr_count);    * explicit setting of the count parameter ;
%put %stp_seplist(chr,2);             * if you only wanted the first two values ;
%put %stp_seplist(chr,indlm=%str( )); * note that "blah blah blah" got parsed into separate tokens ;
%put %stp_seplist(chr,dlm=|);
%put %stp_seplist(chr,indlm=,dlm=);   * this just concatenates all the words together ;
%put %stp_seplist(chr,indlm=%str( ),dlm=,nest=);   * this just concatenates and compresses all the words together ;
%put %stp_seplist(chr,nest=q);        * useful if your data contains macro special tokens (&, %, etc) ;
%put %stp_seplist(chr,upper=Y);

%put %stp_seplist(num);               * probably not what you want ;
%put %stp_seplist(num,nest=);         * for numbers you want to turn off the default quoting ;
%put %stp_seplist(num,&num_count,nest=);
%put %stp_seplist(num,2,nest=);       * if you only wanted the first two values ;

%put %stp_seplist(single);
%put SAS is %stp_seplist(single,nest=), I tell you!;

=======================================================================

If you want to test this in a stored process itself, save this code as
a stored process:

options mprint;
%macro stp;
  %local where;
  %let where=%sysfunc(sum(&region_count,&product_count,&subsidiary_count));
  options noserror nomerror;
  data subset;
    set sashelp.shoes;
    %if (&where) %then %do;
      where 1
    %end;
    %if (&region_count) %then %do;
      and region in (%stp_seplist(region))
    %end;
    %if (&product_count) %then %do;
      and product in (%stp_seplist(product))
    %end;
    %if (&subsidiary_count) %then %do;
      and subsidiary in (%stp_seplist(subsidiary))
    %end;
    %if (&where) %then %do;
      ;
    %end;
  run;
  options serror merror;

  proc print;
  run;
%mend;
%stp

Create three multi-value text prompts on region, product, and
subsidiary, then run the STP to test the macro execution.

-----------------------------------------------------------------------
Notes:

This macro is meant to be called within a stored process, to return the
macro variable array as a separated list.  Most likely, this separated
list will be used in a where clause.

I have not tested this macro with other prompt types.  It may work with
other types, but a separated list output may or may not be appropriate
to the other prompt types.

This macro is just a "wrapper macro" to the %seplist macro, converting
the macro array created by a STP into a format acceptable to %seplist.

This is a function style macro, and needs to be called in a
syntactically correct context where a separated list output is valid.

---------------------------------------------------------------------*/

%macro stp_seplist
/*---------------------------------------------------------------------
Transform stored process (STP) multi-select macro variable array into a
separated list output.
---------------------------------------------------------------------*/
(MVAR          /* Macro variable name set by the STP (REQ).          */
,COUNT         /* Macro variable element count set by the STP (Opt). */
               /* If not set, a macro variable named <mvar>_count    */
               /* must exist.  This is the case with multi-value     */
               /* text prompts in a STP.                             */
,DLM=%str(,)   /* Output delimiter (Opt).                            */
               /* Default is a comma.                                */
               /* While not technically required, without an output  */
               /* delimiter, all the values are compressed together. */
,INDLM=%str(^) /* Input delimiter (Opt).                             */
               /* If your input data contains spaces, a blank INDLM  */
               /* parameter would cause each space delimited work to */
               /* be treated as a separate token.  In most cases, you*/
               /* will not need to change this value unless your     */
               /* input contains carets (^)                          */
,NEST=QQ       /* Nest each word in the separated list? (Opt).       */
               /* Default is QQ (double-quoting).  See the macro     */
               /* header of %seplist for more details.               */
,UPPER=0       /* Convert to uppercase? (Opt).                       */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr count string temp i;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(MVAR,         _req=1,_words=0,_case=N)
%parmv(NEST,         _req=0,_words=0,_case=U,_val=Q QQ P C B)
%parmv(UPPER,        _req=0,_words=0,_case=Y,_val=0 1)

%if (&parmerr) %then %goto quit;

%* if count was not explicitly specified, a macro variable <mvar>_count ;
%* should exist in the global environment.  if so, resolve it, otherwise assume 1 ;
%if (&count eq ) %then %do;
  %if (%symexist(&&mvar._count)) %then
    %let count=&&&mvar._count;
  %else
    %let count=1;
%end;

%* compensate for the absolute braindead way SAS implemented a single element macro "array" ;
%if (&count eq 1) %then %let &mvar.1=&&&mvar;

%let string=;
%let temp=;

%* Using %superq inside the loop generates the error: ;
%* ERROR: Maximum level of nesting of macro functions exceeded. ;
%* See http://support.sas.com/kb/00/449.html ;

%* If the source data contains tokens that can be interpretted as macro characters, ;
%* (for example Savings&Loan, %change), then set the options noserror nomerror ;
%* outside this macro.  I cannot set it here since this is a function style macro ;
%do i=1 %to &count;
  %if (&i gt 1) %then %let string=&string.&indlm;
  %let temp=&&&mvar&i;
  %if (&upper eq 1) %then %let temp=%upcase(&temp);
  %let string=&string.&temp;
%end;

%seplist(%superq(string),indlm=&indlm,dlm=&dlm,nest=&nest)

%quit:
%mend;
