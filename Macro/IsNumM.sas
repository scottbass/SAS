/*=====================================================================
Program Name            : IsNumM.sas
Purpose                 : Checks if alphanumeric MACRO variable input
                          (which is always character data) is valid
                          numeric data.
                          Optionally checks for IsInt, IsNonNeg, or 
                          IsPos.
SAS Version             : SAS 9.3
Input Data              : Alphanumeric data contained in a macro
                          variable.
Output Data             : Return code indicating IsNum, IsInt,
                          IsNonNeg, or IsPos.

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 16FEB2016
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

options missing=' ';

* check for numeric input ;
%put isnum=%IsNumM( );
%put isnum=%IsNumM(.);
%put isnum=%IsNumM(._);
%put isnum=%IsNumM(.A);
%put isnum=%IsNumM(.Z);
%put isnum=%IsNumM(-1);
%put isnum=%IsNumM(0);
%put isnum=%IsNumM(1);
%put isnum=%IsNumM(1.1);
%put isnum=%IsNumM( 123456789012.123456789012);
%put isnum=%IsNumM(-123456789012.123456789012);
%put isnum=%IsNumM( 1234567890123.1234567890123);
%put isnum=%IsNumM(-1234567890123.1234567890123);
%put isnum=%IsNumM( 12345678901234.12345678901234);
%put isnum=%IsNumM(-12345678901234.12345678901234);
%put isnum=%IsNumM( 123456789012345.123456789012345);
%put isnum=%IsNumM(-123456789012345.123456789012345);
%put isnum=%IsNumM( 1234567890123456.1234567890123456);
%put isnum=%IsNumM(-1234567890123456.1234567890123456);
%put isnum=%IsNumM( 1.1);
%put isnum=%IsNumM( -123);
%put isnum=%IsNumM( -123.45);
%put isnum=%IsNumM( --123.45);
%put isnum=%IsNumM(A);
%put isnum=%IsNumM( B);
%put isnum=%IsNumM(123 456);
%put isnum=%IsNumM(123-456);
%put isnum=%IsNumM(~!@#$%^&*()_+=);

options missing='.';
%put isnum=%IsNumM( );
%put isnum=%IsNumM(.);
%put isnum=%IsNumM(._);
%put isnum=%IsNumM(.A);
%put isnum=%IsNumM(.Z);
%put isnum=%IsNumM(-1);
%put isnum=%IsNumM(0);
%put isnum=%IsNumM(1);
%put isnum=%IsNumM(1.1);
%put isnum=%IsNumM( 123456789012.123456789012);
%put isnum=%IsNumM(-123456789012.123456789012);
%put isnum=%IsNumM( 1234567890123.1234567890123);
%put isnum=%IsNumM(-1234567890123.1234567890123);
%put isnum=%IsNumM( 12345678901234.12345678901234);
%put isnum=%IsNumM(-12345678901234.12345678901234);
%put isnum=%IsNumM( 123456789012345.123456789012345);
%put isnum=%IsNumM(-123456789012345.123456789012345);
%put isnum=%IsNumM( 1234567890123456.1234567890123456);
%put isnum=%IsNumM(-1234567890123456.1234567890123456);
%put isnum=%IsNumM( 1.1);
%put isnum=%IsNumM( -123);
%put isnum=%IsNumM( -123.45);
%put isnum=%IsNumM( --123.45);
%put isnum=%IsNumM(A);
%put isnum=%IsNumM( B);
%put isnum=%IsNumM(123 456);
%put isnum=%IsNumM(123-456);
%put isnum=%IsNumM(~!@#$%^&*()_+=);

* check for integer input ;
%put isint=%IsNumM(1,type=int);
%put isint=%IsNumM(1.1,type=int);
%put isint=%IsNumM(999999999999,type=int);
%put isint=%IsNumM(9999999999999,type=int);
%put isint=%IsNumM(99999999999999,type=int);
%put isint=%IsNumM(999999999999999,type=int);
%put isint=%IsNumM(9999999999999999,type=int);
%put isint=%IsNumM(99999999999999999,type=int);
%put isint=%IsNumM(999999999999999999,type=int);
%put isint=%IsNumM(9999999999999999999,type=int);

* check for non-negative input ;
%put isnonneg=%IsNumM(-1,type=nonneg);
%put isnonneg=%IsNumM(-1.2,type=nonneg);
%put isnonneg=%IsNumM(0,type=nonneg);
%put isnonneg=%IsNumM(1,type=nonneg);
%put isnonneg=%IsNumM(1.2,type=nonneg);

* check for positive input ;
%put ispos=%IsNumM(-1,type=pos);
%put ispos=%IsNumM(-1.2,type=pos);
%put ispos=%IsNumM(0,type=pos);
%put ispos=%IsNumM(1,type=pos);
%put ispos=%IsNumM(1.2,type=pos);

* treat missing data (not including special missing data) as valid ;
%put missing=%IsNumM(  ,missing=N);
%put missing=%IsNumM(. ,missing=N);
%put missing=%IsNumM(._,missing=N);
%put missing=%IsNumM(.A,missing=N);
%put missing=%IsNumM( .M,missing=N);
%put missing=%IsNumM(  .Z  ,missing=N);
%put missing=%IsNumM(-1,missing=N);
%put missing=%IsNumM( 0,missing=N);
%put missing=%IsNumM( 1,missing=N);

%put missing=%IsNumM(  ,missing=Y);
%put missing=%IsNumM(. ,missing=Y);
%put missing=%IsNumM(._,missing=Y);
%put missing=%IsNumM(.A,missing=Y);
%put missing=%IsNumM( .M,missing=Y);
%put missing=%IsNumM(  .Z  ,missing=Y);
%put missing=%IsNumM(-1,missing=Y);
%put missing=%IsNumM( 0,missing=Y);
%put missing=%IsNumM( 1,missing=Y);

-----------------------------------------------------------------------
Notes:

This is "pure macro" code and returns an R-value ("function style macro").
It must be called in the correct context for such a macro.

Since %sysfunc does not support the INPUT function, the INPUTN function
is used instead.  INPUTN does not support the ?? modifier to suppress
invalid numeric input.  

Therefore, additional error checking of the 
source data (via a Perl regular expression) is used to prevent the 
macro from throwing warning messages.

Note that the check for IsInt collapses for large numbers,
where precision is lost and the difference between 
num and int(num) becomes 0 [num-int(num)=0].  

On my machine, this happens around 1E15, or 15 significant digits.

Unlike the %IsNum macro, which runs in a data step, this function style
macro does not treat special missing values as valid numeric data.
This is an edge case that I am happy not to cater for.

---------------------------------------------------------------------*/

