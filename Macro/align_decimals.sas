/*=====================================================================
Program Name            : align_decimals.sas
Purpose                 : Aligns the decimal points of numeric or
                          character variables, optionally adding
                          additional bracketing characters
                          (usually parentheses).
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 09OCT2010
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

* create test dataset ;
data test;
   length num1 num2 8 chr1 chr2 $9 maxdec 8;
   input num1 num2 chr1 chr2 maxdec;
   datalines;
1              1           1           1              4
2.2            2.2         2.2         2.2            4
33.3           33.3        33.3        33.3           4
4.44           4.44        4.44        BAD            4
555.55         555.55      555.55      555.55         4
66.666         66.666      66.666      66.666         4
7777.77        7777.77     7777.77     7777.77        4
8888.888       8888.888    8888.888    BAD            4
9999.9999      9999.9999   9999.9999   9999.9999      4
;
run;

* align decimals for single numeric column ;
data aligned;
   set test;
   %align_decimals(var=num1,width=11,decpos=4);
run;
proc print;run;

* >>> creates output variable col_num1 as "(xxxx.xxxx)" (default) ;

=======================================================================

* align decimals for multiple numeric columns ;
data aligned;
   set test;
   %align_decimals(var=num1 num2,width=11,decpos=4);
run;
proc print;run;

* >>> creates output variables col_num1 col_num2 as "(xxxx.xxxx)" ;

=======================================================================

* align decimals for multiple character columns ;
data aligned;
   set test;
   %align_decimals(var=chr1 chr2,width=11,decpos=4,type=C);
run;
proc print;run;

* >>> create output variables col_chr1 col_chr2 as "(xxxx.xxxx)" ;

=======================================================================

* align decimals for multiple variables using multiple invocations ;
data aligned;
   set test;
   %align_decimals(var=num1 num2,width=13,decpos=4);
   %align_decimals(var=chr1 chr2,width=13,decpos=-4,type=C);
run;
proc print;run;

* >>> create output variables col_num1 col_num2 as "(xxxx.xxxx  )" ;
* >>> create output variables col_chr1 col_chr2 as "( xxxx.xxxx )" ;

=======================================================================

* align decimals using an input variable list ;
* if an input variable list is used, then out must be specified ;
* an output variable list (numeric suffix) can be used ;
data aligned;
   set test;
   %align_decimals(var=num1 -- num2,out=var1-var2,width=11,decpos=4);
run;
proc print;run;

* >>> create output variables var1 - var2 as "(xxxx.xxxx)" ;

=======================================================================

* specify explicit output variable names ;
* there must be a one to one match of input to output variable names ;
* based on position, although output variable lists are allowed ;
data aligned;
   set test;
   %align_decimals(var=chr1-chr2,out=var_a var_b,width=11,decpos=4,type=c);
run;
proc print;run;

* >>> create output variables var_a var_b as "(xxxx.xxxx)" ;

=======================================================================

* specify output variable prefix ;
data aligned;
   set test;
   %align_decimals(var=num1,width=11,decpos=4,prefix=myvar_);
run;
proc print;run;

* >>> create output variables myvar_num1 as "(xxxx.xxxx)" ;

=======================================================================

* specify numerically suffixed output variables ;
* if suffix=# then input variable name (num1, num2) are not part ;
* of the output variable name ;
* Note:  an output variable list might be just as easy, but with the below approach ;
* you do not need to know the actual number of variables in the input or output list ;
data aligned;
   set test;
   %align_decimals(var=num1-numeric-num2,width=11,decpos=4,prefix=somevar,suffix=#);
run;
proc print;run;

* >>> create output variables somevar1 somevar2 as "(xxxx.xxxx)" ;

=======================================================================

* right justify output (note increased width and negative decpos) ;
data aligned;
   set test;
   %align_decimals(var=num2,width=14,decpos=-4);
run;
proc print;run;

* >>> create output variable col_num2 as "(  xxxx.xxxx)" ;

=======================================================================

* same as above, using a maxdec variable in the source dataset ;
data aligned;
   set test;
   %align_decimals(var=num2,width=14,decpos=-maxdec);
run;
proc print;run;

* >>> create output variable col_num2 as "(  xxxx.xxxx)" ;

=======================================================================

* align decimals with additional bracketing characters ;
data aligned;
   set test;
   %align_decimals(var=num1 num2,width=14,decpos=5,lc={,rc=}*);
run;
proc print;run;

* >>> create output variables col_num1 col_num2 as "{ xxxx.xxxx }*" ;

=======================================================================

* align decimals with no additional bracketing characters ;
data aligned;
   format col_num1 col_num2;
   set test;
   %align_decimals(var=num1,width=18,decpos=4,lc=,rc=);
   %align_decimals(var=num2,width=18,decpos=-4,lc=,rc=);
   file print;
   put @1 "*" col_num1 $char18. +(-1) "#" @25 "*" col_num2 $char18. +(-1) "#";
run;

* >>> create output variables col_num1 col_num2 as ;
* "xxxx.xxxx     " (left justified) and ;
* "     xxxx.xxxx" (right justified) ;

=======================================================================

* error conditions ;
* left width too small ;
data aligned;
   set test;
   %align_decimals(var=num1,width=11,decpos=3);
run;
proc print;run;

=======================================================================

* right width too small ;
data aligned;
   set test;
   %align_decimals(var=num1,width=11,decpos=-3);
run;
proc print;run;

=======================================================================

* overall width too small ;
data aligned;
   set test;
   %align_decimals(var=num1,width=9,decpos=4);
run;
proc print;run;

=======================================================================

* different number of input and output variables ;
data aligned;
   set test;
   %align_decimals(var=num1-num2,out=col_num1,width=11,decpos=4);
run;
proc print;run;

-----------------------------------------------------------------------
Notes:

When aligning decimal points within a character output variable, the
two constants are the width of the output variable, and the position of
the decimal point.  By evaluating the length of the integer portion
(for left justification) and decimal portion (for right justification)
of the input number, pointers can be derived to determine the start
position of the numeric data within the output string.

In general, set the WIDTH parameter to the column width of your output
(usually a PROC REPORT column).  Set the DECPOS parameter to the
maximum length of either the integer portion (positive DECPOS) or
decimal portion (negative DECPOS) of the number.  Use a positive number
to left justify the output within the output WIDTH, and use a negative
number to right justify the output within the output WIDTH. Increase
the DECPOS parameter if you want additional spacing after or before
your bracketing characters (usually parentheses).

If the maximum decimal length has been pre-calculated (eg. via the
%max_decimals macro), and exists as a variable in the source dataset,
then that variable can be specified as the DECPOS parameter.

If the input variable(s) are a character representation of numeric
data, they are first validated as numeric data before being processed.
Invalid numeric data will be displayed as missing data.

Be aware that, as part of this validation process, the data step
error flag variable _ERROR_ is reset to 0.  Therefore, this macro
should be called early in the data step if you wish to trap later
downstream errors.

Because this macro uses data step arrays to process multiple input
variables, the VAR parameter must contain variables of a single data
type (numeric or character).  If both numeric and character data need
to be processed, invoke this macro twice.

By default this macro uses the LC ("left character" and RC ("right
character) parameters to bracket the aligned numeric data with left and
right parentheses.  Use the LC and RC parameters to change the
bracketing characters, including none at all.

The WIDTH parameter must be the TOTAL width of the output column,
including bracketing characters.  For example, if your maximum input
data is 4 characters integer and 4 characters decimal (eg. 1234.5678),
then your WIDTH should be a minimum of 11
(4 integers + 4 decimals + 1 (decimal point) + 2 (bracketing characters)).

If the numeric data cannot fit into the output column without
overwriting either of the bracketing characters, then a message is
written to the log and the output column is "blank" (bracketing
characters only).

---------------------------------------------------------------------*/

