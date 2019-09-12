/*====================================================================
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

======================================================================

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

+===================================================================*/

/*--------------------------------------------------------------------
Usage:

%optsave;
   Saves current options settings to default dataset work.options

%optsave(out=sasuser.myoptions);
   Saves current options to dataset sasuser.myoptions

----------------------------------------------------------------------
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

--------------------------------------------------------------------*/

%macro optsave
/*--------------------------------------------------------------------
Defines a hash object for later lookup
--------------------------------------------------------------------*/
(OUT=options   /* Output dataset to contain current options (REQ).  */
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
