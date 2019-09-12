/*=====================================================================
Program Name            : squote.sas
Purpose                 : Wrap the argument in single quotes
SAS Version             : SAS 9.3
Input Data              : Text or macro variable
Output Data             : Single quoted text or resolved macro variable


Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 28OCT2016
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

Based on original work by SAS Communities user "Tom".
https://communities.sas.com/t5/SAS-Communities-Library/Not-All-Macro-Language-Elements-Are-Supported-by-the-Macro/ta-p/223904
Used with permission.

=======================================================================

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

options symbolgen;

%put %squote();

=======================================================================

%put %squote(foo);

=======================================================================

%let mvar=bar;
%put %squote(&mvar);

=======================================================================

%let mvar='blah';
%put %squote(&mvar);

=======================================================================

* unbalanced quote testing ;
* first get a simple %put to work ;
* you may have to restart SAS a lot during this testing ;

* these do not work ;
%let mvar=P.J. O'Briens;            %put &=mvar;
%let mvar=%str(P.J. O'Briens);      %put &=mvar;
%let mvar=%nrstr(P.J. O'Briens);    %put &=mvar;
%let mvar=%quote(P.J. O'Briens);    %put &=mvar;

%let mvar=P.J. O'Briens;            %put %bquote(&mvar);
%let mvar=%str(P.J. O'Briens);      %put %bquote(&mvar);
%let mvar=%nrstr(P.J. O'Briens);    %put %bquote(&mvar);
%let mvar=%quote(P.J. O'Briens);    %put %bquote(&mvar);

* this works ;
%let mvar=%bquote(P.J. O'Briens);   %put &=mvar;
%let mvar=%bquote(P.J. O'Briens);   %put %bquote(&mvar);

* so, for %put to work, the unbalanced quotes must be macro quoted ;
* in the call to %squote ;

* this works because the parameter is macro quoted, ;
* and the %squote macro returns balanced quotation marks ;
* so the %put statement works ;
%let mvar=%bquote(P.J. O'Briens);   %put %squote(&mvar);

* assigning the results of %squote to a macro variable also works ;
* these do not work ;
%let mvar=%str(P.J. O'Briens);
%let newmvar = %squote(%bquote(&mvar));
%put &=newmvar;

%let mvar=%str(P.J. O'Briens);
%let newmvar = %squote(%superq(mvar));
%put &=newmvar;

* but this does ;
%let mvar=%bquote(P.J. O'Briens);
%let newmvar = %squote(&mvar);
%put &=newmvar;

-----------------------------------------------------------------------
Notes:


Compare the functionality of this macro to SAS's %tslit macro.
Besides the hideous hard-to-remember name of SAS's macro,
this macro is "cleaner", especially when symbolgen is active.

---------------------------------------------------------------------*/

%macro squote
/*---------------------------------------------------------------------
Wrap the argument in single quotes.
---------------------------------------------------------------------*/
(VALUE         /* Value to wrap in single quotes (Opt).              */
);

%unquote(%str(%')%qsysfunc(tranwrd(%superq(value),%str(%'),''))%str(%'))
%mend;

/******* END OF FILE *******/