%macro IsNumM
/*---------------------------------------------------------------------
Checks if alphanumeric (character) input is valid numeric data.
---------------------------------------------------------------------*/
(CHAR          /* Character variable to check (Opt).                 */
 ,TYPE=NUM     /* Type of check to run (REQ).                        */
               /* Valid values are NUM INT NONNEG or POS             */
               /* (case-insensitive)                                 */
 ,MISSING=N    /* Include missing values as valid numeric input?(REQ)*/
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);

%local macro parmerr rx match num;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(TYPE,         _req=1,_words=0,_case=U,_val=NUM INT NONNEG POS)
%parmv(MISSING,      _req=1,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* remove leading spaces ;
%let char=&char;
%* put CHAR=*&char*;  %* for debugging ;

%* use a Perl regex to test for empty string, missing(.), or special missing (._,.A-.Z) data  ;
%* if YES: ;
%* if MISSING=N treat as not valid numeric data ;
%* if MISSING=Y treat as valid numeric data ;
%let rx = %sysfunc(prxparse(/^( *|\.[A-Z_]*)$/o));
%let match = %sysfunc(prxmatch(&rx,%superq(char)));
%syscall prxfree(rx);
%if (&match eq 1) %then %do;
   %if (&missing) %then %let rtn=1; %else %let rtn=0;
&rtn
   %return;
%end;

%* use a Perl regex to test for numeric input ;
%* the regex is "/^(-{0,1})(\d*)(\.{0,1})(\d*)$/o", which means: ;
%* beginning of string (^): ;
%* 0 or 1 minus signs: ;
%* 0 or more digits: ;
%* 0 or 1 periods: ;
%* 0 or more digits: ;
%* end of string ($) ;
%* compile the regex once (o) ;
%let rx = %sysfunc(prxparse(/^(-{0,1})(\d*)(\.{0,1})(\d*)$/o));
%let match = %sysfunc(prxmatch(&rx,%superq(char)));
%syscall prxfree(rx);

%* if no match then not num ;
%if (&match eq 0) %then %do;
0
   %return;
%end;

%* the Perl regex should be sufficient to cleanse the input to the inputn function ;   
%* convert the value to num. if it is missing then not num ;
%* note: this only supports options missing='.' and options missing=' ' ;
%let num=%sysfunc(inputn(%superq(char),best32.),best32.);
%let num=&num;
%* put NUM =#&num#; %* for debugging ;
%if (%superq(num) eq .) or (%superq(num) eq ) %then %do;
0
   %return;
%end;

%* it is probably a num :-) ;
%if (&type eq NUM) %then %do;
1 
%end;
%else
%if (&type eq INT) %then %do;
   %let int=%sysfunc(int(&num),32.);
   %put INT =#&int#;
   %let rtn=%eval(&int eq &num);
&rtn
%end;
%else
%if (&type eq NONNEG) %then %do;
   %let rtn=%sysevalf(&num ge 0);
&rtn
%end;
%else
%if (&type eq POS) %then %do;
   %let rtn=%sysevalf(&num gt 0);
&rtn
%end;

%quit:

%mend;

/******* END OF FILE *******/
