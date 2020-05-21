/*====================================================================
Program Name            : guess_pk
Purpose                 : Guess the primary key of a SAS dataset or 
                          RDBMS table.
SAS Version             : SAS 9.3
Input Data              : SAS dataset or RDBMS table
Output Data             : SAS output dataset

Macros Called           : parmv, seplist, varlist, dedup_mstring,
                          loop, loop_control, nobs, get_permutations

This macro is based on original ideas provided by Allan Bowe.

Originally Written by   : Scott Bass
Date                    : 18MAY2020
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

%guess_pk(data=sashelp.class)

Guess the primary key for the sashelp.class dataset,
creating the _guess_pk_ output dataset (default value),
processing up to MAX_LEVEL=4 permutations (default value)
of the columns until a "hit" is found.

======================================================================

%guess_pk(data=sashelp.zipcode)

Guess the primary key for the sashelp.zipcode dataset,
creating the _guess_pk_ output dataset (default value),
processing up to MAX_LEVEL=4 permutations (default value)
of the columns until a "hit" is found.

Note that ZIP_CLASS, ALIAS_CITY, and ALIAS_CITYN are dropped as 
potential primary key columns since they contain missing values.

======================================================================

%guess_pk(data=sashelp.cars,print=Y)

Guess the primary key for the sashelp.cars dataset,
creating the _guess_pk_ output dataset (default value),
processing up to MAX_LEVEL=4 permutations (default value)
of the columns until a "hit" is found.

======================================================================

%guess_pk(
   data=sashelp.cars,
   out=pk (
      where=(
         prxmatch('/\bmake\b/i',strip(key)) 
     and prxmatch('#\bmodel\b#i',strip(key)) 
      )
   ),
   level=3,
   print=Y
)
%guess_pk(
   data=sashelp.cars,
   out=pk (
      where=(
         findw(key,'make','','i')
     and findw(key,'model','','i')
      )
   ),
   min_level=3,
   max_level=4,
   print=Y
)

Let's say we disagree with the previous results,
believe that the primary key is probably either 3 or 4 columns,
believe that the primary key would likely contain Make and Model,
but we aren't sure what the other columns might be.

Guess the primary key for the sashelp.cars dataset,
creating the pk output dataset,
filtering the output dataset on key contains Make and Model (case-insensitive),
and processing depth level=3 and 3 to 4 of the column permutations.

From these results, we chose Make Model Drivetrain as a suitable
primary key.

======================================================================

%guess_pk(
   data=sashelp.cars,
   varlist=
        make model type 
      | make model origin
      ~ make model drivetrain 
      ^ make model type origin 
      | make model type drivetrain 
   ,print=Y
)

Following on from the above, we review the data in sashelp.cars,
and believe that the primary key could be one of the combinations
listed in the VARLIST parameter.

Guess the primary key for the sashelp.class dataset,
creating the _guess_pk_ output dataset (default value),
processing only the combination of columns listed in the 
VARLIST parameter.

From these results, we chose Make Model Drivetrain as a suitable
primary key.

======================================================================

%guess_pk(data=sashelp.class,min_level=2,max_level=4,print=Y)

Guess the primary key for the sashelp.class dataset,
creating the _guess_pk_ output dataset (default value),
processing only depth level=2 to 4 permutations
of the columns until a "hit" is found.

======================================================================

%guess_pk(data=sashelp.class,min_level=2,max_level=4,stop=N,print=Y)

Guess the primary key for the sashelp.class dataset,
creating the _guess_pk_ output dataset (default value),
processing only depth level=2 to 4 permutations,
but process all depth levels, do not stop when a "hit" is found.

======================================================================

%guess_pk(data=sashelp.class,level=0,print=Y)

Guess the primary key for the sashelp.class dataset,
creating the _guess_pk_ output dataset (default value),
processing every possible permutation of columns (LEVEL=0)

======================================================================

data shoes;
   * correct the PDV order ;
   format Region Subsidiary Product Stores;
   set sashelp.shoes;
   * remove "duplicate" row ;
   if region='Western Europe' 
  and subsidiary='Copenhagen' 
  and product='Sport Shoe' 
  and stores=1 then 
      delete;
run;

%guess_pk(data=shoes,max_level=5,print=Y)
%guess_pk(data=shoes,max_level=5,drop=sales inventory returns,print=Y)
%guess_pk(data=shoes,level=0,keep=region product subsidiary stores,print=Y)

Guess the primary key for the (corrected) sashelp.shoes dataset,
creating the _guess_pk_ output dataset (default value),
processing permutations from depth level 1 to 5,
until a "hit" is found.

The first invocation returns Inventory, 
since that fact (analysis) data is unique.
This is likely not what you want, since in a production environment
it could become non-unique at any time.

The second invocation returns Product Subsidiary.
While this does uniquely identifiy each row,
I would choose Region Subsidiary Product as the primary key.

The third invocation returns all possible primary keys
within the candidate columns, and confirms that 
Region Subsidiary Product qualifies as a primary key.

======================================================================

%guess_pk(data=sashelp.class,keep=name age sex,print=Y)
%guess_pk(data=sashelp.class,drop=height weight,print=Y)
%guess_pk(data=sashelp.class,drop=height weight,keep=name age,print=Y)
%guess_pk(data=sashelp.class,drop=_numeric_,keep=name--sex,print=Y)

Guess the primary key for the sashelp.class dataset,
creating the _guess_pk_ output dataset (default value),
processing up to MAX_LEVEL=4 permutations (default value)
of the columns until a "hit" is found,
dropping or keeping columns from the source dataset as specified
by the DROP and KEEP parameters.

The normal SAS rules for keeping or dropping variables applies.
Variable lists can also be used.

======================================================================

%guess_pk(
   data=sashelp.shoes
  ,varlist=
      region subsidiary product
    | region subsidiary product stores
  ,print=Y
)

Note the "data bug" in sashelp.shoes.
Drilldown on region=Western Europe, subsidiary=Copenhagen, product=Sport Shoe

%guess_pk(
   data=sashelp.zipcode
  ,varlist=
      city state ^
      zip zip_class ^
      x y
  ,print=Y
)

Note that zip_class is dropped from the candidate column list 
since it contains missing data.

%guess_pk(
   data=sashelp.cars
  ,varlist=
      make model type drivetrain | make | make model | make model type
  ,print=Y
)

Guess the primary key for the specified datasets,
creating the _guess_pk_ output dataset (default value),
considering only the variable list(s) provided by the calling code.

If the end user has a good idea of the potential combination of 
columns that could form the primary key, providing this list can
significantly improve performance rather than using the brute force 
method of processing all possible permutations.

However, this can result in false positives if one of the columns is
a primary key, since all additional combinations containing this column
would also be flagged as a primary key as well.

The VARLIST parameter does not support variable lists
(eg. name--sex, or var1-var20, or prefix:).  
Each variable must be explicitly specified, and in the desired order 
of the primary key.

======================================================================

FREQ Method:
Guess the primary key using PROC FREQ instead of the hash object.
These are most of the above use cases, except using the FREQ method.

The default method is to use the hash object to determine the 
primary key.  Specifiy METHOD=freq if memory constraints prevent
the use of the hash object.

Typically you would not specify method=freq.  You would only specify
method=freq if your first attempt using the hash object aborted 
due to out-of-memory error.

%guess_pk(method=freq,data=sashelp.class)
%guess_pk(method=freq,data=sashelp.zipcode)
%guess_pk(method=freq,data=sashelp.cars,print=Y)
%guess_pk(method=hash,data=sashelp.cars,print=Y)

%guess_pk(
   method=freq,
   data=sashelp.cars,
   out=pk (
      where=(
         prxmatch('/\bmake\b/i',strip(key)) 
     and prxmatch('#\bmodel\b#i',strip(key)) 
      )
   ),
   level=3,
   print=Y
)
%guess_pk(
   method=freq,
   data=sashelp.cars,
   out=pk (
      where=(
         findw(key,'make','','i')
     and findw(key,'model','','i')
      )
   ),
   min_level=3,
   max_level=4,
   print=Y
)
%guess_pk(
   method=freq,
   data=sashelp.cars,
   varlist=
        make model type 
      | make model origin
      ~ make model type origin 
      ^ make model type drivetrain 
   ,print=Y
)

%guess_pk(method=freq,data=sashelp.class,min_level=2,max_level=4,print=Y)
%guess_pk(method=freq,data=sashelp.class,min_level=2,max_level=4,stop=N,print=Y)
%guess_pk(method=freq,data=sashelp.class,level=0,print=Y)

data shoes;
   * correct the PDV order ;
   format Region Subsidiary Product Stores;
   set sashelp.shoes;
   * remove "duplicate" row ;
   if region='Western Europe' 
  and subsidiary='Copenhagen' 
  and product='Sport Shoe' 
  and stores=1 then 
      delete;
run;

%guess_pk(method=freq,data=shoes,max_level=5,print=Y)
%guess_pk(method=freq,data=shoes,max_level=5,drop=sales inventory returns,print=Y)
%guess_pk(method=freq,data=shoes,level=0,keep=region product subsidiary stores,print=Y)

%guess_pk(method=freq,data=sashelp.class,keep=name age sex,print=Y)
%guess_pk(method=freq,data=sashelp.class,drop=height weight,print=Y)
%guess_pk(method=freq,data=sashelp.class,drop=height weight,keep=name age,print=Y)
%guess_pk(method=freq,data=sashelp.class,drop=_numeric_,keep=name--sex,print=Y)

%guess_pk(
   method=freq,
   data=sashelp.shoes
  ,varlist=
      region subsidiary product
    | region subsidiary product stores
  ,print=Y
)

%guess_pk(
  method=freq,
   data=sashelp.zipcode
  ,varlist=
      city state ^
      zip zip_class ^
      x y
  ,print=Y
)

%guess_pk(
   method=freq,
   data=sashelp.cars
  ,varlist=
      make model type drivetrain | make | make model | make model type
  ,print=Y
)

======================================================================

proc sql noprint;
   create table _columns_ as
   select name
   from dictionary.columns
   where libname='SASHELP' and memname='CARS'
   order by varnum;
quit;
%get_permutations(data=_columns_,var=name,level=0);

This is not a use case for %guess_pk per se, but rather an example 
of the number of column permutations that can be generated from a 
relatively small dataset.  The number of permutations increases 
exponentially depending on the number of columns.  
This can result in a SIGNIFCANT number of permutations.  

Keep this in mind if you intend to use MAX_LEVEL=0 in %guess_pk.

I recommend you use VARLIST, KEEP, and/or DROP to limit the number
of column permutations if you have a very "wide" dataset.

But sure, if you have absolutely no idea which column or combination
of columns might possibly be the primary key, then brute force may be
the only option.  Depending on your data volume (number of rows)
this approach could take a very long time to return results.

======================================================================

Error Testing:

%guess_pk()

An input dataset or view (including RDBMS tables) must be specified.

%guess_pk(data=doesnotexist)

The input dataset or view must exist.

%guess_pk(data=sashelp.class,varlist=foo)
%guess_pk(data=sashelp.class,keep=foo)
%guess_pk(data=sashelp.class,drop=foo)

If VARLIST | KEEP | DROP is specified, 
every variable specified must exist in the input dataset.

%guess_pk(data=sashelp.class,varlist=name,max_level=)

MAX_LEVEL is a required parameter.

%guess_pk(data=sashelp.class,varlist=name,max_level=-1)

MAX_LEVEL must be a NONNEGATIVE number.

%guess_pk(data=sashelp.class,varlist=name,out=)

OUT is a required parameter and must be a valid output dataset name.

%guess_pk(data=sashelp.class,varlist=name,method=foo)

Valid values for the METHOD parameter are HASH | FREQ (case-insensitive).

----------------------------------------------------------------------
Notes:

This macro creates working datasets with a naming convention
using leading and trailing underscores, i.e. _<dataset name>_.
If your session also uses this naming convention for your datasets
there is a slight chance of dataset name collision.

The default output dataset name is _<name of macro>_, i.e.
_guess_pk_.

I will use the term "dataset" to mean dataset, view, RDBMS table,
or RDBMS view.

For this macro, "primary key" is defined as the column or 
combination of columns that uniquely identify a row in the dataset.
Therefore, when de-duping rows based on the primary key,
the count of each primary key will be 1, and the total row count
of the de-duped primary keys will equal the row count of the 
source dataset.

The primary key is also defined as the minimum number of columns that
uniquely identified a row in the dataset.  
For example, if "foo bar" and "foo bar blah baz" both uniquely identify a row, 
then only "foo bar" will be returned, unless max_level=0 is specified.

However, once a "hit" is made, the remaining permutations at that
"level" will also be processed, in case of "ties".  For example, if
"foo bar", "bar blah", and "blah baz" all uniquely identify a row,
then they will all be returned for further investigation by the end
user in "breaking the tie" and deciding on the primary key.
But, "foo bar blah" or "foo bar blah baz" would not be returned,
since they are at a deeper level of column permutations.

Only columns that are NOT NULL will be considered for primary keys.
In other words, if the column contains any missing (NULL) values,
that column is removed from the list of columns to be considered as
contributing to the primary key.

If the VARLIST parameter is specified, the KEEP and/or DROP parameters
are ignored, and no column permutations are generated.
The VARLIST(s) are the column permutations that will be processed.

Multiple VARLISTs can be spefified, using either the pipe (|),
tilde (~), or caret (^) characters as delimiters between the individual
VARLISTs.  See examples above.

If both KEEP and DROP are specified, the DROP list will be applied
first, then the KEEP list will be applied to those results.
In practice, this usually results in the KEEP list taking precedence,
except when the DROP and KEEP lists overlap, such as
DROP=_numeric_, KEEP=name age sex.  In this case, only
name sex would be used.

This macro does not cater for space separated variables, i.e.
N'This variable contains spaces'.  If you have such a dataset or table,
use a view to map space separated variables into SAS-compliant variable
names.

This macro uses the hash object to test for the uniqueness of the key.
The default behaviour of a single valued hash object is to reject the
insertion of duplicate key values.  The return code from the attempted
insertion can be used to abort the processing of a key as soon as a
duplicate has been encountered.  This results in significant performance
gains, especially for large data volumes.

However, if you have very large data volumes, it is possible that the hash
object approach could result in out-of-memory error.  If that happens,
specify METHOD=freq.  This will use PROC FREQ instead of the hash
object to determine the primary key, at the expense of performance.

This macro uses the MD5 hash function to create the key from the 
concatenation of the subject column(s).  This is done to create a 
smaller memory footprint for the hash object or proc freq processing.

If METHOD=hash, reviewing the row counts read for each key will tell
you where the first duplicate occurred.  You can then review the
data around that row number to give you an idea of additional
columns to add to the proposed key.  
Review the log output for the VARLIST examples above for more details.

--------------------------------------------------------------------*/

