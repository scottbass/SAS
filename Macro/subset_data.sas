/*=====================================================================
Program Name            : subset_data
Purpose                 : Subset the input dataset by observations and
                          variables. Also rename variables.
SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : None

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 27APR2007
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

%subset_data
(
   data=sashelp.class
   ,out=class
   ,obs=%str(1-5 or 11-15 or 20-30)
   ,rename=%str(Sex=Gender)
   ,keep=Name Age Gender
);

   Subset sashelp.class dataset,
      outputting work.class dataset
      keeping observations 1-5, 11-15 (10 observations in total)
         (there are only 19 observations in sashelp.class)
      renaming variable Sex to Gender
      keeping variables Name Age Gender

%subset_data
(
   data=sashelp.class
   ,out=class
   ,rename=%str(Sex=Gender)
   ,where=%str(Gender="F")
);

   Subset sashelp.class dataset,
      outputting work.class dataset,
      keeping all Female records

data class;
   set sashelp.class;
   if (sex="F") then call missing(of _all_);
run;

%let missing=%sysfunc(getoption(missing,keyword));
options missing=" ";

%subset_data
(
   data=class
   ,out=test
   ,if=%str(not missing(cats(of _all_)))
);

options &missing;

   Subset sashelp.class dataset,
      outputting work.class dataset,
      deleting records where all variables are missing
         (i.e. completely blank records)

This is a common problem with Excel, since it often "loses track"
of the end of data.

-----------------------------------------------------------------------
Notes:

Subset data created by a PROC IMPORT of an Excel spreadsheet.

The OBS parameter is parsed, and converted to a subsetting if
statement.  There is no error if the obs parameter is greater than
the number of observations in the input dataset.

If the RENAME parameter is specified, all other parameters (i.e.
WHERE clause) should use the renamed variable name.

This is a pretty simple macro, just meant to make a common job task
take less code to implement in the calling program.

---------------------------------------------------------------------*/

%macro subset_data
/*---------------------------------------------------------------------
Subset the input dataset by observations and variables.
Also rename variables.
---------------------------------------------------------------------*/
(DATA=&syslast /* Input dataset (REQ).                               */
               /* Default is &syslast (last dataset created).        */
,OUT=&syslast  /* Output dataset (REQ).                              */
               /* Default is &syslast (last dataset created).        */
,WHERE=        /* Where clause (Opt).                                */
               /* Do not specify the where keyword.                  */
,IF=           /* Subsetting If statement (Opt).                     */
               /* Do not specify the if keyword.                     */
               /* The statement must be in the form of a subsetting  */
               /* if, not a subsetting delete.                       */
,FIRSTOBS=     /* First observation to keep (Opt).                   */
,LASTOBS=      /* Last observation to keep (Opt).                    */
,OBS=          /* List of observations to keep (Opt).                */
               /* Use this if you need to keep a non-contiguous      */
               /* range of observations.  Specify the list as a      */
               /* range separated by the keyword "or".               */
               /* See examples below.                                */
,KEEP=         /* Variables to keep (Opt).                           */
               /* Should be syntactically correct variable list,     */
               /* such as A-C X Y Z, F1-F3 F5, _numeric_, etc.       */
,DROP=         /* Variables to drop (Opt).                           */
               /* Should be syntactically correct variable list,     */
               /* such as A-C X Y Z, F1-numeric-F10, etc.            */
,RENAME=       /* Variables to rename (Opt).                         */
               /* Should be syntactically correct rename statement,  */
               /* such as F1=State F2=Institution, etc.              */
);

%local macro parmerr obs id1 id2 id3 id4 id5;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(DATA,          _req=1,_words=1,_case=U)  /* words=1 allows ds options */
%parmv(OUT,           _req=1,_words=1,_case=U)
%parmv(FIRSTOBS,      _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(LASTOBS,       _req=0,_words=0,_case=U,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

%* parse the obs option ;
%if (%superq(obs) ne ) %then %do;
   %let id1 = %sysfunc(prxparse(s/\s*or\s*/ OR /i));                    %* multiple spaces to single space, uppercase OR ;
   %let id2 = %sysfunc(prxparse(s/\s*-\s*/-/i));                        %* multiple spaces around dash to no space ;
   %let id3 = %sysfunc(prxparse(s/\s+(\d+)\s+/ $1-$1 /i));              %* single numbers to numeric range ;
   %let id4 = %sysfunc(prxparse(s/(\d+)-(\d+)/($1 le _N_ le $2)/i));    %* convert to subsetting if syntax ;
   %let id5 = %sysfunc(prxparse(s/###//i));
   %let obs = %sysfunc(prxchange(&id1,-1,%str(&obs ###)));              %* trailing delimiter to ensure match on id3 ;
   %let obs = %sysfunc(prxchange(&id2,-1,&obs));
   %let obs = %sysfunc(prxchange(&id3,-1,&obs));
   %let obs = %sysfunc(prxchange(&id4,-1,&obs));
   %let obs = %sysfunc(prxchange(&id5,-1,&obs));
   %let obs = if &obs;
   %syscall prxfree(id1);
   %syscall prxfree(id2);
   %syscall prxfree(id3);
   %syscall prxfree(id4);
   %syscall prxfree(id5);
%end;

data &out;
   set &data
   %if (%quote(&firstobs.&lastobs.&rename) ne ) %then %do;
      (
      %if (&firstobs ne ) %then %do;
         firstobs=&firstobs
      %end;
      %if (&lastobs ne ) %then %do;
         obs=&lastobs
      %end;
      %if (%quote(&rename) ne ) %then %do;
         rename=( &rename )
      %end;
      )
   %end;
   ;
   %if (%quote(&obs) ne ) %then %do;
      &obs;
   %end;
   %if (%quote(&where) ne ) %then %do;
      where &where;
   %end;
   %if (%quote(&if) ne ) %then %do;
      if &if;
   %end;
   %if (%quote(&keep) ne ) %then %do;
      keep &keep;
   %end;
   %if (%quote(&drop) ne ) %then %do;
      drop &drop;
   %end;
run;

%quit:
%mend;

/******* END OF FILE *******/
