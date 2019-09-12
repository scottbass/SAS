/*=====================================================================
Program Name            : justify.sas
Purpose                 : Creates a macro variable with text left,
                          center, and right justified within a given
                          width (usually the linesize).
                          (pure macro solution)
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 05SEP2010
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

options ls=80;

* basic tests ;
%let string=%justify(left=Left,center=Center,right=Right);
%put %length(&string) *&string*;

%let string=%justify(left=Left);
%put %length(&string) *&string*;

%let string=%justify(center=Center);
%put %length(&string) *%str(&string)*;

%let string=%justify(right=Right);
%put %length(&string) *&string*;

%let string=%justify(left=Left,right=Right);
%put %length(&string) *&string*;

=======================================================================

* without trimming result ;
* all string lengths should be 80 ;
%let string=%justify(left=Left,center=Center,right=Right,trim=N);
%put %length(&string) *&string*;

%let string=%justify(left=Left,trim=N);
%put %length(&string) *&string*;

%let string=%justify(center=Center,trim=N);
%put %length(&string) *&string*;

%let string=%justify(right=Right,trim=N);
%put %length(&string) *&string*;

%let string=%justify(left=Left,right=Right,trim=N);
%put %length(&string) *&string*;

=======================================================================

* more realistic use cases ;
options nonumber nodate ls=80;

%let string=%justify(left=Left,center=Center,right=Right);
%put &string;

title2 "&string";
footnote;
proc print data=sashelp.shoes (obs=10) noobs;
run;

   Creates the macro variable &string with the text
   "Left   Center   Right" justified as left/center/right respectively
   within the current linesize.

=======================================================================

title;
footnote;

%let string=%justify(
   left=Prepared by: &sysuserid
   ,right=Date: %qleft(%qsysfunc(date(),weekdatx.))
   ,width=75
);
%put &string;

footnote "%unquote(&string)";
proc print data=sashelp.shoes (obs=10) noobs;
run;

   Creates the footnote with the text
   "Prepared by: <userid>   Date: <current date>"
   justified as left/right respectively within a line length of 75.

=======================================================================

%let string=%justify(
   left=This is a long string that is left justified
   ,center=This is a long string that is centered
   ,right=This is a long string that is right justified
   ,width=80
);
%put &string;

   This will return an error string since the combined lengths of the
   input parameters is greater than the specified linesize.

=======================================================================

data _null_;
   file print;
   string="%justify(left=Page 1,center=Acme Pharmaceuticals,right=&sysdate9)";
   put string;
run;

   Prints the string "Page 1   Acme Pharmaceuticals   <current date>"
   justified as left/center/right respectively within the current
   linesize.

   Of course, in a data step, there are probably easier ways of doing this.

-----------------------------------------------------------------------
Notes:

This is a "pure macro" solution so it must be called as an rvalue, i.e.
on the right hand side of an equals sign or in the context of a
function call.

If the combined text is greater than the width specification
(default is the current linesize) then a warning is written to the
log and error text is returned.

Because of all the leading spaces, the returned value is returned QUOTED.
Depending on the context of the calling program, the returned value
may need to be unquoted.

Compare the results:

%put *%justify(center=Center)*;
%let string=%justify(center=Center);
%put *&string*;
%let string=%unquote(&string);
%put *&string*; * is now left justified due to the unquoted assignment statement ;
                * of course, in some cases that could be just what you want ;

%put *%unquote(%justify(center=Center))*;  * does not work ;

---------------------------------------------------------------------*/

%macro justify
/*---------------------------------------------------------------------
Creates a macro variable of left/center/right justified text.
---------------------------------------------------------------------*/
(LEFT=         /* Left justified text (Opt.)                         */
,CENTER=       /* Center justified text (Opt.)                       */
,RIGHT=        /* Right justified text (Opt.)                        */
,WIDTH=        /* Explicit width (Opt).                              */
               /* If blank the current linesize option is used.      */
,TRIM=Y        /* Trim the returned string (Opt.)                    */
               /* If Y, the returned string is trimmed.              */
               /* If N, the returned string is padded with trailing  */
               /* spaces, with the returned string length equal to   */
               /* the specified linesize.                            */
);

%local macro parmerr string start_l start_c start_r;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(LEFT,         _req=0,_words=1,_case=N)
%parmv(CENTER,       _req=0,_words=1,_case=N)
%parmv(RIGHT,        _req=0,_words=1,_case=N)
%parmv(WIDTH,        _req=0,_words=0,_val=POSITIVE)
%parmv(TRIM,         _req=0,_words=0,_val=0 1)

%if (&parmerr) %then %goto quit;

%* if width is blank then use the current linesize option ;
%if (&width eq ) %then %let width=%sysfunc(getoption(linesize));

%* check if the combined length of the strings is greater than the width ;
%if (%eval(%length(&left&center&right) gt &width)) %then %do;
   %put %str(WAR)NING:  The combined lengths of the input parameters is greater than &width..;
   %let string=%str(*** ERROR IN &SYSMACRONAME PARAMETERS ***);
%end;
%else %do;
   %* unfortunately, SAS format modifiers do not work in the sysfunc/qsysfunc functions ;
   %* so, we have to roll our own justification algorithms ;
   %let start_l=0;
   %let start_c=0;
   %let start_r=0;

   %if %length(&left)   %then %let start_l=1;
   %if %length(&center) %then %let start_c=%eval((&width - %length(&center)) / 2);
   %if %length(&right)  %then %let start_r=%eval((&width - %length(&right)));

   %* put &start_l &start_c &start_r;  %* for debugging ;

   %* fill the buffer from left to right, always ensuring the buffer is as long as the width ;
   %* otherwise, qsubstr will return out of range errors ;
   %if (&start_l) %then %let string=%superq(left);
   %let string=%qsysfunc(putc(%superq(string),$char&width..));

   %if (&start_c) %then %let string=%qsubstr(%superq(string),1,&start_c)%superq(center);
   %let string=%qsysfunc(putc(%superq(string),$char&width..));

   %if (&start_r) %then %let string=%qsubstr(%superq(string),1,&start_r)%superq(right);
   %let string=%qsysfunc(putc(%superq(string),$char&width..));

   %* if trim was specified, trim the final string ;
   %if (&trim) %then %let string=%qtrim(%superq(string));
%end;

%* NOTE: because of all the leading spaces, the string is returned QUOTED ;
%* Depending on the context of the calling program, the returned value may need to be unquoted ;
&string

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
