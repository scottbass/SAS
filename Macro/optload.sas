/*====================================================================
Program Name            : optload.sas
Purpose                 : Loads SAS options for an options dataset
SAS Version             : SAS 9.1.3
Input Data              : SAS options dataset
Output Data             : None

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

%optload;
   Restores options settings from the default work.options dataset.

%optload(data=sasuser.myoptions);
   Restores options settings from the sasuser.myoptions dataset.

----------------------------------------------------------------------
Notes:

This is just a "wrapper macro" around PROC OPTLOAD.

PROC OPTLOAD allows both out= and key= options, but I don't like the
key= option, as it is difficult to remove the key from the sasuser
registry.  So I have only implemented the out= option.

An error check is done to check if the data= dataset exists, but no
further error checking is done, for example feeding an improperly
formatted dataset to PROC OPTLOAD.

Typically %optsave and %optload would be used at the beginning
and end of a program respectively, to save and restore the SAS
options to their original values.

--------------------------------------------------------------------*/

%macro optload
/*--------------------------------------------------------------------
Loads SAS options for an options dataset
--------------------------------------------------------------------*/
(DATA=options  /* Source dataset to contain desired options (REQ).  */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0,_case=U)

%* check if the dataset exists ;
%if (^%sysfunc(exist(&data))) %then
%parmv(_msg=&data dataset does not exist);

%if (&parmerr) %then %goto quit;

%* restore SAS system options from the options dataset,
%* see documentation for PROC OPTLOAD for more details ;
proc optload data=&data;
run;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
