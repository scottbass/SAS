/*=====================================================================
Program Name            : nobs.sas
Purpose                 : Return the number of observations in a data
                          set.
SAS Version             : SAS 9.1.3
Input Data              : DATA= macro parameter
Output Data             : # of observations in the data set

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 01MAY2006
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
Date                    : 27MAY2015
Change/reason           : Added format=32. to select statement
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

data work.foo;
   do x=1 to 25;
      output;
   end;
run;

data work.foo_view / view=work.foo_view;
   do x=1 to 14;
      output;
   end;
run;

-----------------------------------------------------------------------

* Assign the number of observations in &syslast ;
* (work.foo_view) to &nobs;
%nobs;
%put &nobs;

=======================================================================

* Assign the number of observations in work.foo to &foo.
%let foo=%nobs(work.foo);
%put &foo;

=======================================================================

* Assign the number of observations in work.foo to &foo. ;
* Also assign the global macro variable &mynobs ;
* (which in this case is a bit redundant). ;
%let foo=%nobs(work.foo, mvar=mynobs);
%put &foo;
%put &mynobs;

=======================================================================

* Use %nobs as part of a logic condition in a data step ;
data _null_;
   if not (%nobs(work.foo)) then
      put "No observations";
   else
      put "%nobs(work.foo) observations.";
run;

=======================================================================

* Invoke %nobs on a view, assigning the number of observations to &nobs ;
%nobs(work.foo_view);
%put &nobs;

=======================================================================

* Invoke %nobs on a data set with a where condition, assigning the ;
* number of observations returned to &mymvar ;
%nobs(work.foo (where=(uniform(0) le .5)), mvar=mymvar);
%put &mymvar;

-----------------------------------------------------------------------
Notes:

If %nobs can determine the number of observations from the data set
descriptor, %nobs will invoke an "all macro" syntax, returning the
number of observations as an RVALUE.  In this scenario, %nobs should
be called as part of an assignment statement or logic condition.

If %nobs cannot determine the number of observations from the data
set descriptor, or if a data set option (usually a where clause) is
specified, %nobs will invoke PROC SQL, and will return the number of
observations in a macro variable (default is &nobs, but can be set by
the calling code).

It is up to the end user to know the proper context for calling %nobs.
If there is any doubt, you could always do:

%nobs(work.foo());
%put &nobs;

but this will not perform as well as reading the number of observations
from the data set descriptor.

If you experience any error calling this macro, as a first course try
changing the context in which the macro is called.  For example, to
test:

%put %nobs(foo);
%nobs(foo);

One of these will *always* cause an error in the code execution phase
(i.e. after macro code resolution).

Returns:
   &nobs_rc = -1 if dataset does not exist
   &nobs_rc = -2 if dataset cannot be opened for input

---------------------------------------------------------------------*/

%macro nobs
/*---------------------------------------------------------------------
Return the number of observations in a data file.
---------------------------------------------------------------------*/
(DATA          /* Name of data file (Opt).                           */
               /* If blank, &syslast is used                         */
,MVAR=         /* Name of returned macro variable (Opt).             */
               /* If non-blank then global mvar unconditionally set. */
               /* If blank then:                                     */
               /*    If "all macro" then no global macro var set.    */
               /*    If PROC SQL then global mvar &nobs set.         */
);

%local macro parmerr data mvar paren dataset options dsid anobs _nobs;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=0,_words=1,_case=U) /* _words=1 allows input ds options */
%parmv(MVAR,         _req=0,_words=0,_case=U)

%global nobs_rc;
%let nobs_rc = 0;

%*---------------------------------------------------------------------
Reset global macro variable from any previous invocations
----------------------------------------------------------------------;
%if (&mvar ne ) %then %do;
   %global &mvar;
   %let &mvar = ;
%end;

%*---------------------------------------------------------------------
When data parameter not specified, use &syslast macro variable to get
last created data set.
----------------------------------------------------------------------;
%if (%superq(data) eq ) %then %let data = &syslast;

%*----------------------------------------------------------------------
Parse data parameter for data set options.  Note that the scan
function cannot be used since a WHERE clause attached to the DATA
parameter may contain a period.
-----------------------------------------------------------------------;
%let paren = %index(&data,%str(%() );
%if (&paren) %then %do;
   %let dataset = %substr(&data,1,&paren-1);
   %let options = %substr(&data,&paren);  /* not used but may as well save */
%end;
%else %do;
   %let dataset = &data;
%end;

%*---------------------------------------------------------------------
Does the dataset exist?
----------------------------------------------------------------------;
%if ^(%sysfunc(exist(&dataset,data)) or
      %sysfunc(exist(&dataset,view))) %then %do;
   %parmv(_msg=%str(ERR)OR: &dataset does not exist);
   %let nobs_rc = -1;
   %goto quit;
%end;

%*---------------------------------------------------------------------
Does the engine know the number of observations?
Or was a data set option specified?
----------------------------------------------------------------------;
%if (&paren) %then
   %let anobs = 0;
%else %do;
   %let dsid = %sysfunc(open(&dataset));
   %if (&dsid gt 0) %then %do;
      %let anobs = %sysfunc(attrn(&dsid,anobs));
      %let _nobs = %eval(%sysfunc(attrn(&dsid,nobs)) - %sysfunc(attrn(&dsid,ndel)));
      %let dsid  = %sysfunc(close(&dsid));
   %end;
   %else %do;
      %parmv(_msg=%str(ERR)OR: Unable to open &dataset for input);
      %let nobs_rc = -2;
      %goto quit;
   %end;
%end;

%if ^(&anobs) %then %do;

%*---------------------------------------------------------------------
Number of observations could not be determined, so use PROC SQL
If mvar is blank set it to "nobs"
----------------------------------------------------------------------;
   %if (&mvar eq ) %then %do;
      %let mvar = nobs;
      %global &mvar;
      %let &mvar = ;
   %end;
   proc sql noprint;
      select count(*) format=32. into :&mvar separated by " " from &data;
   quit;
%end;
%else %do;

%*---------------------------------------------------------------------
Return number of observations as an RVALUE
If mvar is specified then also return global macro variable
----------------------------------------------------------------------;
&_nobs

   %if (&mvar ne ) %then %do;
      %let &mvar = &_nobs;
   %end;
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
