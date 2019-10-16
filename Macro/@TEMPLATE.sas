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
