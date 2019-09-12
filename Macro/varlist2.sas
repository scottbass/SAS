/*=====================================================================
Program Name            : varlist2.sas
Purpose                 : Returns a string containing a space separated
                          list of variables in a dataset.  Supports
                          dataset options and sorting of the returned
                          variable list.
SAS Version             : 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 17NOV2016
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
Change/reason           : Added UPCASE and SORT parameters
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%varlist2(sashelp.shoes);
%put &=varlist;

   Returns the list of variables in SASHELP.SHOES,
   in PDV order.

=======================================================================

%varlist2(sashelp.shoes(keep=Region Subsidiary Sales Returns));
%put &=varlist;

%varlist2(sashelp.shoes(keep=Region--Stores));
%put &=varlist;

%varlist2(sashelp.shoes(keep=_character_));
%put &=varlist;

%varlist2(sashelp.shoes(keep=_numeric_));
%put &=varlist;

%varlist2(sashelp.shoes (drop=Region Subsidiary Sales Returns));
%put &=varlist;

%varlist2(sashelp.shoes (drop=Region--Stores));
%put &=varlist;

%varlist2(sashelp.shoes (drop=_character_));
%put &=varlist;

%varlist2(sashelp.shoes (drop=_numeric_));
%put &=varlist;

* nonsensical but works! ;
%varlist2(sashelp.shoes (drop=_all_));
%put &=varlist;

   Returns the list of variables in SASHELP.SHOES,
   in PDV order, 
   with the dataset option applied.

=======================================================================

%varlist2(sashelp.shoes,upcase=Y);
%put &=varlist;

%varlist2(sashelp.shoes (keep=Region Subsidiary Sales Returns),upcase=Y);
%put &=varlist;

   Returns the list of variables in SASHELP.SHOES,
   in PDV order, 
   with the dataset option applied,
   with the returned variable list uppercased.

=======================================================================

%varlist2(sashelp.shoes,sort=Y);
%put &=varlist;

%varlist2(sashelp.shoes (drop=Region--Subsidiary),sort=Y);
%put &=varlist;

   Returns the list of variables in SASHELP.SHOES,
   in sorted (alphabetical) order, 
   with the dataset option applied.

=======================================================================

%varlist2(sashelp.shoes,upcase=Y,sort=Y);
%put &=varlist;

%varlist2(sashelp.shoes (drop=Region--Subsidiary),upcase=Y,sort=Y);
%put &=varlist;

   Returns the list of variables in SASHELP.SHOES,
   in sorted (alphabetical) order, 
   with the dataset option applied,
   with the returned variable list uppercased.

=======================================================================

%varlist2(sashelp.shoes,mvar=mymvar);
%put &=mymvar;

%varlist2(sashelp.shoes,mvar=mymvar,upcase=Y);
%put &=mymvar;

%varlist2(sashelp.shoes,mvar=mymvar,upcase=Y,sort=Y);
%put &=mymvar;

   Returns the list of variables in SASHELP.SHOES,
   in the user-specified macro variable &MYMVAR.

-----------------------------------------------------------------------
Notes:

The (separate) %varlist macro is a function style macro that returns
the variables in a dataset.  However, that macro does not support
dataset options, particularly DROP or KEEP, nor does it support
returning the variable list in sorted (alphabetical) order.

This macro (%varlist2) is not a function style macro.  However, it 
does support dataset options, particularly DROP or KEEP.

This macro (%varlist2) also supports returning the variable list in
sorted (alphabetical) order.

This macro creates the global macro variable VARLIST, which contains
the dataset variable list.  Specify the MVAR= parameter to specify
a different name.

---------------------------------------------------------------------*/

%macro varlist2
/*---------------------------------------------------------------------
Returns a string containing a space separated list of variables in a
dataset.  Supports dataset options and sorting of the returned
variable list.
---------------------------------------------------------------------*/
(DATA          /* Source dataset (REQ).                              */
,UPCASE=N      /* Uppercase the returned variable names? (Opt).      */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,SORT=N        /* Return the variable list in sorted (alphabetical)  */
               /* order? (Opt).                                      */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,MVAR=VARLIST  /* Name of returned macro variable (REQ).             */
);

%local macro parmerr notes;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(DATA,         _req=1,_words=1,_case=N)
%parmv(UPCASE,       _req=0,_words=0,_case=U,_val=0 1)
%parmv(SORT,         _req=0,_words=0,_case=U,_val=0 1)
%parmv(MVAR,         _req=1,_words=0,_case=U)

%if (&parmerr) %then %goto quit;

%global &mvar;
%let &mvar=;

%* capture the current NOTES system option ;
%let notes=%sysfunc(getoption(notes));
options nonotes;

proc contents data=&data out=_contents_ (keep=name varnum) noprint;
run;
proc sql noprint;
   %if (&upcase) %then %do;
      select upcase(name)
   %end;
   %else %do;
      select name
   %end;
   into :&mvar separated by ' '
   from _contents_
   %if (&sort) %then %do;
      %if (&upcase) %then %do;
         order by upcase(name)
      %end;
      %else %do;
         order by name
      %end;
   %end;
   %else %do;
      order by varnum
   %end;
   ;
   drop table _contents_;
quit;

%* restore the NOTES system option ;
options &notes;

%quit:
%mend;

/******* END OF FILE *******/
