/*=====================================================================
Program Name            : varlist.sas
Purpose                 : Returns a string containing a space separated 
                          list of variables in a dataset
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 06DEC2007
Program Version #       : 1.0

=======================================================================

Copyright (c) 2016 Scott Bass (sas_l_739@yahoo.com.au)

This code is licensed under the Unlicense license.
For more information, please refer to http://unlicense.org/UNLICENSE.

=======================================================================

Modification History    :

Programmer              : Scott Bass
Date                    : 12AUG2016
Change/reason           : Changed %parmv call on DATA parameter to
                          allow ds options (i.e. drop and keep)
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%put %varlist(sashelp.class);
%put %varlist(sashelp.shoes (keep=region--stores));
%put %varlist(sashelp.stocks (drop=volume adjclose));

Outputs the variable list of the source dataset, honouring any keep=
or drop= options.

Often this would be assigned to a macro variable, i.e.
%let varlist=%varlist(sashelp.class)

-----------------------------------------------------------------------
Notes:

---------------------------------------------------------------------*/

%macro varlist
/*---------------------------------------------------------------------
Return a string containing a space separated list of variables in a
dataset.
---------------------------------------------------------------------*/
(DATA          /* Input dataset (REQ)                                */
);

%local macro parmerr;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(data,_req=1,_words=1,_case=U)

%if (&parmerr) %then %goto quit;

%* open dataset for input ;
%let dsid=%sysfunc(open(&data,i));

%* if open failed, abort ;
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open &data);
   %goto quit;
%end;

%do i=1 %to %sysfunc(attrn(&dsid,nvars));
%sysfunc(varname(&dsid,&i))  /* do not indent this statement */
%end;
%let dsid=%sysfunc(close(&dsid));

%quit:
%mend;

/******* END OF FILE *******/
