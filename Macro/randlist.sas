/*=====================================================================
Program Name            : randlist.sas
Purpose                 : Macro to create a random list of data
SAS Version             : SAS 8.2
Input Data              : DATA= macro parameter
Output Data             : OUT=  macro parameter

Macros Called           : parmv, varexist, nobs

Originally Written by   : Scott Bass
Date                    : 12JAN2005
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

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%randlist(data=ir&prot..lab)
   returns a random 50% of input dataset in macro variable &randlist.
   data returned is a list of subjid (default value of VAR parameter).

%randlist(data=ir&prot..lab, var=usubjid)
   returns a random 50% of input dataset in macro variable &randlist.
   data returned is a list of usubjid.

%randlist(data=ir&prot..lab, out=work.lab_randlist)
   returns a random 50% of input dataset in both macro variable
   &randlist and output dataset work.lab_randlist.  data returned would
   be a random 50% of subjids from the input dataset, and a random
   ordered list of these same subjids in &randlist.

%randlist(data=ir&prot..lab, out=work.lab_randlist, mvar=)
   returns a random 50% of input dataset in output dataset
   work.lab_randlist only (since the MVAR parameter is blank). data
   returned would be a random 50% of subjids from the input dataset.

%randlist(data=ir&prot..lab, pct=20)
   returns a random 20% of subjids from the input dataset in macro
   variable &randlist.

%randlist(data=ir&prot..lab, pct=20, min=10)
   returns a random 20% of subjids from the input dataset in macro
   variable &randlist, or a minimum of 10 items returned if 20% is less
   than 10 items.

%randlist(data=ir&prot..lab, pct=20, max=30)
   returns a random 20% of subjids from the input dataset in macro
   variable &randlist, or a maximum of 30 items returned if 20% is
   greater than 30 items.

%randlist(data=ir&prot..lab, pct=20, min=20, max=120)
   returns a random 20% of subjids from the input dataset in macro
   variable &randlist, with a minimum of 20 items and a maximum number
   of 120 items returned.

%randlist(
   data=ir&prot..lab (where=(subjid not like "S%")),
   out=work.randlist (keep=subjid visit)
)
   returns a random 50% of subjids from the input dataset, which is
   *first* subset by the input dataset where clause.

   returned data is in both the macro variable &randlist and the
   output dataset work.randlist.

   only the variables subjid and visit are kept in the output dataset.

-----------------------------------------------------------------------
Notes:

This macro would be better if rewritten to use PROC SURVEYSELECT.

Input dataset must be specified and must exist.

VAR must be a variable in the input dataset.

By default, &randlist is always created.
Set MVAR to blank to suppress this.

The MVAR variable is returned as a comma-delimited list only (no parentheses).
This makes it easier to further parse the returned list if required.
If building an IN where clause, you need to add the parentheses, eg.

   where subjid in (&randlist);

   not

   where subjid in &randlist;

Character variables are returned as a single-quoted comma-delimited list,
eg. '10041017','10031023','10021037', etc.

and numeric variables are returned as a comma-delimited list,
eg. 17,3,22,7,4,53, etc.

An *output* WHERE clause defeats the whole purpose of this macro.
The &out parm is upper-cased in the macro.  An output WHERE clause will
have unpredictable results.

Note that, if you invoke this macro and create a macro variable &mvar
in a *non-default* macro variable name (i.e. not &randlist), then later
re-invoke the macro with &mvar set to missing, the *old* random item
list will still exist in that macro variable.  Since the syntax to not
create a macro variable is a blank &mvar, I don't know which old macro
variable to reset.  The best I can do is unconditionally delete the
*default* macro variable &randlist on each macro invocation. You can
use %symdel to delete an old macro variable before re-invoking the
macro.
---------------------------------------------------------------------*/

%macro randlist
/*---------------------------------------------------------------------
Create a random list of data, and create an output data set, a macro
variable list, or both.  Output can be limited by pct of total
&var (usually subjid), min # of subjids, max # of subjids, or a
combination of these parameters.
---------------------------------------------------------------------*/
(DATA=         /* Input dataset (REQ).                               */
               /* Input dataset options are allowed.                 */
,OUT=          /* Output dataset (Optional).                         */
               /* Output dataset options are allowed, such as KEEP=, */
               /* but don't use a WHERE= output dataset option.      */
               /* If missing no output dataset will be created.      */
,OUTRAND=0     /* Sort output dataset in random order? (Opt.)        */
               /* If no output dataset supplied then this option has */
               /* no effect.  Valid values are                       */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
,VAR=          /* Variable to subset on (REQ).                       */
,MVAR=randlist /* Output macro variable list (Optional).             */
               /* Default value is randlist.  If missing no macro    */
               /* variable list will be created.                     */
,PCT=50        /* percentage of input dataset desired in output.     */
               /* (Optional).  Default value is 50%.  If missing,    */
               /* 100% of the input dataset will be included in the  */
               /* output.  Valid values are 1 - 100.                 */
,MIN=          /* Minimum number of VAR desired in output (Opt.)     */
,MAX=          /* Maximum number of VAR desired in output (Opt.)     */
,SEED=0        /* Seed value for uniform function (REQ).             */
               /* Default value is 0.                                */
               /* Valid values are any non-negative integer.         */
);

