/*====================================================================
Program Name            : get_permutations.sas
Purpose                 : Gets all the permutations (combinations) of
                          values from an input list of data.
SAS Version             : SAS 9.3
Input Data              : SAS input dataset or list of items
Output Data             : SAS output dataset

Macros Called           : parmv, seplist

This macro is based on original work by 
Francis Joseph (Joe) Kelley documented in the SUGI paper
https://support.sas.com/resources/papers/proceedings/proceedings/sugi23/Posters/p177.pdf

Permission has been granted by Joe to use his original ideas for this macro.

Originally Written by   : Scott Bass
Date                    : 14MAY2020
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

%get_permutations(list=b a c f d e)

Creates the _get_permutations_ dataset (default output dataset name) 
from the input list of values,
at a depth of 1 level (default).

======================================================================

%get_permutations(list=b a c f d e,level=1)
%get_permutations(list=b a c f d e,level=2)
%get_permutations(list=b a c f d e,level=3)

Creates the _get_permutations_ dataset
from the input list of values,
at a depth of 1, 2, and 3 levels respectively.

======================================================================

%get_permutations(list=b a c f d e,min_level=1,max_level=1)
%get_permutations(list=b a c f d e,min_level=2,max_level=2)
%get_permutations(list=b a c f d e,min_level=3,max_level=3)

Same as above, but explicitly setting min_level and max_level.

======================================================================

%get_permutations(list=b a c f d e,min_level=2,max_level=4)
%get_permutations(list=b a c f d e,min_level=3,max_level=5)

Creates the _get_permutations_ dataset
from the input list of values,
at a depth of 2-4 and 3-5 respectively.

======================================================================

%get_permutations(list=b a c f d e,level=10)

Creates the _get_permutations_ dataset (default output dataset name) 
from the input list of values,
at a depth of number of items level.

Since min_level and max_level were not specified, 
they are internally set to level, i.e. 10.

But since max_level is greater than the number of items, 
it is set to the number of items in the list, i.e. 6.

But since min_level is now greater than max_level, it is set to
max_level, i.e. 6.

======================================================================

%get_permutations(list=b a c f d e,min_level=3,level=10)
%get_permutations(list=b a c f d e,min_level=3,max_level=10)

Same as above, but since min_level was explicitly specified, 
and it is less than the (reset) max_level (6), it remains set as 3, 
and the result is a "slice" of the permutations from 3-6.

You can use this technique (a large value for level or max_level)
to create a "slice" of permutations from min_value to the number of items.

======================================================================

%get_permutations(list=b a c f d e,level=0)

Creates the _get_permutations_ dataset (default output dataset name) 
from the input list of values,
at all possible depth levels, i.e. all possible permutations.

======================================================================

%get_permutations(list=bb a ccc ffffff dddd eeeee a eeeee ccc)

Creates the _get_permutations_ dataset
from the input list of values,
at a depth of 1 level (default).

The code removes the duplicate values in the list and displays
a warning message in the log.

======================================================================

proc sql noprint;
   create table _contents_ as
   select name
   from dictionary.columns
   where libname='SASHELP' and memname='SHOES'
   order by varnum;
quit;

%get_permutations(data=_contents_,var=name,level=1,print=Y)
%get_permutations(data=_contents_,var=name,level=2,print=Y)
%get_permutations(data=_contents_,var=name,level=3,print=Y)

Creates the _get_permutations_ dataset (default output dataset name) 
from the input list of column names,
at a depth of 1, 2, and 3 levels respectively,
and prints the output dataset.

======================================================================

proc sql noprint;
   create table _contents_ as
   select name
   from dictionary.columns
   where libname='SASHELP' and memname='SHOES'
   order by varnum;
quit;

%get_permutations(data=_contents_,var=name,level=0,print=Y)

Derives every permutation possible,
across all possible levels (1 to number of items)
from the column list of sashelp.shoes,
and prints the output dataset.

======================================================================

proc sql noprint;
   create table _contents_ as
   select name
   from dictionary.columns
   where libname='SASHELP' and memname='PRICEDATA'
   order by varnum;
quit;

%get_permutations(data=_contents_,var=name,level=1,out=permutations,print=Y)
%get_permutations(data=_contents_,var=name,level=2,out=permutations,print=Y)
%get_permutations(data=_contents_,var=name,level=3,out=permutations,print=Y)

* do not print these! ;
%get_permutations(data=_contents_,var=name,level=4,out=permutations)
%get_permutations(data=_contents_,var=name,level=5,out=permutations)

DO NOT run this with level=0!
The permutations will be in the 10's of millions 
and will take forever to run!

Creates the permutations output dataset,
from the input list of column names,
at a depth of 1, 2, 3, 4, and 5 levels respectively.

This example demonstrates how the list of permutations increases
substantially with an increase in the number of items and the 
depth level.

Note however that the distribution is analogous to a bell curve.
As the level passes the midpoint of the number of items, 
the number of permutations decreases.

======================================================================

Error Testing:

%get_permutations()

Either DATA or LIST must be specified.

%get_permutations(data=doesnotexist)

If DATA is specified it must be an existing dataset or view
(including RDBMS tables).

%get_permutations(data=sashelp.class,var=foo)

If DATA is specified, then VAR must also be specified 
and must exist in the DATA dataset or view.

%get_permutations(data=sashelp.class,var=name,out=)

OUT is a required parameter and must be a valid output dataset name.

%get_permutations(data=sashelp.class,var=name,level=)

LEVEL is a required parameter.

%get_permutations(data=sashelp.class,var=name,level=-1)

LEVEL must be a NONNEGATIVE number.

%get_permutations(data=sashelp.class,var=name,min_level=0)

MIN_LEVEL must be a POSITIVE number.

%get_permutations(data=sashelp.class,var=name,max_level=0)

MAX_LEVEL must be a POSITIVE number.

%get_permutations(data=sashelp.class,var=name,min_level=5,max_level=3)

MIN_LEVEL must less than or equal to MAX_LEVEL.

----------------------------------------------------------------------
Notes:

This macro creates working datasets with a naming convention
using leading and trailing underscores, i.e. _<dataset name>_.
If your session also uses this naming convention for your datasets
there is a slight chance of dataset name collision.

The default output dataset name is _<name of macro>_, i.e.
_get_permutations_.

Setting LEVEL is the equivalent of setting MIN_LEVEL and MAX_LEVEL
to that value.  
This will create an output dataset of that depth level only.

Setting LEVEL=0 is the equivalent of setting MIN_LEVEL=1 and
MAX_LEVEL to the number of items in the source dataset.
This will create an output dataset of all possible depth levels,
i.e. all possible permutations.  This can create a SIGNIFICANT
number of permutations.

If both MIN_LEVEL and MAX_LEVEL are set, then LEVEL is ignored.
This will create an output dataset of those specified depth levels,
i.e. a "slice" of all possible permutations.

--------------------------------------------------------------------*/