%macro align_decimals
/*---------------------------------------------------------------------
Aligns the decimal points of numeric or character variables.
---------------------------------------------------------------------*/
(VAR=          /* Input variable(s) (REQ).                           */
,OUT=          /* Output variables (Opt).                            */
               /* If blank, the ouput variables are named as         */
               /* &PREFIX.&VAR1.&SUFFIX, &PREFIX.&VAR2.&SUFFIX, etc. */
,WIDTH=        /* Total output variable width (including any         */
               /* bracketing characters) (REQ).                      */
,DECPOS=       /* Decimal position within the total output variable  */
               /* width (REQ).                                       */
               /* Must be a positive or negative integer,            */
               /* or an existing variable in the source dataset that */
               /* is a positive or negative integer.                 */
,TYPE=N        /* Input variable(s) type (REQ).                      */
               /* Default is N.  Valid values are N or C.            */
               /* All input variables must be the same data type.    */
,PREFIX=col_   /* Output variable name prefix (Opt).                 */
               /* Default is col_.                                   */
               /* If missing then OUT= must be specified.            */
,SUFFIX=       /* Output variable name suffix (Opt).                 */
               /* If blank, the suffix is &VAR1, &VAR2, etc., where  */
               /* &VAR1, &VAR2, etc is each word in &VAR.            */
               /* Specify "#" to use a numeric counter suffix.       */
,LC=%str(%()   /* Left bracketing character (Opt).                   */
               /* Default is "(".                                    */
,RC=%str(%))   /* Right bracketing character (Opt).                  */
               /* Default is ")".                                    */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(VAR,          _req=1,_words=1,_case=N)
%parmv(WIDTH,        _req=1,_words=0,_case=N,_val=POSITIVE)
%parmv(DECPOS,       _req=1,_words=0,_case=N)
%parmv(TYPE,         _req=1,_words=0,_case=U,_val=N C)

%if (&parmerr) %then %goto quit;

%* additional error checking ;
%* if PREFIX and SUFFIX are blank then OUT must be specified ;
%* (otherwise the output variable name would equal the input variable name) ;
%if (%superq(prefix) eq ) and (%superq(suffix) eq ) %then %if (%superq(out) eq ) %then %do;
   %parmv(_msg=If PREFIX and SUFFIX are both blank then OUT must be specified)
   %goto quit;
%end;

%* if an input variable list is specified then OUT must be specified ;
%if (%index(%superq(var),%str(-_))) %then %if (%superq(out) eq ) %then %do;
   %parmv(_msg=If an input variable list is specified then OUT must be specified)
   %goto quit;
%end;

%* if OUT is blank then need to build the output variable list from VAR, PREFIX, and SUFFIX ;
%* if SUFFIX = # then use a numeric suffix ;
%if (%superq(suffix) eq %str(#)) %then
   %let num_suffix=1;
%else
   %let num_suffix=0;

%if (%superq(out) eq ) %then %do;
   %let i=1;
   %let word=%qscan(%superq(var),&i,%str( ));
   %do %while (%superq(word) ne );
      %if (&num_suffix) %then %do;
         %let word=%str();
         %let suffix=&i;
      %end;
      %let out=%superq(out)%superq(prefix)%superq(word)%superq(suffix)%str( );

      %let i=%eval(&i+1);
      %let word=%qscan(%superq(var),&i,%str( ));
   %end;
%end;
%let out=%unquote(&out);

%* since this macro supports multiple invocations within a single datastep, ;
%* we need to uniquely declare variable arrays or there will be a naming collision ;
%* rather than trying to keep track of macro invocations, ;
%* just create a (hopefully) unique random number ;
%let rand=%sysfunc(ranuni(0));
%let rand=%sysevalf(&rand*10000);
%let rand=%sysfunc(int(&rand));

%* now code the logic of this macro ;
array _var&rand._ {*} &var;
array _out&rand._ {*} $&width &out;

%* if the array dimensions are not the same, print an error and stop ;
if (dim(_out&rand._) ne dim(_var&rand._)) then do;
   putlog "ERR" "OR: The number of output variables does not equal the number of input variables.";
   stop;
end;

length _str&rand._ _num&rand._ $&width _width_ _decpos_ _intlen_ _declen_ _start_ _length_ 8;

_width_=&width;
_str&rand._="&lc"||putc("",cats("$",_width_-lengthn("&lc")-lengthn("&rc")))||"&rc";

do _i_=1 to dim(_var&rand._);
   %* if the input variable type is numeric, convert to character ;
   %* if the input variable type is character, validate as a number ;
   %if (&type eq N) %then %do;
      _num&rand._=put(_var&rand._{_i_},best32.-L);
   %end;
   %else %do;
      _num&rand._=put(input(_var&rand._{_i_},? best.),best.-L);
      if (_ERROR_) then do;
         putlog "ERR" "OR: " _var&rand._{_i_} "is not valid numeric data.  " _n_=;
         _ERROR_=0;  /* reset error flag */
      end;
      /* comment the above lines and uncomment the below line */
      /* if you do not want to validate the input character data as numeric */
      /* _num&rand._=strip(_var&rand._{_i_}); */
   %end;

   %* get the length of the integer and decimal portions ;
   _intlen_=lengthn(strip(scan(_num&rand._,1,".")));
   _declen_=lengthn(strip(scan(_num&rand._,2,".")));

   %* derive decimal position ;
   _decpos_=&decpos;

   if (_decpos_ lt 0) then
      _decpos_=_width_+(_decpos_)-lengthn("&rc");
   else
      _decpos_=_decpos_+1+lengthn("&lc");

   _out&rand._{_i_}=_str&rand._;
   _start_=_decpos_-_intlen_;
   _length_=length(_num&rand._);
   if (_start_ ge 1+lengthn("&lc")) and (_start_+_length_-1 le _width_-lengthn("&rc")) then
      substr(_out&rand._{_i_},_start_,_length_)=strip(_num&rand._);
   else
      putlog "ERR" "OR: " _num&rand._ "cannot fit within WIDTH=&width and DECPOS=&decpos..";

   drop _str&rand._ _num&rand._ _width_ _decpos_ _intlen_ _declen_ _start_ _length_ _i_;
end;

%* end of macro logic ;

%quit:

%mend;

/******* END OF FILE *******/
