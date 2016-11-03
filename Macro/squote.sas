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

I did not write this macro.  Full attribution goes to "Tom"
https://communities.sas.com/t5/SAS-Communities-Library/Not-All-Macro-Language-Elements-Are-Supported-by-the-Macro/ta-p/223904

I just wanted to add this useful macro to my macro toolkit.

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
