/*====================================================================
Program Name            : get_dups.sas
Purpose                 : Identifies duplicate records given a list
                          of variables
SAS Version             : SAS 9.3
Input Data              : SAS dataset or view
Output Data             : SAS dataset containing duplicate records

Macros Called           : parmv
                          seplist

Originally Written by   : Michael Raithel
Date                    : 11JUL2016
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

Based on original work by Michael Raithel.
Used with permission.

=======================================================================

Modification History    :

Programmer              : Scott Bass
Date                    : 21JUL2016
Change/reason           : Modified from original work created by
                          Michael Raithel posted to LinkedIn and 
                          to his blog.
                          http://michaelraithel.blogspot.com.au/2016/07/hack-312-identifying-duplicate-variable.html
Program Version #       : 1.1

+===================================================================*/

/*--------------------------------------------------------------------
Usage:

Note:  sashelp.cars has a few records with dups for make and model,
       so use this dataset as our test data.

Pretend you are trying to determine the keys for sashelp.cars,
i.e. the combination of variables that will uniquely identify the record.

=======================================================================

%get_dups(data=sashelp.cars,varlist=make)

   Displays duplicate records for varlist=model 
   using PROC MEANS (default)

=======================================================================

%get_dups(data=sashelp.cars,varlist=make,proc=sql)

   Displays duplicate records for varlist=model 
   using PROC SQL

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model)

   Displays duplicate records for varlist=make model
   using PROC MEANS (default)

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model,proc=sql)

   Displays duplicate records for varlist=make model
   using PROC SQL

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model drivetrain)

   Displays duplicate records for varlist=make model drivetrain
   using PROC MEANS (should be no duplicates)

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model drivetrain,proc=sql)

   Displays duplicate records for varlist=make model drivetrain
   using PROC SQL (should be no duplicates)

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model,method=class)

   Displays duplicate records for varlist=make model
   using the CLASS statement of PROC MEANS (default value)
   
=======================================================================

%get_dups(data=sashelp.cars,varlist=make model,method=by)

   This will generate an error, since sashelp.cars is not pre-sorted
   by make model, the method=by, and sort=n is the default setting.

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model,method=by,sort=y)

   Displays duplicate records for varlist=make model
   using the BY statement of PROC MEANS,
   sorting the input dataset. 

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model,print=y)

   Displays duplicate records for varlist=make model
   printing the duplicate records
   (default is to only create a duplicates dataset for post-processing
    in the calling program)

=======================================================================

%get_dups(data=sashelp.cars,varlist=make model,print=y,proc=sql)

   Displays duplicate records for varlist=make model
   printing the duplicate records
   (default is to only create a duplicates dataset for post-processing
    in the calling program)

=======================================================================

Error checking: 

%get_dups(data=doesnotexist,varlist=make model)

%get_dups(data=sashelp.cars,varlist=make foo model)

%get_dups(data=sashelp.cars,varlist=make model,method=foo)

%get_dups(data=sashelp.cars,varlist=make model,proc=foo)

%get_dups(data=sashelp.cars(where=(make="BMW")),varlist=make model)

----------------------------------------------------------------------
Notes:

This macro is useful for determining the natural key(s) for a dataset
or table.  The natural key(s) will uniquely identify a record,
so no duplicates will be returned.

This macro will use either PROC MEANS or PROC SQL to determine whether
duplicate records exist for a given variable list.

PROC MEANS will usually (always?) perform better than PROC SQL,
since "under the covers" PROC SQL will sort the input dataset 
by the variable list.

However, PROC MEANS collapses the data into a single record per
combination of variable list data, while PROC SQL will print all
records which have duplicates.  

By default, this macro only produces a dataset (work.dups) containing
the duplicate records.  This dataset can then be post-processed by the
calling program.  Specify PRINT=Y to optionally print the duplicate 
records to the default output destination.

PROC MEANS Only:

By default, the CLASS statement is used to group the variable list data.
However, when the CLASS statement is used, PROC MEANS will group the 
data in memory.  On rare occasions, with very large datasets and 
low cardinality of variable list data, this can result in an 
out-of-memory exception.  In this scenario, specify METHOD=BY so that 
PROC MEANS will use the BY statement to group the variable list data.

By default, when METHOD=BY is specified, it is assumed that the 
input data is (either physically or logically) sorted by the varlist.
Specify SORT=Y for this macro to sort the input dataset to a 
temporary dataset before calling PROC MEANS.

The SORT parameter is ignored unless METHOD=BY.

Also note that, if your data is already pre-sorted, BY processing
will usually give better performance than CLASS processing.

--------------------------------------------------------------------*/

