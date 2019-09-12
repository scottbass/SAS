/*====================================================================
Program Name            : dedup_string.sas
Purpose                 : Removes duplicate items from a string
SAS Version             : SAS 9.2
Input Data              : Data step string containing duplicate tokens
Output Data             : Data step string with duplicates removed

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 29AUG2011
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

====================================================================*/

/*--------------------------------------------------------------------
Usage:

data _null_;
  oldstring="C A B B A G E 3 2 1 1 2 3";
  %dedup_string(invar=oldstring, outvar=newstring);
  %* dedup_string(invar=oldstring);
  put oldstring=;
  put newstring=;
run;

Dedups the input string oldstring, returning "C A B G E 3 2 1"

The first invocation creates a new variable, the second invocation
dedups the old variable in place.

======================================================================

data _null_;
  length oldstring newstring $200;
  oldstring="C|A|B|B|A|G|E|3|2|1|1|2|3";
  %* dedup_string(invar=oldstring, outvar=newstring, dlm=|);
  %dedup_string(invar=oldstring, dlm=|);
  put oldstring=;
  put newstring=;
run;

Same as above but using a different tokenization delimiter.

----------------------------------------------------------------------
Notes:

This macro must be called from within a data step.

--------------------------------------------------------------------*/

%macro dedup_string
/*--------------------------------------------------------------------
Removes duplicate items from a string using hash objects
--------------------------------------------------------------------*/
(INVAR=        /* Input variable name (REQ).                        */
,OUTVAR=       /* Output variable name (Opt).                       */
,DLM=          /* Delimiter marking each token in the input string  */
               /* (Opt).  If not specified, a space will be used.   */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(INVAR,        _req=1,_words=0,_case=N)
%parmv(OUTVAR,       _req=0,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* if OUTVAR was not specified set it to invar ;
%if (&outvar eq ) %then %let outvar=&invar;

%* if DLM was not specified set it to a space ;
%if (%superq(dlm) eq ) %then %let dlm=%str( );

length __word $200 __temp $32767;

%* if outvar ne invar define length of outvar via assignment statement ;
%* the data in outvar can never be longer than invar, only shorter ;
%if (&outvar ne &invar) %then %do;
  if 0 then &outvar=&invar;
%end;

%* need to use a temporary variable when updating in place ;
__temp=&invar;
call missing(&outvar);

%* process the input string, comparing current token with tokens already in output string ;
do __i = 1 by 1;
  __word=scan(__temp,__i,' ');
  if missing(__word) then leave;
  if indexw(upcase(&outvar),upcase(__word)) eq 0 then &outvar=catx(' ',&outvar,__word);
end;

drop __temp __word __i;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
