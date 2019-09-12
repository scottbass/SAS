/*====================================================================
Program Name            : dedup_mstring.sas
Purpose                 : Removes duplicate words from a 
                          macro variable string
SAS Version             : SAS 9.4
Input Data              : Macro variable string
Output Data             : r-value string with duplicates removed

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 02FEB2016
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

%let oldstring=C A B B A G E 3 2 1 1 2 3;
%put %dedup_mstring(&oldstring);

Dedups the input string oldstring, returning "C A B G E 3 2 1".
The default delimiter for a word is a space.

======================================================================

%let oldstring=C  A  B  B  A  G  E  3 2 1 1 2 3;
%let newstring=%dedup_mstring(&oldstring);
%put &=newstring;

Same as above, but assigns the result to &newstring.
Multiple input delimiters are replaced with a single output delimiter.

======================================================================

%let oldstring=%str(C, A, B, B, A, G, E, 3, 2, 1, 1, 2, 3);

* these examples do not work ;
%put %dedup_mstring(&oldstring,indlm=,);
%put %dedup_mstring(%quote(&oldstring),indlm=,); 

* these examples work ;
%put %dedup_mstring(%quote(&oldstring),indlm=%str(,)); 
%put %dedup_mstring(%bquote(&oldstring),indlm=%str(,)); 
%put %dedup_mstring(%nrbquote(&oldstring),indlm=%str(,)); 
%put %dedup_mstring(%superq(oldstring),indlm=%str(,)); 

* this is what you need to output a space as the output delimiter ;
%put %dedup_mstring(%superq(oldstring),indlm=%str(,),dlm=);            * uses the input delimiter ;
%put %dedup_mstring(%superq(oldstring),indlm=%str(,),dlm=%str());      * uses the input delimiter ;
%put %dedup_mstring(%superq(oldstring),indlm=%str(,),dlm=%str( ));     * space ;
%put %dedup_mstring(%superq(oldstring),indlm=%str(,),dlm=%str(  ));    * two spaces ;
%put %dedup_mstring(%superq(oldstring),indlm=%str(,),dlm=%str( | ));   * space | space ;

Commas are common in macro variable strings, but are problematic
for the macro tokenizer.  Macro quoting functions must be used on the
macro invocation to get the desired results.

======================================================================

%let oldstring=C^A^B^B^A#G#E#3|2|1*1*2*3;

* output delimter is a space ;
%put %dedup_mstring(&oldstring,indlm=^#|*);  

* output delimter is a comma ;
%let newstring=%dedup_mstring(&oldstring,indlm=^#|*,dlm=%str(,));  
%put &=newstring;

Multiple delimiters may be specified for the input string to delimit 
words, but only one delimiter can be specified for the output string. 
(This is a rare use case.)

======================================================================

%let oldstring='PERSON', "ORGANISATION",AND,OR,NOT, 'PERSON', 'ORGANISATION';
%let newstring=%dedup_mstring(%quote(&oldstring),indlm=%str(,));
%put &=newstring;

Example of a complex string, including macro keywords.

For quoted strings, the quoting must be matched (start and end quotes)
and the same type (single or double quotes).

For the purposes of this macro, all characters other than the delimiter
are significant and used to determine whether a duplicate occurs

----------------------------------------------------------------------
Notes:

This macro returns an r-value, so the results are usually assigned to
another macro variable or else used inline.  The returned r-value is 
macro unquoted.

This macro is a "pure macro" implementation and runs to completion 
during program compilation.

An input delimiter is required to indicate what determines a "word".

The default input and output delimter is a space.

If the output delimiter is not specified:
   If the length of the input delimiter = 1, the input delimiter 
      will be used for the output string.
   If the length of the input delimiter > 1, a space 
      will be used for the output string.
   
If the output delimiter is specified, it will always be used.

--------------------------------------------------------------------*/

%macro dedup_mstring
/*--------------------------------------------------------------------
Removes duplicate words from a macro variable string
--------------------------------------------------------------------*/
(IN            /* Input string (REQ).                               */
,INDLM=        /* Input delimiter marking each token (word) in the  */
               /* input string (Opt).                               */
               /* If not specified, a space will be used.           */
,DLM=          /* Output delimiter marking each token (word) in the */
               /* output string (Opt).                              */
               /* If not specified:                                 */
               /*    If the length of INDLM = 1, set to INDLM       */
               /*    If the length of INDLM > 1, set to space       */
);

%local macro parmerr i out;
%let macro = &sysmacroname;
%let out   = ;

%* check input parameters ;
%parmv(IN,           _req=1,_words=1,_case=N)

%if (&parmerr) %then %goto quit;

%* if the input INDLM was not specified set it to a space ;
%if (%length(%superq(indlm)) eq 0) %then %let indlm=%str( );

%* if the output DLM was not specified: ;
%*    if the length of INDLM = 1, set DLM = INDLM ;
%*    if the length of INDLM > 1, set DLM to a space. ;
%if (%length(%superq(dlm)) eq 0) %then %do;
   %if (%length(%superq(indlm)) eq 1) %then
      %let dlm = %superq(indlm);
   %else
   %if (%length(%superq(indlm)) gt 1) %then
      %let dlm = %str( );
%end;
   
%* loop over each token, searching the target for that token ;
%let num=%sysfunc(countc(%superq(in),%str(&indlm)));
%let num=%eval(&num+1);
%do i=1 %to &num;
   %let word=%scan(%superq(in),&i,%str(&indlm));
   %let pos=%sysfunc(indexw(&out,&word,%str(&dlm)));
   %if (&pos eq 0) %then %do;
      %if (&i gt 1) %then %let out=&out%str(&dlm);
      %let out=&out&word;
   %end;
%end;
%unquote(&out)

%quit:

%mend;

/******* END OF FILE *******/
