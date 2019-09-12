/*=====================================================================
Program Name            : dump_mvars.sas
Purpose                 : Dumps macro variables to the log.
SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : None

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 11MAY2011
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

Modification History    :

Programmer              : Scott Bass
Date                    : 03NOV2011
Change/reason           : Added _ALL_, SCOPE=, and SORT= options
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 19JUN2012
Change/reason           : Added support for mismatched quotes in the
                          dumped macro variable
Program Version #       : 1.2

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%dump_mvars(
   sysdate9
   sysday
   sysmacroname
   sysscp
   sysuserid
   undefined
)

Dumps named macro variables to the log, in the order specified.

=======================================================================

%let alpha=A;
%let omega=B;
%let zeta=C;

%dump_mvars(
   zeta
   omega
   alpha
   ,sort=yes
)

Dumps named macro variables to the log, sorted by name.

=======================================================================

%dump_mvars(
   _all_
   ,scope=automatic
   ,sort=yes
)

Dumps ALL automatic macro variables to the log, sorted by name.

=======================================================================

%dump_mvars(
   _all_
)

Dumps ALL macro variables to the log,
in the order returned by the dictionary table.

=======================================================================

data _null_;
  a="Test of 'matched' quotes";
  b='Test of "matched" quotes';
  c="Test of 'mismatched quotes";
  d='Test of "mismatched quotes';
  call symputx("a", a, "G");
  call symputx("b", b, "G");
  call symputx("c", c, "G");
  call symputx("d", d, "G");
  call symputx("e", '&b', "G");
  call symputx("f", '&c', "G");
run;

* this works ;
%dump_mvars(
   a b c d e
)

* this fails ;
* it works for everything except an embedded macro variable reference to mismatched quotes ;
%dump_mvars(
   f
)

%symdel a b c d e f / nowarn;

Dump a macro variable with mismatched quotes.

-----------------------------------------------------------------------
Notes:

---------------------------------------------------------------------*/

%macro dump_mvars
/*---------------------------------------------------------------------
Dumps macro variables to the log.
---------------------------------------------------------------------*/
(
 MVARS         /* List of macro variables to dump to the log (REQ).  */
 ,SCOPE=       /* Macro variable scope (Opt).                        */
               /* If not specified, all macro scopes are printed.    */
               /* Valid values are GLOBAL, LOCAL, and AUTOMATIC      */
 ,SORT=        /* Print values sorted by macro variable name?        */
               /* If missing or NO, values are printed in the order  */
               /* specified in the macro call.  If YES, values are   */
               /* printed in sorted order based on macro variable    */
               /* name.                                              */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr mvar line i;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(MVARS,        _req=1,_words=1,_case=N)
%parmv(SCOPE,        _req=0,_words=1,_case=U,_val=GLOBAL LOCAL AUTOMATIC)
%parmv(SORT,         _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* if MVARS=_ALL_, print all macro variables ;
%* if SCOPE was specified, limit printing to specified scope ;
%* if SORT=YES, print macro variables in sorted order ;
%* In all three scenarios, we need to use the dictionary tables to reformat the MVARS list ;

%if ( (%upcase(&mvars) eq _ALL_) or (&scope ne ) or (&sort eq 1) ) %then %do;
  proc sql noprint;
    select
      name into :mvars separated by " "
    from
      dictionary.macros
    where

    %if (%upcase(&mvars) eq _ALL_) %then %do;
      1
    %end;
    %else %do;
      upcase(name) in (%upcase(%seplist(&mvars,nest=QQ)))
    %end;

    %if (&scope ne ) %then %do;
      and scope in (%upcase(%seplist(&scope,nest=QQ)))
    %end;

    %if (&sort eq 1) %then %do;
      order by name
    %end;
    ;
  quit;
%end;

%* now print the mvars list to the log ;
%let line=%sysfunc(repeat(=,%sysfunc(getoption(ls))-1));
%let line=%substr(&line,1,80);
%put &line;

%let i=1;
%let mvar=%scan(&mvars,&i);
%do %while (&mvar ne );
   %if %symexist(&mvar) %then %do;
      %let num1 = %sysfunc(countc(%superq(&mvar),%str(%')));
      %let num2 = %sysfunc(countc(%superq(&mvar),%str(%")));
      %if (%sysfunc(mod(&num1,2)) ne 0) %then %do;
         %put %sysfunc(putc(&mvar,$32.)) = %superq(&mvar);
      %end;
      %else
      %if (%sysfunc(mod(&num2,2)) ne 0) %then %do;
         %put %sysfunc(putc(&mvar,$32.)) = %superq(&mvar);
      %end;
      %else %do;
         %put %sysfunc(putc(&mvar,$32.)) = %unquote(%superq(&mvar));
      %end;
   %end;
   %else %do;
      %put %sysfunc(putc(&mvar,$32.)) = ***MACRO VARIABLE UNDEFINED***;
   %end;
   %let i=%eval(&i+1);
   %let mvar=%scan(&mvars,&i);
%end;

%put &line;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