%macro guess_pk
/*--------------------------------------------------------------------
Guess the primary key of a SAS dataset or RDBMS table.
--------------------------------------------------------------------*/
(DATA=         /* Input dataset (REQ).                              */
,OUT=work._guess_pk_
               /* Output dataset (REQ).                             */
               /* The default value is work._guess_pk_.             */
,VARLIST=      /* Space separated variable list (Opt).              */
               /* If specified, this variable list will be used     */
               /* instead of derived column permutations.           */
               /* Multiple variable lists can be specified,         */
               /* separated by |, ~, or ^.                          */
               /* All variables must exist in the DATA dataset.     */
,KEEP=         /* Space separated variable list (Opt).              */
               /* If specified, only these variables will be        */
               /* considered in deriving the column permutations.   */
               /* All variables must exist in the DATA dataset.     */
,DROP=         /* Space separated variable list (Opt).              */
               /* If specified, these variables will be dropped     */
               /* from consideration in deriving the columns        */
               /* permutations.                                     */
               /* All variables must exist in the DATA dataset.     */
,LEVEL=1       /* Desired depth level of permutations to generate   */
               /* (REQ).  Default value is 1.                       */
               /* If LEVEL=0, then all column permutations will     */
               /* be generated.  This can result in a significant   */
               /* number of permutations!                           */
,MIN_LEVEL=    /* Starting depth level of permutations to generate  */
               /* (Opt).                                            */
,MAX_LEVEL=4   /* Maximum depth level of permutations to generate   */
               /* (Opt).  Default value is 4.                       */
,STOP=Y        /* Stop processing the next level when a "hit" is    */
               /* found? (REQ).                                     */
               /* Default value is YES.  Valid values are:          */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
,METHOD=HASH   /* Method used to derive the primary key (REQ).      */
               /* Default value is HASH.                            */
               /* Valid values are HASH or FREQ.                    */
,PRINT=N       /* Print the OUT dataset to the Results window? (REQ)*/
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);

