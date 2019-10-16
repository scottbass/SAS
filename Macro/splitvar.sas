/*=====================================================================
Program Name            : splitvar.sas
Purpose                 : In-datastep macro to insert split characters
                          in a string variable.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 11FEB2011
Program Version #       : 1.1

=======================================================================

Scott Bass (sas_l_739@yahoo.com.au)

This code is licensed under the Unlicense license.
For more information, please refer to http://unlicense.org/UNLICENSE.

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

Based on original work by Roland Rashleigh-Berry.
http://www.datasavantconsulting.com/roland/splitvar.sas
Used with permission.

=======================================================================

Modification History    :



Programmer              : Scott Bass
Date                    : 28MAR2011
Change/reason           : Detect when splits have already been put into
                          lines, and add addional ones.
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

options ls=65;
%let options=%sysfunc(getoption(ls,keyword)) %sysfunc(getoption(center,keyword));

data source;
   length string $600 line1 line2 line3 $200;
   infile datalines truncover;
   input line1 $char200. / line2 $char200. / line3 $char200.;
   string=catt(of line:);
   drop line:;
   datalines;
This is a long string that is much longer than the current
 linesize.  We want to insert a split character when we encounter
 a space or a hyphen that is near the end of the line.
;
run;

data report;
   set source;
   %splitvar(string,%sysfunc(getoption(ls)),outvar=newstr1,split=~);
   %splitvar(string,%sysfunc(getoption(ls)),outvar=newstr2,split=~,hanging_indent=5);
   %splitvar(string,40,outvar=newstr3,split=~);
run;

options ls=max nocenter;

proc print data=report;
run;

proc report data=report missing nowd headline headskip split="~" ls=80 spacing=2;
   column string newstr1 newstr2 newstr3 newstr3=newstr4;
   define string        / display width=65   flow;  * implicit flowing original string w/in linesize ;
   define newstr1       / display width=65   flow;  * explicit flowing new string w/in linesize ;
   define newstr2       / display width=70   flow spacing=2; * explicit flowing new string w/in linesize with hanging indent ;
   define newstr3       / display width=40   flow;  * width equal to explicit flow width ;
   define newstr4       / display width=30   flow;  * width smaller than explicit flow width for illustration ;
run;

options &options;

-----------------------------------------------------------------------
Notes:

A split character will normally be placed in a blank space. If there is
no suitable space then it will be inserted after a hyphen. But if there
is no suitable space and no hyphen then it will be inserted at the end.
You must ensure there is enough room to do this by ensuring the length
of the variable is greater than the length of any string.

This macro will only look back the floor of half the column width to
find a place to insert the split character.

If the outvar parameter is not specified, the input variable is
altered in place.

The default split character is ~.  The split character should not be
present in the input string.

No error checking is done to ensure the col parameter is less than the
current linesize.

Note that this is not a function-style macro. It must be used in a data
step as shown in the usage notes.

---------------------------------------------------------------------*/

%macro splitvar
/*---------------------------------------------------------------------
Macro to insert split characters in a string variable
---------------------------------------------------------------------*/
(VAR           /* Input variable name (REQ).                         */
               /* Only one variable may be specified.                */
,COLS          /* Column number at which splitting should occur (REQ)*/
,SPLIT=~       /* Split character (REQ).                             */
               /* Must be a single character.                        */
,OUTVAR=       /* Output variable name (Opt).                        */
               /* If not specified, the input variable is altered.   */
,HANGING_INDENT=0
               /* If a hanging indent is included, then this is      */
               /* added after every new split.                       */
);

%local macro parmerr drop rename hi;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(VAR,        _req=1,_words=0,_case=N)
%parmv(COLS,       _req=1,_words=1,_case=N)
%parmv(SPLIT,      _req=1,_words=0,_case=N)
%parmv(OUTVAR,     _req=0,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* additional error checking ;
%* the split character must be a single character ;
%let split=%sysfunc(dequote(&split));  %* dequotes a properly quoted split character ;
%if (%length(&split) ne 1) %then
   %parmv(_msg=Split character &split is not a single character);

%if (&parmerr) %then %goto quit;

%* if hanging indent was specified, create the hanging indent prefix ;
%if (&hanging_indent) %then %let hi=%qsysfunc(putc(,$&hanging_indent..));

%* if outvar parameter was specified, copy the input variable ;
%* to the output variable, and modify the output variable instead. ;
%if (&outvar ne ) %then %do;
   &outvar=&var;
   %let var=&outvar;
%end;

_pos=0;
do while(length(substr(&var,_pos+1))>&cols);

   *- if there is a delimiter within the line, then break there ;
   if (0<findc(&var,"&split",'ti',_pos+1)<_pos + &cols) then do;
      _pos=findc(&var,"&split",'ti',_pos+1)+1;
      _cols=1;
   end;

   else do _cols=(&cols) to floor(&cols/2) by -1;
      if substr(&var,_pos+_cols,1) EQ ' ' then do;
         &var=substr(&var,1,_pos+_cols-1)||
              "&split&hi"||
              left(substr(&var,_pos+_cols+1));
*         _pos=_pos+_cols+&hanging_indent+1;
         _pos=_pos+_cols+1;
         _cols=1;
      end;
   end;

   *- if space character not found look for a hyphen - ;
   if _cols>1 then do;
      do _cols=&cols to floor(&cols/2) by -1;
         if substr(substr(&var,_pos+1),_cols,1) EQ '-' then do;
            &var=substr(&var,1,_pos+_cols)||
                "&split&hi"||
                left(substr(&var,_pos+_cols+1));
*            _pos=_pos+_cols+&hanging_indent+1;
            _pos=_pos+_cols+1;
            _cols=1;
         end;
      end;
   end;

   *- if no hyphen found then split at end - ;
   if _cols>1 then do;
      &var=substr(&var,1,_pos+&cols)||
           "&split&hi"||
           left(substr(&var,_pos+&cols+1));
*      _pos=_pos+_cols+&hanging_indent+1;
      _pos=_pos+&cols+1;
   end;
end;

%* fix bug in PROC REPORT flow algorithm ;
%* the last line of a multi-line flowed column has a leading space truncated ;
%* see http://support.sas.com/kb/5/845.html ;
/*
%if (&hanging_indent) %then %do;
   * fix bug in PROC REPORT flow algorithm ;
   _pos=findc(&var,"&split",'ti',-9999);
   if _pos then &var=catt(&var,"&split");
%end;
*/

drop _pos _cols;

%quit:

%mend;

/******* END OF FILE *******/