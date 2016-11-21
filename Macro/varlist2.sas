/*=====================================================================
Program Name            : varlist2.sas
Purpose                 : Returns a string containing a space separated
                          list of variables in a dataset.  Supports
                          dataset options.
SAS Version             : 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 17NOV2016
Program Version #       : 1.0

=======================================================================

Copyright (c) 2016 Scott Bass (sas_l_739@yahoo.com.au)

This code is licensed under the Unlicense license.
For more information, please refer to http://unlicense.org/UNLICENSE.

=======================================================================

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%varlist2(sashelp.class);
%put &=varlist;

   Returns the list of variables in SASHELP.CLASS.

=======================================================================

%varlist2(sashelp.class (drop=name age weight));
%put &=varlist;

%varlist2(sashelp.class (keep=name age weight));
%put &=varlist;

%varlist2(sashelp.class (keep=name--age));
%put &=varlist;

%varlist2(sashelp.class (keep=_character_));
%put &=varlist;

%varlist2(sashelp.class (keep=_numeric_));
%put &=varlist;

   Returns the list of variables in SASHELP.CLASS, 
   with the dataset option applied.

-----------------------------------------------------------------------
Notes:

The (separate) %varlist macro is a function style macro that returns
the variables in a dataset.  However, that macro does not support
dataset options, particularly DROP or KEEP.

This macro (%varlist2) is not a function style macro.  However, it 
does support dataset options, particularly DROP or KEEP.

This macro creates the global macro variable &varlist, which contains
the dataset variable list.

---------------------------------------------------------------------*/

%macro varlist2
/*---------------------------------------------------------------------
Returns a string containing a space separated list of variables in a
dataset.  Supports dataset options.
---------------------------------------------------------------------*/
(DATA          /* Source dataset (REQ).                              */
);

%local macro parmerr;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(data,_req=1,_words=1,_case=N)

%if (&parmerr) %then %goto quit;

%* capture current notes option setting ;
%let notes=%sysfunc(getoption(notes));

options nonotes;
data _null_;
   if 0 then set &data;
   length _dummy_ $1 varname $32 varlist $32767;
   do while (1);
      call vnext(varname);
      if varname='_dummy_' then leave;
      varlist=catx(" ",varlist,varname);
   end;
   call symputx("varlist",varlist,"G");
   stop;
run;
options &notes;

%quit:
%mend;

/******* END OF FILE *******/
