/*=====================================================================
Program Name            : max_decimals.sas
Purpose                 : Derives the maximum number of decimal places
                          within a given variable(s), either for the
                          entire dataset or by groups.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv, seplist

Originally Written by   : Scott Bass
Date                    : 01OCT2010
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

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* create test dataset ;
data test;
   length key $1 num1 num2 8 chr1 chr2 $9;
   input key num1 num2 chr1 chr2;
   datalines;
A  1              1           1           1
A  2.22           2.22        2.2         2.2
A  33.333         33.333      33.3        33.3
A  4.4444         4.444       4.44        BAD
B  555.55         555.5       555.55      555
B  66.6           66.6        66.66       66
B  7777.77        7777.7      7777.77     7777
C  8888.888       8888.888    8888.88     BAD
C  9999.9999      9999.99     9999.9      9999.9
;
run;

* various test invocations ;

* all numeric variables, only _maxdec_ dataset created ;
%max_decimals(data=test,out=_null_);

* all numeric variables, max decimals merged into new dataset ;
%max_decimals(data=test,out=test1);

* all character variables (should contain numeric data) ;
%max_decimals(data=test,out=test2,var=_character_);

* all variables ;
%max_decimals(data=test,out=test3,var=_all_);

* specify explicit variables ;
%max_decimals(data=test,out=test4,var=num1 chr2);

* specify explicit prefix ;
%max_decimals(data=test,out=test5,var=num2 chr1 chr2,prefix=my_max_);

* by key variables ;
* all numeric variables, max decimals merged into new dataset ;
%max_decimals(data=test,out=test6,by=key);
%max_decimals(data=test,out=test6,by=key,var=chr1 chr2);

* max decimals merged back into source dataset ;
%max_decimals(data=test);

* all numeric variables, max decimals merged into new data step view ;
* all the above examples can output a data step view via the type= parameter ;
%max_decimals(data=test,out=v_test,type=view);

-----------------------------------------------------------------------
Notes:

An output data step view, rather than dataset, can be useful
if the input dataset is very large.

If TYPE=view, then OUT= must be specified (or _null_).

If OUT=_null_, then TYPE= is irrelevant.

---------------------------------------------------------------------*/

%macro max_decimals
/*---------------------------------------------------------------------
Derives the maximum number of decimal places within a given variable(s)
---------------------------------------------------------------------*/
(DATA=         /* Input dataset. (REQ).                              */
,OUT=          /* Output dataset / view (Opt).                       */
               /* If blank, the derived maximum decimal variable(s)  */
               /* are merged back into the input dataset.            */
               /* If "_null_" (case-insensitive), only the _MAXDEC_  */
               /* working dataset is created, for use in the         */
               /* calling program.                                   */
,TYPE=DATA     /* Output dataset type (Opt).                         */
               /* Default is DATA.  If blank, then DATA is used.     */
               /* Valid values are DATA or VIEW.                     */
,VAR=_NUMERIC_ /* Input variables (REQ).                             */
               /* Default is all numeric variables in the input      */
               /* dataset.                                           */
,BY=           /* By variables (Opt).                                */
               /* If blank, the maximum decimal variable(s) are      */
               /* derived for the entire column.                     */
               /* If not blank, the maximum decimal variable(s) are  */
               /* derived for each by group.                         */
,PREFIX=maxdec_
               /* Output variable prefix (REQ).                      */
               /* Default is "maxdec_".  Output variables are named  */
               /* as &PREFIX.&VAR1, &PREFIX.&VAR2, etc.              */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0,_case=U)
%parmv(OUT,          _req=0,_words=0,_case=U)
%parmv(TYPE,         _req=0,_words=0,_case=U,_val=DATA VIEW)
%parmv(VAR,          _req=1,_words=1,_case=U)
%parmv(BY,           _req=0,_words=1,_case=U)
%parmv(PREFIX,       _req=1,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* if out was not specified, merge results back into source dataset ;
%if (&out eq ) %then %let out=&data;

%* if type is blank then set to DATA ;
%if (&type eq ) %then %let type=DATA;

%* if type=VIEW then out must be different than data ;
%if (&type eq VIEW) %then
   %if (&out eq &data) %then %do;
      %parmv(_msg=If TYPE=VIEW then the OUT parameter must be diffent from the DATA parameter)
      %goto quit;
   %end;

%* get contents of source dataset ;
proc contents data=&data (keep=&var) out=_columns_ (keep=name type varnum) noprint;
run;

%* get list of numeric and character variables ;
%local num_vars chr_vars;
%let num_vars=;
%let chr_vars=;
proc sql noprint;
   select name into :num_vars separated by " " from _columns_ where type=1 order by varnum;
   select name into :chr_vars separated by " " from _columns_ where type=2 order by varnum;
   drop table _columns_;
quit;

%let max_dec_vars=%seplist(&num_vars &chr_vars,prefix=&prefix,dlm=%str( ));

%* create dataset deriving maximum number of decimal places per variable ;
data _maxdec_;
   set &data end=eof;

   %if (&by ne ) %then %do;
   by &by;
   %end;

   %if (&num_vars ne ) %then %do;array _num_ {*} &num_vars;%end;
   %if (&chr_vars ne ) %then %do;array _chr_ {*} &chr_vars;%end;

   array _maxdec_ {*} &max_dec_vars;
   retain _maxdec_;
   length _temp_ _int_ _dec_ $32;

   _i_=0;
   %if (&num_vars ne ) %then %do;
   do _i_=1 to dim(_num_);
      _temp_=put(_num_{_i_},best32.-L);
      _int_=scan(_temp_,1,".");
      _dec_=scan(_temp_,2,".");
      _maxdec_{_i_}=max(_maxdec_{_i_},lengthn(_dec_));
   end;
   _i_=_i_-1;
   %end;

   %if (&chr_vars ne ) %then %do;
   do _j_=1 to dim(_chr_);
      _temp_=put(input(_chr_{_j_},?? best32.),best32.-L);
      _int_=scan(_temp_,1,".");
      _dec_=scan(_temp_,2,".");
      _maxdec_{_j_+_i_}=max(_maxdec_{_j_+_i_},lengthn(_dec_));
   end;
   %end;

   %if (&by ne ) %then %do;
   if last.%scan(&by,-1,%str( )) then do;
      output;
      call missing(of &max_dec_vars);
   end;
   %end;
   %else %do;
   if eof then output;
   %end;

   keep &by &max_dec_vars;
run;

%* merge max decimal data back into original dataset ;
%if (%lowcase(&out) ne _null_) %then %do;
   %if (&by eq ) %then %do;
      data &out %if (&type eq VIEW) %then / view=&out;;
         set &data;
         if _n_=1 then set _maxdec_;
      run;
   %end;
   %else %do;
      data &out %if (&type eq VIEW) %then / view=&out;;
         merge &data _maxdec_;
         by &by;
      run;
   %end;
%end;

%quit:

%mend;

/******* END OF FILE *******/
