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
Date                    : 07JUL2017
Change/reason           : Added UPCASE parameter
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%put %varlist(sashelp.shoes);

Outputs the variable list of the source dataset in PDV order.

Often this would be assigned to a macro variable, i.e.
%let varlist=%varlist(sashelp.class)

======================================================================

%put %varlist(sashelp.shoes,upcase=Y);

Same as above but uppercasing the returned variable list;

======================================================================

Error Processing:

%put %varlist(sashelp.doesnotexist);

%put %varlist(sashelp.shoes(keep=Region Subsidiary Sales Returns));
%put %varlist(sashelp.shoes(keep=Region--Returns));
%put %varlist(sashelp.shoes(keep=_character_));
%put %varlist(sashelp.shoes(keep=_numeric_));
%put %varlist(sashelp.shoes (drop=Region Subsidiary Sales Returns));
%put %varlist(sashelp.shoes (drop=Region--Returns));
%put %varlist(sashelp.shoes (drop=_character_));
%put %varlist(sashelp.shoes (drop=_numeric_));

-----------------------------------------------------------------------
Notes:

This macro is a "pure macro" and returns an rvalue.  It must be on the 
right side of an assignment statement, or otherwise used where an 
rvalue is appropriate, eg. %put %varlist(sashelp.class).

Note that dataset options (esp. KEEP= and DROP=) are not allowed.
This is due to a shortcoming in the VARNAME function, since it is 
reading the variable number from the dataset header and not from a
logical PDV.  If you remove the error checking on dataset options
and run the above error checks, you will get warnings from the 
varname function.

---------------------------------------------------------------------*/

%macro varlist
/*---------------------------------------------------------------------
Return a string containing a space separated list of variables in a
dataset.
---------------------------------------------------------------------*/
(DATA          /* Input dataset (REQ)                                */
,UPCASE=N      /* Uppercase the returned variable names? (Opt).     */
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);

%local macro parmerr varlist;
%let macro = &sysmacroname;

%* additional error checking ;
%if (%index(%superq(data),%str(%())) %then %do;
   %parmv(_msg=Dataset options are not allowed);
   %goto quit;
%end;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)
%parmv(UPCASE,       _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* open dataset for input ;
%let dsid=%sysfunc(open(&data,i));

%* if open failed, abort ;
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open &data);
   %goto quit;
%end;

%do i=1 %to %sysfunc(attrn(&dsid,nvars));
   %let varlist=&varlist %sysfunc(varname(&dsid,&i));
%end;
%let dsid=%sysfunc(close(&dsid));

%if (&upcase) %then %let varlist=%upcase(&varlist);
&varlist

%quit:
%mend;

/******* END OF FILE *******/
