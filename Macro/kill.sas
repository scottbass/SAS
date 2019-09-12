/*====================================================================
Program Name            : kill.sas
Purpose                 : Deletes specified contents from a library
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 15Feb2010
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

Modification History    :

Programmer              : Scott Bass
Date                    : 30JAN2012
Change/reason           : Added data parameter.
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 01AUG2016
Change/reason           : Changed save/delete/data parameters to not
                          change the case.  Table names are case
                          sensitive when working with RDBMS's. 
Program Version #       : 1.2

+===================================================================*/

/*--------------------------------------------------------------------
Usage:

%kill;

   Deletes all datasets and views (default) from the WORK library (default)

%kill(
   lib=claims
);

   Deletes all datasets and views (default) from the claims library

%kill(
   lib=claims
   ,type=data
);

   Deletes all datasets (only) from the claims library

%kill(
   lib=claims
   ,type=data view catalog
);

   Deletes all contents (datasets, views, catalogs) from the claims library

%kill(
   lib=claims
   ,type=all
);

   Deletes all contents (datasets, views, catalogs) from the claims library
   (same as above)

%kill(
   lib=claims
   ,save=FOO BAR BLAH
);

   Deletes all contents from the claims library EXCEPT FOO, BAR, and BLAH
   datasets or views.  Since a SAS library can contain EITHER a dataset
   OR view for a given membername, both datasets and views are saved for
   a given membername.

%kill(
   lib=claims
   ,delete=FOO BAR BLAH
);

   Deletes ONLY FOO, BAR, and BLAH datasets or views from the claims library.

%kill(
   data=claims.foo
);

   Deletes the FOO dataset or view from the claims library.

----------------------------------------------------------------------
Notes:

The complete list of member types that can be specified to
PROC DATASETS are ACCESS ALL CATALOG DATA FDB MDDB PROGRAM VIEW.
For simplicity, this macro only accepts type=DATA VIEW CATALOG ALL.
A blank type= parameter is equivalent to DATA VIEW.

Only one of data=, delete=, or save= options can be specified.  If both
are specified an error message is returned.

--------------------------------------------------------------------*/

%macro kill
/*--------------------------------------------------------------------
Deletes specified contents from a library
--------------------------------------------------------------------*/
(LIB=          /* Input library (Opt).  If not specified,           */
               /* the WORK library is used.                         */
,TYPE=DATA VIEW
               /* Member type affected (Opt).  If not specified,    */
               /* all datasets and views are deleted.               */
               /* Valid values are DATA, VIEW, CATALOG, ALL         */
,SAVE=         /* Member names to save from deletion (Opt).         */
               /* If not specified, all items are deleted.  If the  */
               /* member name does not exist in the specified       */
               /* library, no error occurs, but also no error       */
               /* message is displayed.                             */
,DELETE=       /* Member names to delete (Opt).                     */
               /* If not specified, all items are deleted.  If the  */
               /* member name does not exist in the specified       */
               /* library, no error occurs, but also no error       */
               /* message is displayed.                             */
,DATA=         /* Member name to delete (Opt).                      */
               /* Only a single name can be specified.              */
               /* If a one-level name is specified, the USER        */
               /* option is used for the library.  If the USER      */
               /* option is blank then WORK is used for the library.*/
);

%local macro parmerr kill readonly;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(LIB,           _req=0,_words=0,_case=U)
%parmv(TYPE,          _req=0,_words=1,_case=U,_val=DATA VIEW CATALOG ALL)
%parmv(SAVE,          _req=0,_words=1,_case=N)
%parmv(DELETE,        _req=0,_words=1,_case=N)
%parmv(DATA,          _req=0,_words=1,_case=N)

%let check=%eval((&save ne ) + (&delete ne ) + (&data ne ));
%if (&check gt 1) %then
%parmv(_msg=Only one of DATA=, SAVE=, or DELETE= parameters may be specified)

%if (&parmerr) %then %goto quit;

%* If DATA was specified, parse into LIB and DELETE ;
%if (&data ne ) %then %do;
  %let delete=%scan(&data,2,.);  %* two level name ;
  %if (&delete eq ) %then
    %let delete=%scan(&data,1,.); %* one level name ;
  %else
    %let lib=%scan(&data,1,.);
%end;

%* if library was not specified, use USER= option, then use WORK ;
%if (&lib eq ) %then %let lib=%sysfunc(getoption(user));
%if (&lib eq ) %then %let lib=WORK;

%* if member type was not specified, use DATA VIEW ;
%if (&type eq ) %then %let type=DATA VIEW;

%* if save or delete were not specified, use KILL ;
%let kill=kill;
%if (&save ne ) or (&delete ne ) %then %let kill=;

%* check if library is readonly (assume WORK is not readonly!) ;
%let readonly=no;
%if (%upcase(&lib) ne WORK) %then %do;
   proc sql noprint;
      select readonly into :readonly separated by " "
      from dictionary.libnames
      where upcase(libname) = "%upcase(&lib)"
      ;
   quit;
%end;

%if (%index(&readonly,yes) eq 0) %then %do;
   proc datasets lib=&lib memtype=(&type) &kill nolist nowarn;
   %if (&save ne   ) %then %do;save &save;%end;
   %if (&delete ne ) %then %do;delete &delete;%end;
   quit;
%end;
%else %do;
   %put %str(NO)TE: Library &lib is readonly;
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