%macro get_permutations
/*--------------------------------------------------------------------
Gets all the permutations (combinations) of values 
from an input list of data.
--------------------------------------------------------------------*/
(DATA=         /* Input dataset (Opt).                              */
               /* If not specified, the LIST parameter must be      */
               /* specified.                                        */
,OUT=work._get_permutations_
               /* Output dataset (REQ).                             */
               /* The default value is work._get_permutations_.     */
,VAR=          /* Variable containing the list of items from which  */
               /* the permutations are generated (Opt).             */
               /* If the DATA parameter is specified,               */
               /* the VAR parameter is also required.               */
,LIST=         /* A space separated list of items from which the    */
               /* permutations are generated (Opt).                 */
               /* If specified, the DATA and VAR parameters are     */
               /* ignored.                                          */
,LEVEL=1       /* Desired depth level of permutations to generate   */
               /* (REQ).  Default value is 1.                       */
               /* If LEVEL=0, then all column permutations will     */
               /* be generated.  This can result in a significant   */
               /* number of permutations!                           */
,MIN_LEVEL=    /* Starting depth level of permutations to generate  */
               /* (Opt).                                            */
,MAX_LEVEL=    /* Maximum depth level of permutations to generate   */
               /* (Opt).                                            */
,PRINT=N       /* Print the OUT dataset to the Results window? (REQ)*/
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);