%macro get_dups
/*--------------------------------------------------------------------
Identifies duplicate records given a list of variables.
--------------------------------------------------------------------*/
(DATA=         /* Input dataset (REQ).                              */
               /* Either one- or two-level names are supported.     */
               /* Dataset options (i.e. WHERE=) are not supported.  */
,VARLIST=      /* Space-separated variable list (REQ).              */
               /* The variable list must exist in the input dataset.*/
,PROC=MEANS    /* Procedure used to identify duplicates (REQ).      */
               /* Default value is MEANS.                           */
               /* Valid values are MEANS or SQL.                    */
               /* MEANS performs better but SQL lists ALL records   */
               /* with duplicate values, not just a summary record. */
,METHOD=CLASS  /* Method used to group variable list data (REQ).    */
               /* Valid values are CLASS or BY.                     */
               /* Default value is CLASS.                           */
               /* Only used when PROC=MEANS.                        */
,SORT=N        /* Sort input dataset? (Opt).                        */
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
               /* If YES, the input dataset is sorted to a temporary*/
               /* dataset for use by PROC MEANS.                    */
               /* Only used when PROC=MEANS.                        */
,PRINT=N       /* Print duplicates dataset? (Opt).                  */
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
               /* If YES, the duplicates dataset is printed to the  */
               /* default output destination.                       */
);

%local macro parmerr dsid i src;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,          _req=1,_words=0,_case=U)
%parmv(VARLIST,       _req=1,_words=1,_case=U)
%parmv(PROC,          _req=1,_words=0,_case=U,_val=MEANS SQL)
%parmv(METHOD,        _req=1,_words=0,_case=U,_val=CLASS BY)
%parmv(SORT,          _req=0,_words=0,_case=U,_val=0 1)
%parmv(PRINT,         _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* were dataset options specified? ;
%if (%index(%superq(data),%str(%())) %then %do;
   %parmv(_msg=Dataset options are not allowed with this macro)
   %goto quit;
%end;

%* does the input dataset exist? ;
%if not (%sysfunc(exist(&DATA,data)) or %sysfunc(exist(&DATA,view))) %then %do;
   %parmv(_msg=The &DATA dataset does not exist)
   %goto quit;
%end;

%* are the variables in the input dataset? ;
%let dsid=%sysfunc(open(&DATA,I));  %* I should probably error check this, but... ;
%let i=1;
%let var=%scan(&VARLIST,&i,%str( ));
%do %while(&var ne );
   %if (%sysfunc(varnum(&dsid,&var)) le 0) %then %do;
      %parmv(_msg=The variable &var is not present in the &DATA dataset)
      %let dsid=%sysfunc(close(&dsid));
      %goto quit;
   %end;
   %let i=%eval(&i+1);
   %let var=%scan(&VARLIST,&i,%str( ));
%end;
%let dsid=%sysfunc(close(&dsid));

%if (&PROC eq SQL) %then %do;
   proc sql noprint;
      create table work.dups as
      select
         count(1) as count, *
      from
         &DATA
      group by
         %seplist(&varlist)
      having count > 1
   ;
%end;
%else
%if (&PROC eq MEANS) %then %do;
   %* does the data need to be sorted? ;
   %let src=&DATA;

   %if (&METHOD eq BY) and (&SORT) %then %do;
      libname workspde spde "%sysfunc(pathname(work))" temp=yes;
      proc sort data=&DATA out=workspde._sorted_;
         by &VARLIST;
      run;
      %let src=workspde._sorted_;
   %end;

   %* use PROC MEANS to create the duplicates dataset ;
   proc means data=&src nway noprint missing;
      &METHOD &VARLIST;
      output out=work.dups (
         drop=_type_ 
         rename=(_freq_=count)
         where=(count > 1) 
      ) sum=;
   run;
%end;

%if (&PRINT) %then %do;
   title1 "Duplicate Values in the &DATA dataset";
   title2 "Duplicate Count for Variables: &VARLIST";
   proc print data=work.dups noobs label;
   %if (&proc eq MEANS) %then %do;
      var count &VARLIST;
   %end;
      label count = "Duplicate Count";
   run;
   title;
%end;

%quit:

%mend;

/******* END OF FILE *******/
