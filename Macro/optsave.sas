/*=====================================================================
Program Name            : optsave.sas
Purpose                 : Saves current options settings to a SAS
                          dataset
SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : SAS options dataset

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 14MAY2010
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

+====================================================================*/

/*---------------------------------------------------------------------
Usage:

%optsave;
   Saves current options settings to default dataset work.options

%optsave(out=sasuser.myoptions);
   Saves current options to dataset sasuser.myoptions

-----------------------------------------------------------------------
Notes:

This is just a "wrapper macro" around PROC OPTSAVE.

PROC OPTSAVE allows both out= and key= options, but I don't like the
key= option, as it is difficult to remove the key from the sasuser
registry.  So I have only implemented the out= option.

No error checking is done, for example attempting to write output
dataset to readonly library.

Typically %optsave and %optload would be used at the beginning
and end of a program respectively, to save and restore the SAS
options to their original values.

---------------------------------------------------------------------*/

%macro optsave
/*---------------------------------------------------------------------
Defines a hash object for later lookup
---------------------------------------------------------------------*/
(OUT=options   /* Output dataset to contain current options (REQ).   */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(OUT,          _req=1,_words=0,_case=U)

%if (&parmerr) %then %goto quit;

%* save current SAS system options, ;
%* see documentation for PROC OPTSAVE for more details ;
proc optsave out=&out;
run;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
