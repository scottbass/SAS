/*=====================================================================
Program Name            : loop.sas
Purpose                 : A "wrapper" macro to execute code over a
                          list of items
SAS Version             : SAS 8.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 24APR2006
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
Date                    : 17JUL2006
Change/reason           : Added DLM parameter
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 24DEC2009
Change/reason           : Made changes as suggested by Ian Whitlock,
                          updated header with additional usage cases
Program Version #       : 1.2

Programmer              : Scott Bass
Date                    : 13MAY2011
Change/reason           : Fixed nested macro scoping errors by explicitly
                          declaring the iterator and word as local.
Program Version #       : 1.3

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%macro code;
   %put &word;
%mend;
%loop(Hello World);

=======================================================================

%let str = Hello,World;
%loop(%bquote(&str),dlm=%bquote(,));

=======================================================================

%macro code();
   %put &word;
%mend;
%loop(Hello World,mname=code());

=======================================================================

%macro mymacro;
   proc print data=&word;
   run;
%mend;

proc datasets kill nowarn nolist;
quit;

data one;x=1;run;
data two;y=2;run;

proc sql noprint;
   select memname into :list separated by '|'
      from dictionary.tables
      where libname = "WORK" and memtype = "DATA"
   ;
quit;
%loop(&list,dlm=|,mname=mymacro);

=======================================================================

Calling a macro with parameters:

%macro mymacro(parm=&word);
   %put &parm;
%mend;
%loop(hello world,mname=mymacro);    * this causes a tokenization error ;
%loop(hello world,mname=mymacro());  * no error ;
%mymacro(parm=hi);

Note that the parm is the literal text '&word' (without quotes of course).
See additional details in Nested calls of %loop use case below.

=======================================================================

Nested calls of %loop:

%macro outer;
   %put &sysmacroname &__iter__ &word;
   %loop(INNER_1 INNER_2 INNER_3,mname=inner)
%mend;

%let iter_global=;

%macro inner;
   %local iter_local;
   %global iter_global;

   %if (&iter_local  eq ) %then %let iter_local=1;
   %if (&iter_global eq ) %then %let iter_global=1;

   %let iter_local=%eval(&iter_local + (&__iter__ * 5));  %* not retained across outer loops ;
   %let iter_global=%eval((&iter_global*2)+(&__iter__));  %* retained across outer loops since it is global ;

   %put &sysmacroname &__iter__ &word iter_local=&iter_local iter_global=&iter_global;
   %* let __iter__=999;  %* if uncommented, this would cause a logic error ;
%mend;

%loop(OUTER_A OUTER_B OUTER_C OUTER_D OUTER_E,mname=outer)

Do NOT reset __iter__ in any inner macro or it will affect the outer macro.
You can *REFERENCE* &__iter__, but do not *CHANGE* its value.
If you need to make logic decisions, copy &__iter__ to a local inner variable.

Also, do NOT use %yourmacro(parameter=&word) syntax in nested calls to
%loop.  For example, this will not work:

options mlogic;

%macro level1(firstvar=&word);
   %put firstvar in Level1:  &firstvar;
   %loop(Variable2, mname=level2())
%mend level1;

%macro level2(secondvar=&word);
   %put secondvar in level2: &secondvar;
   %put INCORRECT: firstvar in Level2: &firstvar;
%mend level2;

%loop(Variable1, mname=level1())

In level1, firstvar is actually assigned the literal text '&word'
(without quotes of course). Inside the level1 macro, this text then
resolves to the value of &word AT THAT TIME. Once the level2 macro
executes, it changes the value of &word, which then changes further
references to &firstvar.

Instead, assign firstvar and secondvar to the value of &word INSIDE
each macro, as described for __iter__ above.

Closely review the mlogic output above for more details.

Instead, code this as follows:

options nomlogic;

%macro level1;
   %local firstvar;
   %let firstvar=&word;
   %put &sysmacroname: firstvar in Level1:  &firstvar;
   %loop(Variable4 Variable5, mname=level2)
%mend level1;

%macro level2;
   %local secondvar;
   %let secondvar=&word;
   %put &sysmacroname: secondvar in level2: &secondvar;
   %put &sysmacroname: CORRECT: firstvar in Level2: &firstvar;
%mend level2;

%loop(Variable1 Variable2 Variable3, mname=level1)

-----------------------------------------------------------------------
Notes:

The nested macro "%code" must be created at run time before calling
this macro.

Use the macro variable "&word" within your %code macro for each token
(word) in the input list.

If your macro has any parameters (named or keyword) (even an empty
list), then specify the macro name with empty parentheses for the mname
parameter or tokenization errors will occur during macro execution. For
example, %loop(hello world,mname=mymacro());.  See examples in the
Usage section above.

If your input list has embedded blanks, specify a different dlm value.

Do not use the prefix __ (two underscores) for any macro variables in
the child macro.  This prefix is reserved for any macro variables in
this looping macro.

To "carry forward" the value of the iterator across loops, assign it
(&__iter__) to a global macro variable in an inner macro.

---------------------------------------------------------------------*/

%macro loop
/*---------------------------------------------------------------------
Invoke the nested macro "%code" over a list of space separated
list of items.
---------------------------------------------------------------------*/
(__LIST__      /* Space or character separated list of items (REQ)   */
,DLM=%str( )   /* Delimiter character (REQ).  Default is a space.    */
,MNAME=code    /* Macro name (Optional).  Default is "%code"         */
);

%local macro parmerr __iter__ word;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(MNAME,        _req=1,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* the iterator MUST be unique between macro invocations ;
%* if not, nested invocations of this macro cause looping problems ;
%* unfortunately, SAS macro does not support truly private variable scoping ;

%let __iter__ = 1;
%let word = %qscan(%superq(__list__),&__iter__,%superq(dlm));
%do %while (%superq(word) ne %str());
  %let word=%unquote(&word);
%&mname  /* do not indent macro call */
   %let __iter__ = %eval(&__iter__+1);
   %let word = %qscan(%superq(__list__),&__iter__,%superq(dlm));
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
