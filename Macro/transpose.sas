/*=====================================================================
Program Name            : transpose.sas
Purpose                 : Transpose the input dataset.
SAS Version             : SAS 9.1.3
Input Data              : Input  SAS dataset or view
Output Data             : Output SAS dataset

Macros Called           : parmv, loop, seplist, kill

Originally Written by   : Scott Bass
Date                    : 24MAY2010
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

+====================================================================*/

/*---------------------------------------------------------------------
Usage:

Note:  only a few common usage examples are listed here,
see the macro code for all available parameters.

%transpose(
   data=in,
   out=out,
   by=studyid usubjid visit,
   var=diabp height pulse sysbp temp weight,
   name=name,
   label=,
   col=measures
);

Transpose dataset in,
   creating dataset out,
   by studyid usubjid visit,
   for variables diabp height pulse sysbp temp weight,
   rename _name_ variable to name,
   drop _label_ variable,
   rename col1 to measures

=======================================================================

%transpose(
   data=in,
   out=out,
   by=studyid usubjid visit,
   var=diabp height pulse sysbp temp weight,
   notsorted=Y
);

Transpose dataset in,
   creating dataset out,
   by studyid usubjid visit,
   for variables diabp height pulse sysbp temp weight,
   add the notsorted option to the by statement
   and do not sort the input dataset

=======================================================================

%transpose(
   by=studyid usubjid visit,
   var=diabp height pulse sysbp temp weight,
);

Transpose the last dataset created (&syslast),
   overwriting it,
   by studyid usubjid visit,
   for variables diabp height pulse sysbp temp weight

-----------------------------------------------------------------------
Notes:

By default, the input dataset is sorted by PROC SORT.  However, if this
dataset is already sorted, PROC SORT will just copy the input dataset
to the output dataset.

If the NOTSORTED parameter is specified, the input dataset is not
sorted, and the notsorted option is added to the BY statement.

If the NOSORT parameter is specified, the input dataset is not sorted.

It is unlikely that the BY variable(s) would be blank, but
PROC TRANSPOSE does allow it, see the documentation for details.
If blank, all observations in the source dataset are transposed.

It is unlikely that the VAR variable(s) would be blank, but
PROC TRANSPOSE does allow it, see the documentation for details.
If blank, all numeric variables in the source dataset are transposed.

If the NAME and/or LABEL parameters are blank, the _NAME_ and/or
_LABEL_ variables are dropped from the output dataset.  Otherwise
the PROC TRANSPOSE NAME and/or LABEL options are used.

If the COL parameter is specified, the output columns COL1 - COLn are
renamed according to the list of names specified in the COL parameter.
If there are more COL# columns in the output dataset than items
specified in the COL parameter, the additional columns are not renamed.
If there are more COL# items specified in the COL parameter than
COL# columns in the output dataset, a Warning message is generated.

Dataset options can be specified on the input or output datasets, but
best practice is to use the macro parameters where possible
(eg. name/label/col/where parameters instead of
drop/keep/rename/where dataset options).

---------------------------------------------------------------------*/

