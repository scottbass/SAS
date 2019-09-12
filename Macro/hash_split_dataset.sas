/*====================================================================
Program Name            : hash_split_dataset.sas
Purpose                 : Use hash object to split dataset into
                          multiple datasets
SAS Version             : SAS 9.1.3
Input Data              : SAS input dataset
Output Data             : Multiple SAS output datasets

Macros Called           : parmv, kill

Originally Written by   : Scott Bass
Date                    : 12MAY2010
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

+===================================================================*/

/*--------------------------------------------------------------------
Usage:

data source;
   length key1 svar1 $1;
   input  key1 svar1;
   datalines;
A  1
B  2
C  3
1  A
2  B
2  C
3  D
3  E
3  F
;
run;

proc format;
   value $key
      "1"   = "FOO"
      "2"   = "BAR"
      "3"   = "BLAH"
   ;
run;

----------------------------------------------------------------------

%hash_split_dataset(data=source, out=%str(cats("OUT_",key1)), by=key1);

data source2 / view=source2;
   set source (where=(key1 between "1" and "3"));
run;

%m_hash_split_dataset(data=source2, out=%str(put(key1,$key.)), by=key1, vars=);

This will result in the output datasets OUT_A, OUT_B, OUT_C, OUT_1, OUT_2, OUT_3
and FOO, BAR, and BLAH respectively.

----------------------------------------------------------------------
Notes:

The source dataset must be sorted or indexed on the byvar.

The OUT= parameter must be a SAS code fragment that generates the
desired dynamic SAS output dataset name.  Typically this would be
cats("Prefix",key_var), put could also be something like
put(key_var,some_format.) or cats("Prefix",put(key_var,some_format.))

--------------------------------------------------------------------*/

%macro hash_split_dataset
/*--------------------------------------------------------------------
Use hash object to split dataset into multiple datasets
--------------------------------------------------------------------*/
(DATA=         /* Source dataset (REQ).                             */
,OUT=          /* SAS code fragment that defines the dynamic, data  */
               /* driven output dataset names (REQ).                */
,BY=           /* Grouping variable for output dataset observations */
               /* (REQ).  Only a single variable can be specified.  */
,VARS=_ALL_    /* Desired output variables (Opt).                   */
               /* Default is all variables in the source dataset.   */
               /* Analogous to keep statement on the output dataset.*/
               /* If set to blank only the by variable is output.   */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0,_case=U)
%parmv(OUT,          _req=1,_words=1,_case=N)
%parmv(BY,           _req=1,_words=0,_case=U)
%parmv(VARS,         _req=0,_words=1,_case=U)

%if (&parmerr) %then %goto quit;

%* if VARS=_ALL_, need to get an explicit list of all the dataset variables ;
%* proc contents is much faster than dictionary.columns when a large # of libraries are allocated ;
%if (&vars eq _ALL_) %then %do;
   proc contents data=&data out=_contents_ (keep=name varnum) noprint nodetails;
   run;
   proc sql noprint;
      select name into :vars separated by " "
      from _contents_
      where upcase(name) ne "%upcase(&by)"
      order by varnum;
      drop table _contents_;
   quit;
%end;

%* create sorted view of input dataset ;
proc sql noprint;
   create view _sorted_ as
      select * from &data order by &by
   ;
quit;

%* use a hash object to split a dataset based on the grouping variable ;
data _null_;
   %* declare the hash object ;
   declare hash h (hashexp: 16, ordered: "A");

   %* define keys and satellite variables ;
   h.defineKey("&by","_n_");
   h.defineData(%seplist(&by &vars,nest=QQ));

   %* end hash declaration ;
   h.defineDone();

   do _n_=1 by 1 until (last.&by);
      set _sorted_;
      by &by;
      h.add();
   end;
   h.output(dataset: &out);
run;

%kill(delete=_sorted_)

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