%local macro parmerr;
%local line columns i column dsid anobs nobs word num_items;
%local lev lev_count;
%global _found_;  %* this needs to be global ;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0,_case=N)
%parmv(OUT,          _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(VARLIST,      _req=0,_words=1,_case=N)
%parmv(KEEP,         _req=0,_words=1,_case=N)
%parmv(DROP,         _req=0,_words=1,_case=N)
%parmv(LEVEL,        _req=1,_words=0,_case=N,_val=NONNEGATIVE)
%parmv(MIN_LEVEL,    _req=0,_words=0,_case=N,_val=POSITIVE)
%parmv(MAX_LEVEL,    _req=0,_words=0,_case=N,_val=POSITIVE)
%parmv(STOP,         _req=1,_words=0,_case=U,_val=0 1)
%parmv(METHOD,       _req=1,_words=0,_case=U,_val=HASH FREQ)
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

%* Does the dataset exist? ;
%if (%superq(data) ne ) %then %do;
   %if ^(%sysfunc(exist(&data,data)) or
         %sysfunc(exist(&data,view))) %then %do;
      %parmv(_msg=&data does not exist)
      %goto quit;
   %end;
%end;

%* The default column list is all the columns in the dataset ;
%let columns=%varlist(&data);

%* If VARLIST was specified, ignore KEEP or DROP. ;
%* Otherwise, if KEEP and/or DROP were specified, ;
%* build the variable list ;
%if (%superq(varlist) ne ) %then %do;
   %let drop=;
   %let keep=;

   %do i=1 %to %sysfunc(countw(&varlist,%str( |~^)));
      %let column=%scan(&varlist,&i,%str( |~^));
      %if (%sysfunc(findw(&columns,&column,' ',I)) eq 0) %then %do;
         %parmv(_msg=&column does not exist in &data)
         %goto quit;
      %end;
   %end;

   %* The column list is the de-duped list of columns in VARLIST ;
   %let columns=%sysfunc(translate(&varlist,%str(   ),%str(|~^)));
   %let columns=%dedup_mstring(&columns);
%end;
%if (%superq(varlist)%superq(drop)%superq(keep) ne ) %then %do;
   %* I could have used an "all macro" approach using %sysfunc, ;
   %* but I wanted to support variable lists, and submitting code ;
   %* is the most straightforward approach ;
   proc sql noprint;
      create view work._cols_ as 
      select *
      from &data
      (
      %if (%superq(varlist) ne ) %then keep=&columns;
      %if (%superq(drop) ne ) %then drop=&drop;
      %if (%superq(keep) ne ) %then keep=&keep;
      )
      where 0=1;

      %* reset columns macro variable ;
      %let columns=;

      select name into :columns separated by ' '
      from dictionary.columns
      where libname='WORK' and memname='_COLS_'
      order by varnum;

      drop view work._cols_;
   quit;

   %if (%superq(columns) eq ) %then %do;
      %parmv(_msg=Unable to derive column list.  Ensure the DROP and/or KEEP variable list contains valid variables)
      %goto quit;
   %end;
%end;

%* End of additional error checking ;

%* get number of observations in the source dataset ;
%let nobs=-1;
%let dsid=%sysfunc(open(&data));
%if (&dsid gt 0) %then %do;
   %let anobs = %sysfunc(attrn(&dsid,anobs));
   %let nobs  = %eval(%sysfunc(attrn(&dsid,nobs)) - %sysfunc(attrn(&dsid,ndel)));
   %let dsid  = %sysfunc(close(&dsid));
%end;
%else %do;
   %parmv(_msg=Unable to open &data for input);
   %goto quit;
%end;

%* if the engine cannot determine the number of observations then use PROC SQL ;
%if ^(&anobs) %then %do;
   %* Get number of observations ;
   proc sql noprint;
      select count(0) format=32. into :nobs trimmed from &data;
   quit;
%end;

%if (&nobs le 0) %then %do;
   %parmv(_msg=Unable to determine the number of rows in &data);
   %goto quit;
%end;

%* drop any columns containing missing values ;
%macro missing;
%if (&__iter__ gt 1) %then ,;
/* max(missing(&word)) as &word */ /* do not use this, it performs poorly against RDBMS tables */
max(case when &word is null then 1 else 0 end) as &word
%mend;

* eliminate columns containing missing data ;
proc sql noprint;
   create table work._missing_ (compress=no) as
   select
   %loop(&columns,mname=missing)
   from &data;
quit;

proc transpose 
   data=work._missing_ 
   out=work._columns_ (
      compress=no
      keep=_name_ col1
      rename=(_name_=name col1=missing)
      where=(missing=0)
   );
run;

%let num_items=%nobs(work._columns_);

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

%*** CREATE UTILITY MACROS *** ;

%macro varlist_keys;
* no need to derive permutations, the varlist(s) are the permutations. ;
data work._keys_ (compress=no);
   length lname name $32 key $500 buffer $500;
   %* hash to hold the non-missing columns ;
   declare hash h();
   h.defineKey('lname');
   h.defineData('name');
   h.defineDone();
   do until (eof);
      set work._columns_ end=eof;
      lname=lowcase(name);
      h.ref();
   end;
   varlist="%sysfunc(compbl(&varlist))";
   do i=1 to countw(varlist,'|~^');
      call missing(key);
      buffer=scan(varlist,i,'|~^');
      do j=1 to countw(buffer,' ');
         lname=lowcase(scan(buffer,j,' '));
         if (h.find() eq 0) then key=catx(' ',key,name);
      end;
      output;
   end;
   keep key;
   stop;
run;
%mend;

%macro hash_datastep(out);
* use a hash object to determine if this key is unique for the entire dataset ;
data &out;
   length key $500 _key_ $16 rowcnt nobs 8;
   nobs=&nobs;
   declare hash h();
   %loop_control(control=work._keys_,mname=hash_codegen)
   stop;
   keep key nobs rowcnt;
run;
%mend;

%macro hash_codegen;
%* trim trailing blanks ;
%let key=%trim(&key);
h=_new_ hash();
h.defineKey('_key_');
h.defineDone();
eof=0;
do until (eof);
   set &data end=eof;
   key="&key";
   _key_=md5(catx('|',%seplist(&key)));
   if (h.add() ^= 0) then leave;
end;
if (eof) then do;
   rowcnt=h.num_items;
   if (rowcnt=nobs) then do;
      output;
      %* process the rest of this level then end, unless a VARLIST was specified ;
      %if (%superq(varlist) eq ) %then %do; call symputx('_found_',1,'G'); %end;
   end;
end;
h.delete();
%mend;

%macro freq_datastep(out);
%* create skeleton dataset ;
data &out;
   length key $500 rowcnt nobs 8;
   call missing(of _all_);
   stop;
run;

%loop_control(control=work._keys_,mname=freq_codegen)

proc datasets lib=work nowarn nolist;
   delete _count_ _append_;
quit;
%mend;

%macro freq_codegen;
%* trim trailing blanks ;
%let key=%trim(&key);
data work._md5_ / view=work._md5_;
   length _key_ $16;
   set &data;
   _key_=md5(catx('|',%seplist(&key)));
   keep _key_;
run;
proc freq data=work._md5_ noprint;
   tables _key_ / out=work._count_ (drop=percent where=(count gt 1));
quit;
%if (%nobs(work._count_) eq 0) %then %do;
   %* process the rest of this level then end, unless a VARLIST was specified ;
   %if (%superq(varlist) eq ) %then %do; %let _found_=1; %end;

   data work._append_ (compress=no);
      length key $500 rowcnt nobs 8;
      key="&key";
      nobs=&nobs;
      rowcnt=&nobs;  %* not technically correct since it was not derived, but is still accurate ;
   run;

   proc append base=&out data=work._append_;
   run;
%end;
%mend;

%* this macro can run both HASH and FREQ methods ;
%macro runcode(type);
   %if (%superq(varlist) ne ) %then %do;
      %put &line;
      %put >>> Processing VARLIST=%sysfunc(compbl(&varlist)) <<<;
      %put &line;
      %varlist_keys
      %&type._datastep(&out)
   %end;
   %else
   %if (&level eq 0) %then %do;
      %put &line;
      %put >>> Processing All Levels <<<;
      %put &line;
      * get all permutations of the non-missing candidate columns ;
      %get_permutations(data=work._columns_,var=name,out=work._keys_ (compress=no keep=item0 rename=(item0=key)),level=0)
      %&type._datastep(&out)
   %end;
   %else
   %do;
      %let _found_=0;
      %let lev_count=%eval(&min_level-1);
      %do lev=&min_level %to &max_level;
         %put &line;
         %put >>> Processing Level=&lev <<<;
         %put &line;
         %let lev_count=%eval(&lev_count+1);
         * get the permutations of the non-missing candidate columns at this depth level ;
         %get_permutations(data=work._columns_,var=name,out=work._keys_ (compress=no keep=item0 rename=(item0=key)),level=&lev)
         %&type._datastep(work._primary_key_%sysfunc(putn(&lev,z2.))_ (compress=no))
         %if (&_found_ and &stop) %then %let lev=&max_level;
      %end;
      * concatenate each level into the final consolidated dataset ;
      data &out;
         set
         %do lev=&min_level %to &lev_count;
            work._primary_key_%sysfunc(putn(&lev,z2.))_
         %end;
         ;
      run;

      proc datasets lib=work nowarn nolist;
         delete _primary_key_:;
      quit;
   %end;
%mend;

%if (&method eq HASH) %then %do;
   %runcode(hash)
%end;
%else
%if (&method eq FREQ) %then %do;
   %runcode(freq)
%end;

%if (&print) %then %do;
   title "Primary Keys for &data";
   proc print data=&out;
   run;
   title;
%end;

%quit:

%symdel _found_ / nowarn;

%mend;

/******* END OF FILE *******/