%macro transpose
/*---------------------------------------------------------------------
Transpose the input dataset
---------------------------------------------------------------------*/
(
/* PROC TRANSPOSE Options */

 DATA=&syslast /* Input dataset (REQ).                               */
               /* Default is &syslast (last dataset created).        */
,OUT=&syslast  /* Output dataset (REQ).                              */
               /* Default is &syslast (last dataset created).        */
,BY=           /* By variables (Opt).                                */
               /* By variables for PROC TRANSPOSE.                   */
               /* If not specified then every observation in the     */
               /* input dataset is transposed.                       */
,VAR=          /* Var variables (Opt).                               */
               /* Var variables for PROC TRANSPOSE.                  */
               /* If not specified then every numeric variable in    */
               /* the input dataset is transposed.                   */
,PREFIX=       /* Transposed column prefix (Opt).                    */
               /* If blank, the PROC TRANSPOSE default COL is used.  */
,SORT=Y        /* Sort the input dataset? (Opt).                     */
               /* If 1, the input dataset is sorted before being     */
               /* transposed by PROC TRANSPOSE.                      */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,NOTSORTED=N   /* Add the NOTSORTED option to the BY statement? (Opt)*/
               /* If Y, the SORT= parameter is set to N.             */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,ID=           /* Variable whose formatted value names the output    */
               /* columns (Opt).  Only one of COL= or ID= parameters */
               /* can be specified (not both).                       */
,IDLABEL=      /* Variable whose formatted value labels the output   */
               /* columns (Opt).  Can only be used if the ID=        */
               /* parameter is also specified.                       */
,LET=          /* Allow duplicate values for an ID variable? (Opt).  */
               /* If specified, only the last occurence of the ID    */
               /* variable in the dataset or BY group is transposed. */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,COPY=         /* Copy variables directly from the input to output   */
               /* dataset without transposing them.                  */

/* Input Dataset Options */

,WHERE=        /* Apply where clause to INPUT dataset (Opt).         */
               /* Do not specify the "WHERE=" portion of the clause. */
               /* Ex: var1 in (1,2,3) and var2="whatever"            */
,FORMAT=       /* Apply temporary format to input dataset variables  */
               /* (Opt).  Ex: var1 $mychrfmt. var2 mynumfmt.         */
,LBL=          /* Apply temporary labels to input dataset variables  */
               /* (Opt).  Ex: var1="Label 1" var2="Label 2"          */

/* Output Dataset options */

,COL=          /* Rename PROC TRANSPOSE COL# variable(s)? (Opt).     */
               /* Default value is blank (no rename).  Set to list   */
               /* of valid SAS variable name(s) to rename COL1 - COL#*/
               /* to new values.                                     */
,NAME=_NAME_   /* Rename PROC TRANSPOSE _NAME_ variable? (Opt).      */
               /* Default value is _NAME_ (keep variable w/o rename).*/
               /* Set to blank value to drop _NAME_ variable, set to */
               /* valid SAS variable name to rename to new value.    */
,LABEL=_LABEL_ /* Rename PROC TRANSPOSE _LABEL_ variable? (Opt).     */
               /* Default value is _LABEL_ (keep variable w/o rename)*/
               /* Set to blank value to drop _LABEL_ variable, set to*/
               /* valid SAS variable name to rename to new value.    */
);