%local macro parmerr; 
%local line dsid varnum dups sqlobs num_items max_len start stop i lev;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=0,_words=0,_case=N)
%parmv(OUT,          _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(VAR,          _req=0,_words=0,_case=N)
%parmv(LIST,         _req=0,_words=1,_case=N)
%parmv(LEVEL,        _req=1,_words=0,_case=N,_val=NONNEGATIVE)
%parmv(MIN_LEVEL,    _req=0,_words=0,_case=N,_val=POSITIVE)
%parmv(MAX_LEVEL,    _req=0,_words=0,_case=N,_val=POSITIVE)
%parmv(PRINT,        _req=1,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%let line=%sysfunc(repeat(=,71));

%* Additional error checking ;

%* If MIN_LEVEL or MAX_LEVEL are not specified set them to LEVEL ;
%if (&min_level eq ) %then %let min_level=&level;
%if (&max_level eq ) %then %let max_level=&level;

%* MIN_LEVEL must be less than or equal to MAX_LEVEL ;
%if (&min_level gt &max_level) %then %do;
   %parmv(_msg=MIN_LEVEL (&min_level) must be less than or equal to MAX_LEVEL (&max_level))
   %goto quit;
%end;

%* either DATA or LIST must be specified ;
%if (%superq(data)%superq(list) eq ) %then %do;
   %parmv(_msg=Either DATA or LIST must be specified)
   %goto quit;
%end;

%* If DATA was specified does the dataset exist? ;
%if (%superq(data) ne ) %then %do;
   %if ^(%sysfunc(exist(&data,data)) or
         %sysfunc(exist(&data,view))) %then %do;
      %parmv(_msg=&data does not exist)
      %goto quit;
   %end;

   %* If DATA was specified then VAR must also be specified ;
   %if (%superq(var) eq ) %then %do;
      %parmv(_msg=If DATA is specified then VAR must also be specified.)
      %goto quit;
   %end;

   %* Does VAR exist in the specified dataset ;
   %let dsid=%sysfunc(open(&data));
   %if (&dsid le 0) %then %do;
      %parmv(_msg=Unable to open &data dataset)
      %goto quit;
   %end;
   %let varnum = %sysfunc(varnum(&dsid,&var));
   %if (&varnum le 0) %then %do;
      %parmv(_msg=&var does not exist in &data)
      %let dsid=%sysfunc(close(&dsid));
      %goto quit;
   %end;
   %let dsid=%sysfunc(close(&dsid));
%end;

%* End of additional error checking ;

%* If a list was passed in convert to a dataset ;
%if (%superq(list) ne ) %then %do;
   data work._list_ (compress=no);
      length item $200;
      do item=%seplist(&list,nest=q);
         output;
      end;
   run;
   %let data=work._list_;
   %let var=item;
%end;

* check for duplicate items.  get maximum item length. ;
proc sql noprint; 
   %* check for dups ;
   select &var into :dups separated by ' '
   from &data
   group by &var
   having count(0) > 1;

%if (&sqlobs ne 0) %then %do;
   %put &line;
   %put %str(WAR)NING: Duplicate values found in &data: &dups..;
   %put %str(WAR)NING: De-duplicating data.;
   %put &line;

   * we cannot (easily) use select distinct and keep data order due to the vagaries of SQL ;
   * so use an alternative approach to dedup the data ;

   %* I tried creating a view but it does not give the correct results ;
   %* I think it is due to the runtime execution of the monotonic() function ;
   %* when used within a view that is aggregating on a grouping variable ;

   * create a table of the source dataset with a sorting column to retain the data order ;
   create table work._varnum_ as
   select &var, monotonic() as varnum
   from &data;

   create table work._dedup_ as
   select &var
   from _varnum_
   group by &var
   having varnum=min(varnum)
   order by varnum;

   %let data=work._dedup_;
%end;

   %* get maximum item length ;
   select max(length(&var)) into :max_len trimmed from &data;
quit;

%let num_items=%nobs(&data);

%* Now that we have NUM_ITEMS, process for LEVEL=0 ;
%if (&level eq 0) %then %do;
   %let min_level=1;
   %let max_level=&num_items;
%end;

%* If MAX_LEVEL is greater than the NUM_ITEMS set it to NUM_ITEMS ;
%if (&max_level gt &num_items) %then %do;
   %put &line;
   %put %str(NO)TE: Specified MAX_LEVEL (&max_level) is greater than the number of items (&num_items).;
   %put %str(NO)TE: Resetting MAX_LEVEL from &level to &num_items..;
   %put &line;
   %let max_level=&num_items;
%end;

%* If MIN_LEVEL is greater than MAX_LEVEL set it to MAX_LEVEL ;
%if (&min_level gt &max_level) %then %do;
   %let min_level=&max_level;
%end;

* get the permutations ;
proc transpose data=&data out=work._items_ (compress=no drop=_name_) prefix=_____;
   var &var;
run;

%macro permutations(out);
   %let start=1;
   %let stop=%eval(&num_items - &level);
   data &out;
      set work._items_;
      length item0 $1000;
      array _____{*} _____:;
      array items{*} $&max_len item1 - item&level;
      keep item:;

      %do i = 1 %to &level;
         %let stop = %eval(&stop + 1);
         do idx&i = &start to &stop;
         %let start = %str(%(idx&i + 1%)); %* yes this is correct, do not change this! ;
      %end;
      %do i = 1 %to &level;
         items{&i} = _____{idx&i};
      %end;
      item0=catx(' ',of item1 - item&level);
      output;
      %do i = 1 %to &level;
         end;
      %end;
   run;
%mend;

%do level=&min_level %to &max_level;
   %permutations(work._permutations_%sysfunc(putn(&level,z2.))_)
%end;

%* create consolidated dataset ;
data &out;
   set
   %do level=&min_level %to &max_level;
      work._permutations_%sysfunc(putn(&level,z2.))_
   %end;
   ;
   /* rowcnt+1 */
run;

proc datasets lib=work nowarn nolist;
   delete _permutations_:;
quit;

%if (&print) %then %do;
   title "Permutations for &data";
   proc print data=&out;
   run;
   title;
%end;

%quit:

%mend;

/******* END OF FILE *******/