%* delete the old default &mvar setting ;
%unquote(%nrstr(%symdel randlist / nowarn)); /* workaround a SAS bug */

%* basic error checking ;
%local macro parmerr options;
%let macro = &sysmacroname;

%* do not want to upcase the input data parm ;
%* or it will mess up any input where clause ;
%parmv(DATA,       _req=1,_words=1,_case=N) /* _words=1 allows input  ds options */
%parmv(OUT,        _req=0,_words=1,_case=U) /* _words=1 allows output ds options */
%parmv(OUTRAND,    _req=0,_words=0,_val=0 1)
%parmv(MVAR,       _req=0,_words=0,_case=U)
%parmv(VAR,        _req=1,_words=0,_case=U);
%parmv(PCT,        _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(MIN,        _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(MAX,        _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(SEED,       _req=1,_words=0,_case=U,_val=NONNEGATIVE)

%if (&parmerr) %then %goto quit;

%* first parse off any dataset options ;
%let randlist_index = %index(%bquote(&data),%str(%());
%if (&randlist_index) %then %do;
   %let options = %substr(%bquote(&data),&randlist_index);
   %let data    = %substr(%bquote(&data),1,&randlist_index-1);
%end;
%let data = %upcase(&data);

%* more error checking ;

%* does the input dataset exist? ;
%if not %sysfunc(exist(&data)) %then
   %parmv(_msg=Dataset &data does not exist);

%* is var in the input dataset? ;
%if not %varexist(&data,&var) %then
   %parmv(_msg=Variable &var does not exist in dataset &data);
%else
   %let vartype = %varexist(&data,&var,TYPE);

%* are both output dataset and mvar variable blank? ;
%if (%bquote(&out) = and &mvar = ) %then
   %parmv(_msg=Either an output dataset or macro variable must be specified);

%* output dataset cannot be named _temp_ ;
%let temp = %upcase(%bquote(%scan(&out,1,%str(%())));
%if (&temp = _TEMP_ or &temp = WORK._TEMP_) %then
   %parmv(_msg=Output dataset cannot be named _TEMP_.  Choose another output dataset name.);

%* is percent between 1 and 100? ;
%if not (1 <= &pct and &pct <= 100) %then
   %parmv(_msg=Percent must be an integer between 1 and 100);

%* is max greater than min? ;
%if (&min ^= and &max ^= )%then
   %if (&max <= &min) %then
      %parmv(_msg=Max (&max) must be greater than min (&min));

%if (&parmerr) %then %goto quit;

%* create a dataset of distinct &var, sorted in random order ;
proc sql noprint;
   create table _temp_ as
      select *, uniform(&seed) as sort
         from
            (select distinct &var
               from &data &options
            )
         order by sort
   ;
quit;

%* calculate percentage, min, and max ;
%let nobs=%nobs(_temp_);

%if (&pct = ) %then %let pct = 100;
%if (&min = ) %then %let min = 0;
%if (&max = ) %then %let max = &nobs;

%* convert pct to an observation count ;
%let pct = %sysfunc(round(&nobs * (&pct / 100)));

%* now calculate the desired item count given pct, min, and max settings ;
%let num = %sysfunc(min(%sysfunc(max(&min,&pct)),&max));

%* debugging statement ;
%put nobs=&nobs pct=&pct min=&min max=&max num=&num;

%* create random subset and/or item list ;
proc sql noprint;

   %* do you want an output dataset? ;
   %if (%bquote(&out) ^= ) %then %do;
      create table %bquote(&out) as
         select *
         %if (&outrand) %then %do;
            , uniform(&seed) as sort
         %end;
            from &data &options
            where &var in
               (select &var
                  from _temp_ (obs=&num)
               )
         %if (&outrand) %then %do;
            order by sort
         %end;
      ;
   %end;

   %* do you want an output macro variable? ;
   %* if you want a sorted, but still random, list then uncomment the "distinct" keyword ;
   %* but an unsorted list gives more confidence that the list is truly random ;
   %if (&mvar ^= ) %then %do;
      %global &mvar;

      %if (&vartype = C) %then %do;
         select /* distinct */ quote(strip(&var)) into :&mvar separated by ','
            from _temp_ (obs=&num)
         ;
      %end;
      %else %do;
         select /* distinct */ &var into :&mvar separated by ','
            from _temp_ (obs=&num)
         ;
      %end;
   %end;
quit;

%quit:
%mend;

/******* END OF FILE *******/