%local macro parmerr drop rename options;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(OUT,          _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(BY,           _req=0,_words=1,_case=U)
%parmv(VAR,          _req=0,_words=1,_case=U)
%parmv(PREFIX,       _req=0,_words=0,_case=N)
%parmv(SORT,         _req=0,_words=0,_case=U,_val=0 1)
%parmv(NOTSORTED,    _req=0,_words=0,_case=U,_val=0 1)
%parmv(ID,           _req=0,_words=1,_case=U)
%parmv(IDLABEL,      _req=0,_words=1,_case=U)
%parmv(LET,          _req=0,_words=0,_case=U,_val=0 1)
%parmv(COPY,         _req=0,_words=1,_case=U)

%parmv(WHERE,        _req=0,_words=1,_case=N)
%parmv(FORMAT,       _req=0,_words=1,_case=U)
%parmv(LBL,          _req=0,_words=1,_case=N)

%parmv(NAME,         _req=0,_words=0,_case=U)
%parmv(LABEL,        _req=0,_words=0,_case=U)
%parmv(COL,          _req=0,_words=1,_case=U)

%if (&parmerr) %then %goto quit;

%* additional error checking ;
%* only one of COL or ID can be specified ;
%if (%superq(col) ne ) and (%superq(id) ne ) %then
   %parmv(_msg=Only one of COL or ID parameters can be specified - you cannot specify both);

%* IDLABEL requires that ID is also specified ;
%if (%superq(idlabel) ne ) %then
   %if (%superq(id) eq ) %then
      %parmv(_msg=The IDLABEL parameter requires that the ID parameter is also specified);

%if (&parmerr) %then %goto quit;

%* ensure SORT, NOTSORTED, and LET are boolean values ;
%let sort      = %eval(&sort eq 1);
%let notsorted = %eval(&notsorted eq 1);
%let let       = %eval(&let eq 1);

%* create macro to rename COL# columns ;
%macro _trans_rename;
   %local temp;
   %let temp=&prefix;
   %if (&temp eq ) %then %let temp=COL;
   &temp&__iter__=&word
%mend;

%* sort the input dataset ;
%* if NOTSORTED was specified do not sort ;

%* I used PROC SORT instead of an SQL view because, ;
%* if the input dataset is already sorted, it will ;
%* just be copied to the temporary dataset ;
%if (&notsorted) %then %let sort=0;
%if ((&sort) and (%superq(by) ne )) %then %do;
   proc sort data=&data out=_transpose_;
      by &by;
   run;
   %let data=_transpose_;  %* change value of &data parameter ;
%end;

%* Were output dataset options specified? ;
%let out_opts=0;
%let start=%sysfunc(findc(%superq(out),%str(%(),1));
%if (&start) %then %do;
   %let out_opts=1;
   %let options=%substr(%superq(out),&start+1);
   %let end=%sysfunc(findc(%superq(options),%str(%)),-9999));
   %let options=%substr(%superq(options),1,&end-1);  %* assume proper trailing paren ;
   %let out=%substr(%superq(out),1,&start-1);
%end;

%* Or, were output dataset options specified via macro parameters? ;
%if (&name&label&col ne ) %then %do;
   %let out_opts=1;
   %let drop=;
   %let rename=;
   %if (&name  eq ) %then %let drop=&drop _NAME_;
   %if (&label eq ) %then %let drop=&drop _LABEL_;
   %if (&col   ne ) %then %let rename=%loop(&col,mname=_trans_rename);
   %let drop=&drop; %* removes leading space ;
%end;

%* transpose the dataset ;
proc transpose data=&data out=&out
   %if (&out_opts) %then %do;
      (
      %if (%superq(drop) ne ) %then %do;
         drop=&drop
      %end;
      %if (%superq(rename) ne ) %then %do;
         rename=(&rename)
      %end;
      %if (%superq(options) ne ) %then %do;
         %unquote(%superq(options))
      %end;
      )
   %end;
   %if (%superq(name) ne %str( ) and %superq(name) ne _NAME_) %then %do;
      name=&name
   %end;
   %if (%superq(label) ne %str( ) and %superq(label) ne _LABEL_) %then %do;
      label=&label
   %end;
   %if (%superq(prefix) ne ) %then %do;
      prefix=&prefix
   %end;
   %if (&let) %then %do;
      let
   %end;
   ;
   %if (%superq(where) ne ) %then %do;
      where %unquote(&where);
   %end;
   %if (%superq(by) ne ) %then %do;
      by &by
      %if (&notsorted) %then %do;
         notsorted
      %end;
      ;
   %end;
   %if (%superq(var) ne ) %then %do;
      var &var;
   %end;
   %if (%superq(copy) ne ) %then %do;
      copy &copy;
   %end;
   %if (%superq(id) ne ) %then %do;
      id &id;
   %end;
   %if (%superq(idlabel) ne ) %then %do;
      idlabel &idlabel;
   %end;
   %if (%superq(format) ne ) %then %do;
      format %unquote(&format);
   %end;
   %if (%superq(lbl) ne ) %then %do;
      label %unquote(&lbl);
   %end;
run;

%* delete working dataset ;
%if (%sysfunc(exist(_transpose_))) %then %do;
   %kill(delete=_transpose_)
%end;

%quit:

%mend;

/******* END OF FILE *******/