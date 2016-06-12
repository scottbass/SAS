/*====================================================================
Program Name            : varlist.sas
Purpose                 : Returns a space or comma delimited variable
                          list based on a prxmatch filter
SAS Version             : SAS 9.2
Input Data              : SAS input dataset
Output Data             : Variable list

Macros Called           : parmv, seplist

Originally Written by   : Scott Bass
Date                    : 13DEC2011
Program Version #       : 1.0

======================================================================

Modification History    : 

====================================================================*/

/*--------------------------------------------------------------------
Usage:

%put %varlist(data=sashelp.shoes);                    * all variables in varnum order ;
%put %varlist(data=sashelp.shoes,filter=_numeric_);   * all numeric variables ;
%put %varlist(data=sashelp.shoes,filter=_character_); * all character variables ;
%put %varlist(data=sashelp.shoes,filter=sales);       * "sales" variable ;
%put %varlist(data=sashelp.shoes,filter=s);           * all variables CONTAINING "s" ;
%put %varlist(data=sashelp.shoes,filter=^s);          * all variables beginning with "s" ;
%put %varlist(data=sashelp.shoes,filter=s$);          * all variables ending with "s" ;
%put %varlist(data=sashelp.shoes,filter=\bs);         * all variables matching "word boundary+s" ;
%put %varlist(data=sashelp.shoes,filter=s\b);         * all variables matching "s+word boundary" ;
%put %varlist(data=sashelp.shoes,filter=sales|inventory); * "sales" and "inventory" variables ;
%put %varlist(data=sashelp.shoes,filter=sales|inventory,exclude=YES); * all variables EXCEPT "sales" and "inventory" ;

%put %varlist(data=sashelp.shoes,dlm=C);              * all variables, delimited by comma ;
%put %varlist(data=sashelp.shoes,filter=sales|inventory,exclude=YES, dlm=C);  * most variables, delimited by comma ;

======================================================================

Error checking:

%put %varlist(data=does_not_exist);
%put %varlist(data=sashelp.shoes,filter=does_not_exist);

----------------------------------------------------------------------
Notes:

The filter parameter allows for powerful variable filtering, but
does require a good grasp of the subtleties of regular expressions.

It is much easier to negate the search results (EXCLUDE=YES) than to
come up with a regular expression that can exclude words.  It CAN be
done, but the regular expression contains macro special characters,
which becomes a macro quoting nightmare.

For example:  \b(?!(?:sales|inventory)\b)[\w]+\b

See
http://www.codinghorror.com/blog/2005/10/excluding-matches-with-regular-expressions.html
or Google "Regular expression exclude words" for more details.

This macro is not meant to be an all-encompassing macro that supports
every possible filtering technique.  It will usually be used when you
need a variable list for another macro, and want all variables
except for certain variables.  I also wanted this macro to be a
function-style macro for greater syntax flexibility.

For more control, use the SQL dictionary tables.  For example:

proc sql noprint;
   select name into :variables separated by " "
   from dictionary.columns
   where
      libname="SASHELP"
      and
      memname="SHOES"
      and
      format like "DOLLAR%"
   order by
      name descending
   ;
quit;
%put &variables;

The dictionary tables give you more metadata with which to filter and
format (eg. sort) the returned values, but will be a bit slower than
this macro (depending on the number of libraries allocated) and is not
as syntactically flexible as this macro.

--------------------------------------------------------------------*/

%macro varlist
/*--------------------------------------------------------------------
Returns a space or comma delimited variable list based on a prxmatch
filter
--------------------------------------------------------------------*/
(DATA=         /* Source dataset (REQ).                             */
,FILTER=       /* Variable list filter (Opt).                       */
               /* If not specified then all variables are returned. */
               /* Must be specified as a prxmatch regular           */
               /* expression.                                       */
,EXCLUDE=NO    /* Exclude variables matching the filter? (REQ).     */
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
,DLM=S         /* Output delimiter (REQ).                           */
               /* Valid values are S (Space) and C (Comma)          */
);

%local macro parmerr varlist rx dsid varnum oper;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0,_case=N)
%parmv(EXCLUDE,      _req=1,_words=0,_case=U,_val=0 1)
%parmv(DLM,          _req=1,_words=0,_case=U,_val=S C)

%if (&parmerr) %then %goto quit;

%* make sure the filter (if specified) is valid ;
%if (%superq(filter) ne ) %then %do;
   %if (not %sysfunc(prxmatch(/_NUMERIC_|_CHARACTER_/io,%superq(filter)))) %then %do;
      %let rx=%sysfunc(prxparse(/%superq(filter)/io));
      %if (&rx le 0) %then %do;
         %parmv(_msg=Invalid PRXMATCH regular expression: %super(filter))
         %goto %quit;
      %end;
   %end;
%end;

%* open input dataset ;
%let dsid=%sysfunc(open(&data));
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open &data dataset)
   %goto quit;
%end;

%* get number of variables ;
%let varnum=%sysfunc(attrn(&dsid,nvars));
%if (&varnum le 0) %then %do;
   %parmv(_msg=Unable to obtain the number of variables in &data dataset)
   %goto quit;
%end;

%* was exclude specified? ;
%if (not &exclude) %then
   %let oper=;
%else
   %let oper=NOT;

%* return list of variables that match the filter ;
%let varlist=;
%do i=1 %to &varnum;
   %let varname=%sysfunc(varname(&dsid,&i));
   %if (%sysfunc(prxmatch(/\b_NUMERIC_\b/io,%superq(filter)))) %then %do;
      %if (%sysfunc(vartype(&dsid,&i)) eq N) %then
         %let varlist=&varlist &varname;
   %end;
   %else
   %if (%sysfunc(prxmatch(/\b_CHARACTER_\b/io,%superq(filter)))) %then %do;
      %if (%sysfunc(vartype(&dsid,&i)) eq C) %then
         %let varlist=&varlist &varname;
   %end;
   %else
   %if (%superq(filter) ne ) %then %do;
      %if &oper (%sysfunc(prxmatch(&rx,&varname))) %then
         %let varlist=&varlist &varname;
   %end;
   %else %do;
      %let varlist=&varlist &varname;
   %end;
%end;

%if (&dlm eq S) %then %do;
/* do not indent */
&varlist
%end;
%else
%if (&dlm eq C) %then %do;
/* do nto indent */
%seplist(&varlist)
%end;

%quit:

%let dsid=%sysfunc(close(&dsid));
%if (&rx ne ) %then %syscall prxfree(rx);

%mend;

/******* END OF FILE *******/
