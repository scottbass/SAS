/*=====================================================================
Program Name            : IsNumD.sas
Purpose                 : Checks if alphanumeric (character) input is
                          valid numeric data (data step).
                          Also sets additional flag variables for
                          IsInt, IsFloat, IsNonNeg, IsPos, etc.
SAS Version             : SAS 9.3
Input Data              : Character data in a data step
Output Data             : Flag variables:
                          _IsNum
                          _IsNum2
                          _IsInt
                          _IsFloat
                          _IsNonNeg
                          _IsPos

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

data have;
   length char $32;
   input char $char32.;
   datalines;

.
._
.A
.Z
-1
0
1
1.1
 123456789012.123456789012
-123456789012.123456789012
 1234567890123.1234567890123
-1234567890123.1234567890123
 12345678901234.12345678901234
-12345678901234.12345678901234
 123456789012345.123456789012345
-123456789012345.123456789012345
 1234567890123456.1234567890123456
-1234567890123456.1234567890123456
 1.1
 -123
 -123.45
 --123.45
A
 B
123 456
123-456
~!@#$%^&*()_+=
;
run;

data want;
   set have;
   %IsNum(char);
run;

-----------------------------------------------------------------------
Notes:

_IsNum:    Returns 1 if character input is valid numeric input,
           excluding blank, missing, or special missing values.

_IsNum2:   Returns 1 if character input is valid numeric input,
           including blank, missing, or special missing values.

_IsInt:    Returns 1 if character input is valid numeric input,
           and is also integer input.

_IsFloat:  Returns 1 if character input is valid numeric input,
           and is also floating point input.

_IsNonNeg: Returns 1 if character input is valid numeric input,
           and is also non-negative input (>= 0).

_IsPos:    Returns 1 if character input is valid numeric input,
           and is also positive input (> 0).

Note that the check for IsInt and IsFloat collapses for large numbers,
where precision is lost and the difference between
num and int(num) becomes 0 [num-int(num)=0].

On my machine, this happens around 1E15, or 15 significant digits.

This code must be called within a data step.  It creates the above
flag variables; it is up to the calling program to process those
flag variables as desired, including dropping those flag variables
from the output dataset if desired.

To easily drop these flag variables, the statement:
drop _Is:;
can be used, assuming no other variables use this prefix.

The input dataset should not have these variable names or data
collisions will result.

---------------------------------------------------------------------*/

%macro IsNumD
/*---------------------------------------------------------------------
Checks if alphanumeric (character) input is valid numeric data.
---------------------------------------------------------------------*/
(CHAR          /* Character variable to check (REQ).                 */
);

%local macro parmerr _data_;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(CHAR,_req=1,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

__num__ = input(&char,?? best32.);
if (not missing(__num__)) then do;
   IsNum    = 1;
   IsNum2   = 1;
   IsInt    = (int(__num__) = __num__);
   IsFloat  = (abs(__num__ - int(__num__)) gt 0);
   IsNotNeg = (__num__ ge 0);
   IsPos    = (__num__ gt 0);
end;
else do;
   IsNum    = 0;
   IsNum2   = (strip(&char) in ('','.') or (.A le __num__ le .Z) or (__num__ = ._));
   IsInt    = 0;
   IsFloat  = 0;
   IsNotNeg = 0;
   IsPos    = 0;
end;
drop __num__;

%quit:

%mend;

/******* END OF FILE *******/
