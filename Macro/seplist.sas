/*====================================================================
Program Name            : seplist.sas
Purpose                 : Emit a list of words separated by a delimiter.
SAS Version             : Unknown
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Richard Devenezia
Date                    : 02SEP1999
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

Based on original work by Richard Devenezia.
http://www.devenezia.com/downloads/sas/macros/index.php?m=seplist
Used with permission.

=======================================================================

Modification History    :

Programmer              : Scott Bass
Date                    : 24APR2006
Change/reason           : Copied from
                          http://www.devenezia.com/downloads/sas/macros/index.php?m=seplist
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 07OCT2011
Change/reason           : Added %unquote(&prefix) and %unquote(&suffix)
                          to allow for incremented prefix or suffix
Program Version #       : 1.2

====================================================================*/

/*---------------------------------------------------------------------
Usage:

%put %seplist(Hello World);
* Returns Hello,World ;

%put %seplist(Hello World,nest=QQ);
* Returns "Hello","World" ;

%put %seplist(Hello   ^   World   ,nest=Q,indlm=^,trim=N);
* Returns 'Hello   ','   World' ;

%put %seplist(Hello   ^   World   ,nest=Q,indlm=^,trim=Y);
* Returns 'Hello','World' ;

%put %seplist(Hello   ^   World   ,nest=QQ,indlm=^,dlm=~,trim=Y);
* Returns "Hello"~"World" ;

%put %seplist(A B C,prefix=PREFIX_,suffix=_suffix);
* Returns PREFIX_A_suffix,PREFIX_B_suffix,PREFIX_C_suffix ;

%put %seplist(A B C,prefix=%str(%"PREFIX_),suffix=%str(_suffix%"));
* Returns "PREFIX_A_suffix","PREFIX_B_suffix","PREFIX_C_suffix" ;

%put %seplist(A B C,prefix=%nrstr(name&n=));
* Returns name1=A,name2=B,name3=C ;

%put %seplist(A B C,prefix=%nrstr(name&n=),suffix=%nrstr(_&n));
* Returns name1=A_1,name2=B_2,name3=C_3 ;

-----------------------------------------------------------------------
Notes:

The NEST parameter is just a shortcut to set specifix
PREFIX and SUFFIX settings.  So, if the NEST parameter is specified,
it overrides the PREFIX and SUFFIX parameters.

If you want both PREFIX/SUFFIX and NESTing, do not specify NEST,
and "manually" specify the PREFIX and SUFFIX parameters.

---------------------------------------------------------------------*/

%macro seplist
/*---------------------------------------------------------------------
Emit a list of words separated by a delimiter
---------------------------------------------------------------------*/
(ITEMS
,INDLM=%str( )
,DLM=%str(,)
,PREFIX=
,NEST=
,SUFFIX=
,TRIM=Y
);

/*---------------------------------------------------------------------
Usage:

-----------------------------------------------------------------------
Notes:

%* Richard A. DeVenezia - 990902;
%*
%* emit a list of words separated by a delimiter
%*
%* items  - list of items, separated by indlm
%* indlm  - string that delimits each item of items
%*   dlm  - string that delimits list of items emitted
%* prefix - string to place before each item
%* nest   - Q (single quote ''),
%*          QQ (double quotes ""),
%*          P (parenthesis ()),
%*          C (curly braces {}),
%*          B (brackets [])
%* suffix - string to place after each item
%*
%* Note: nest is a convenience, and could be accomplished using
%*       prefix and suffix
%*;

---------------------------------------------------------------------*/

%local macro parmerr emit nest prefix suffix item n;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(NEST,         _req=0,_words=0,_case=U,_val=Q QQ P C B)
%parmv(TRIM,         _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%let emit=;

%let nest = %upcase (&nest);

%if (&nest = Q) %then %do;
   %let prefix = &prefix.%str(%');
   %let suffix = %str(%')&suffix;
%end;
%else
%if (&nest = QQ) %then %do;
   %let prefix = &prefix.%str(%");
   %let suffix = %str(%")&suffix;
%end;
%else
%if (&nest = P) %then %do;
   %let prefix = &prefix.%str(%();
   %let suffix = %str(%))&suffix;
%end;
%else
%if (&nest = C) %then %do;
   %let prefix = &prefix.%str({);
   %let suffix = %str(})&suffix;
%end;
%else
%if (&nest = B) %then %do;
   %let prefix = &prefix.%str([);
   %let suffix = %str(])&suffix;
%end;

%let n = 1;
%let item = %qscan (&items, &n, %quote(&indlm));

%do %while (%superq(item) ne );
   %if (&trim) %then %let item=%qleft(%qtrim(&item));

   %if (&n = 1) %then %do;
      %if (&nest eq ) %then
         %let emit = %unquote(&prefix.)&item.%unquote(&suffix);
      %else
         %let emit = &prefix.&item.&suffix;
   %end;
   %else %do;
      %if (&nest eq ) %then
         %let emit = &emit.&dlm.%unquote(&prefix.)&item.%unquote(&suffix);
      %else
         %let emit = &emit.&dlm.&prefix.&item.&suffix;
   %end;

   %let n = %eval (&n+1);
   %let item = %qscan (&items, &n, %quote(&indlm));
%end;

%unquote(&emit)

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
