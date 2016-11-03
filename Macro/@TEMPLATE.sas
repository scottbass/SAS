/*=====================================================================
Program Name            : TEMPLATE.sas
Purpose                 : PURPOSE OF THE MACRO
SAS Version             : SAS VERSION WHEN THE MACRO WAS ORIGINALLY WRITTEN
Input Data              : N/A
Output Data             : N/A

Macros Called           : LIST ANY UTILITY MACROS CALLED BY THIS MACRO
                          SO THEY CAN BE ADDED TO THE SASAUTOS LIBRARY AS WELL

Originally Written by   : YOUR FULL NAME (NOT INITIALS - MAKE IT EASY TO FIND YOU LATER)
Date                    : TODAYs DATE IN DDMONYYYY FORMAT (INTERNATIONLALLY UNAMBIGUOUS DATE FORMAT)
Program Version #       : 1.0

=======================================================================

Copyright (c) 2016 Scott Bass

https://github.com/scottbass/SAS/tree/master/Macro

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=======================================================================

Modification History    : Original version

Programmer              : YOUR FULL NAME
Date                    : DDMONYYYY
Change/reason           : SUMMARY OF CODE CHANGE.
                          ADD COMMENTS IN THE CODE ITSELF
                          (INCLUDING NAME AND DATE) FOR ADDITIONAL DETAILS)
Program Version #       : 1.1

Programmer              : YOUR FULL NAME
Date                    : DDMONYYYY
Change/reason           : SUMMARY OF CODE CHANGE.
                          ADD COMMENTS IN THE CODE ITSELF
                          (INCLUDING NAME AND DATE) FOR ADDITIONAL DETAILS)
Program Version #       : 1.2

VERSION 1.0 (ORIGINAL VERSION):
   LEAVE "Original version" TEXT IN PLACE
   DELETE REVISION HISTORY

VERSION 1.1+ (MODIFIED VERSION):
   DELETE THE "Original version" TEXT
   ADD THE REVISION HISTORY PER ABOVE TEMPLATE

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

LIST MACRO USE CASE / UNIT TESTS HERE
TRY TO USE UNIVERSALLY AVAILABLE SOURCE DATA IF POSSIBLE
(EG. SASHELP DATASETS, C:\WINDOWS, /USR/LOCAL, ETC.)
OR ELSE CREATE SIMPLE TEST DATA INLINE
SO THE END USER CAN RUN THE USE CASE WITHOUT FURTHER SETUP OR EFFORT.
IDEALLY THE TEST CASES RUN BY HIGHLIGHTING THE TEXT IN THE SAS EDITOR
AND HITTING F3

=======================================================================

ADDITIONAL USE CASE

=======================================================================

ADDITIONAL USE CASE

-----------------------------------------------------------------------
Notes:

EXPLANATORY NOTES HERE, THAT EXPLAIN DESIGN DECISIONS OR
GENERAL USAGE INFORMATION.

THESE ARE NOTES THAT GO BEYOND COMMENTS WITHIN THE MACRO CODE.

---------------------------------------------------------------------*/

%macro TEMPLATE
/*---------------------------------------------------------------------
PURPOSE OF THE MACRO (REDUNDANT BUT NICE TO HAVE HERE AS WELL)
---------------------------------------------------------------------*/
(PARM1         /* PARM1 EXPLANATION (REQ).                           */
,PARM2=default /* PARM2 EXPLANATION (Opt).  Default is "default"     */
);

%local macro parmerr _data_;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(PARM1,        _req=1,_words=1,_case=N)  /* words allows ds options */
%parmv(PARM2,        _req=0,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* additional error checking ;
%if (&parm1 eq FOO and %superq(parm2) eq BAR) %then %do;
   %parmv(_msg=These two values are mutually exclusive)
   %goto %quit;
%end;

%* well commented macro code goes here ;

%* Use %* or /* */ comment style for comments that do not show in MPRINT output ;
%* Use * comment style for comments that show in MPRINT output ;

%quit:

%mend;

/******* END OF FILE *******/
