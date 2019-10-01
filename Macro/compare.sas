/*====================================================================
Program Name            : compare.sas
Purpose                 : PROC COMPARE either two datasets or
                          two libraries
SAS Version             : SAS 9.1.3
Input Data              : Either Base and Compare datasets or
                          Base and Compare libraries
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 21JAN2009
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

options nocenter mprint ls=max;

data base;
   set sashelp.class;
   label age="Age In Years";
run;
proc sort;
   by name;
run;

data comp;
   set sashelp.class;
   if name="John" then age=99;
   drop sex;
   label age="Age";
run;
proc sort;
   by name;
run;

%compare(base=base,comp=comp,by=name)

Compares the base and compare datasets, reporting on differences for
both variables and observations.

======================================================================

* use the SPDE engine to create temporary libraries ;
libname lib_base spde "%sysfunc(pathname(work))" temp=yes;
libname lib_comp spde "%sysfunc(pathname(work))" temp=yes;

proc copy inlib=sashelp outlib=lib_base;
   select class shoes cars;
run;

proc copy inlib=sashelp outlib=lib_comp;
   select class shoes cars stocks;
run;

data lib_comp.class;
   set lib_comp.class;
   if name="John" then do;
      height+1;
      weight+2;
   end;
run;

%compare(base=lib_base, comp=lib_comp)

libname lib_base;
libname lib_comp;

Compare the lib_base and lib_comp libraries, reporting on library
differences and comparing like named datasets;

======================================================================

* use the SPDE engine to create temporary libraries ;
libname lib_base spde "%sysfunc(pathname(work))" temp=yes;
libname lib_comp spde "%sysfunc(pathname(work))" temp=yes;

proc copy inlib=sashelp outlib=lib_base;
   select class shoes cars stocks;
run;

proc copy inlib=sashelp outlib=lib_comp;
   select class shoes cars;
run;

* filter the library using prxmatch syntax ;
%compare(base=lib_base, comp=lib_comp, filter=cla*|shoes)

libname lib_base;
libname lib_comp;

Compare the lib_base and lib_comp libraries, reporting on library
differences and comparing like named datasets, where the datasets
in the base library match the specified filter.

======================================================================

* use the SPDE engine to create temporary libraries ;
libname lib_base spde "%sysfunc(pathname(work))" temp=yes;
libname lib_comp spde "%sysfunc(pathname(work))" temp=yes;

proc copy inlib=sashelp outlib=lib_base;
   select class shoes;
run;

proc copy inlib=sashelp outlib=lib_comp;
   select class shoes;
run;

data lib_comp.class;
   set lib_comp.class;
   if name="John" then do;
      height+1;
      weight+2;
   end;
run;

* create a keys (BY processing) dataset ;
* the keys variable can have any name, but MUST be ;
* the 2nd variable in the PDV ;
data keys;
   length memname $32 keys $1024;
   infile datalines dsd dlm=":";
   input memname keys;
   datalines;
class : name sex
shoes : region product subsidiary stores
;
run;

* use the keys dataset to do a sorted comparison ;
%compare(base=lib_base, comp=lib_comp, by=keys)

* alternatively, specify the by variables on a per dataset basis ;
%compare(base=lib_base.class, comp=lib_comp.class, by=name sex)
%compare(base=lib_base.shoes, comp=lib_comp.shoes, by=region product subsidiary stores)

libname lib_base;
libname lib_comp;

----------------------------------------------------------------------

Notes:

If an allocated libref and dataset have the same name, the dataset
will take precedence, and a dataset comparison will be done.

A keys dataset can also be created using this proc contents approach:

* create a keys dataset for certain datasets ;
proc contents
   data=sashelp._all_
   out=contents (where=(memname in ("CLASS","SHOES")))
   noprint;
run;

proc sort;
   by libname memname varnum;
run;

data keys;
   format libname memname;
   length keys $1024 flag 8;
   retain keys;
   set contents;
   by libname memname;
   if first.memname then call missing(keys);
   flag=0;
   if prxmatch("/height|weight|age/io",strip(name)) then flag=1;  * variable exclusion ;
   if not prxmatch("/name|sex|region|product|subsidiary/io") then flag=1;  * variable inclusion ;
   if flag=0 then keys=catx(" ",keys,name);
   if last.memname then output;
   keep memname keys;
run;

--------------------------------------------------------------------*/

%macro compare
/*--------------------------------------------------------------------
PROC COMPARE either two datasets or two libraries
--------------------------------------------------------------------*/
(BASE=         /* Base dataset or library (REQ).                    */
,COMP=         /* Compare dataset or library (REQ).                 */
,BY=           /* By variables that uniquely identify a record (Opt)*/
               /* This can be either an explicit list of variables  */
               /* for a dataset, or a metadata dataset              */
               /* If specified, these variables should uniquely     */
               /* identify a record.  Otherwise, a warning message  */
               /* is issued, but the compare continues with the     */
               /* next BY group.                                    */
               /* This option is ignored when comparing libraries.  */
,FILTER=       /* Only process specified datasets? (Opt).           */
               /* This option is only used when comparing libraries.*/
               /* If specified, it must be a valid regular          */
               /* expression in prxmatch syntax.                    */
,CHECKOBS=0    /* Number of observations to print from the check    */
               /* dataset (REQ).                                    */
               /* Default is 0, no printing done.                   */
               /* Specify blank or "max" to print all observations. */
,MAXPRINT=%str(50,1000)
               /* Maximum PROC COMPARE differences to print (REQ).  */
,CRITERION=.000001
               /* Fuzz factor for numeric comparisons (REQ).        */
,METHOD=EXACT
               /* Specifies the method for judging the equality of  */
               /* numeric values                                    */
);

%local macro parmerr base_type comp_type type by_dataset by_var word obs;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(BASE,          _req=1,_words=0,_case=N)
%parmv(COMP,          _req=1,_words=0,_case=N)
%parmv(BY,            _req=0,_words=1,_case=N)
%parmv(FILTER,        _req=0,_words=1,_case=N)
%parmv(CHECKOBS,      _req=0,_words=0,_case=U)
%parmv(MAXPRINT,      _req=1,_words=1,_case=U)
%parmv(CRITERION,     _req=1,_words=0,_case=U)
%parmv(METHOD,        _req=1,_words=0,_case=U,_val=ABSOLUTE EXACT PERCENT RELATIVE)

%if (&parmerr) %then %goto quit;

%* is this a dataset or library compare? ;
%if (%sysfunc(exist(&base,data))  eq 1 or
     %sysfunc(exist(&base,view))) eq 1 %then %let base_type=DATA;
%else
%if (%sysfunc(libref(&base)) eq 0) %then %let base_type=LIB;
%else
%parmv(_msg=Either &base is not allocated or does not exist);

%if (%sysfunc(exist(&comp,data))  eq 1 or
     %sysfunc(exist(&comp,view))) eq 1 %then %let comp_type=DATA;
%else
%if (%sysfunc(libref(&comp)) eq 0) %then %let comp_type=LIB;
%else
%parmv(_msg=Either &comp is not allocated or does not exist);

%if (&parmerr) %then %goto quit;

%* both parameters must be the same type ;
%if (&base_type eq LIB  and &comp_type eq LIB)  %then %let type=LIB;
%else
%if (&base_type eq DATA and &comp_type eq DATA) %then %let type=DATA;
%else
%parmv(_msg=Both the BASE parameter (&base_type) and COMPARE parameter (&comp_type) must be the same type)

%if (&parmerr) %then %goto quit;

%* use SPDE work library for better performance ;
%if (%sysfunc(libref(workspde)) ne 0) %then %do;
   libname workspde spde "%sysfunc(pathname(work))" temp=yes;
%end;

%* capture current value of obs option ;
%let obs=%sysfunc(getoption(obs));

%* if a library comparison, create a comparison report ;
%* then recursively call this macro to compare like named datasets ;
%if (&type eq LIB) %then %do;
   %* temporarily set obs option to max ;
   %* SAS dataset options do not work with the dictionary tables ;
   options obs=max;

   proc sql noprint;
      create table workspde.compare_libraries as
         select
             case when base.memname is null then 0 else 1 end as in_base
            ,case when comp.memname is null then 0 else 1 end as in_comp
            ,case when sum(calculated in_base,calculated in_comp) ne 2 then
               "NO MATCH"
            else
               "MATCHED" 
            end                                          as matched
            ,base.libname                                as base_libname
            ,base.memname                                as base_memname
            ,base.nlobs                                  as base_nobs      format=comma21.
            ,comp.libname                                as comp_libname
            ,comp.memname                                as comp_memname
            ,comp.nlobs                                  as comp_nobs      format=comma21.
         from (
            select
                libname
               ,memname
               ,nlobs
            from
               dictionary.tables
            where
               upcase(libname)="%upcase(&base)"
         ) base
         full outer join (
            select
                libname
               ,memname
               ,nlobs
            from
               dictionary.tables
            where
               upcase(libname)="%upcase(&comp)"
         ) comp
         on
            upcase(base.memname)=upcase(comp.memname)
         %if (%superq(filter) ne ) %then %do;
         where
            prxmatch("/&filter/io",base.memname)
         %end;
         order by
            calculated matched, base.memname
   ;
   %* create macro variable containing matching member names ;
   %global datasets;
   %let datasets=;
   select
      base_memname into :datasets separated by " "
   from
      workspde.compare_libraries
   where
      in_base and in_comp
   ;
   quit;

   options obs=&obs;

   title;
   title1 "Library comparison report between &base  and &comp  libraries";
   proc report data=workspde.compare_libraries (obs=max) nowd;
      column
      ("_Flags_"     in_base in_comp matched)
      ("_Base_"      base_libname base_memname base_nobs)
      ("_Compare_"   comp_libname comp_memname comp_nobs)
      obsdiff
      ;
      define         in_base        / display   spacing=0         "Base";
      define         in_comp        / display                     "Compare";
      define         matched        / display                     "Matched?";
      define         base_libname   / display                     "Libname";
      define         base_memname   / display                     "Memname";
      define         base_nobs      / display   format=comma21.   "# of Obs";
      define         comp_libname   / display                     "Libname";
      define         comp_memname   / display                     "Memname";
      define         comp_nobs      / display   format=comma21.   "# of Obs";
      define         obsdiff        / computed  width=9           "Obs Diff?";
      compute        obsdiff        / char      length=3;
         if comp_nobs ne base_nobs then obsdiff="<<<";
      endcomp;
  quit;

   %* now recursively call this macro over each matching dataset ;
   %if (&datasets eq ) %then %goto quit;

   %macro code;
      %compare(
          base=&base..&word
         ,comp=&comp..&word
         ,by=&by
         ,filter=&filter
         ,checkobs=&checkobs
         ,maxprint=%quote(&maxprint)
         ,criterion=&criterion
         ,method=&method
      )
   %mend;
   %loop(&datasets)
%end;
%else
%if (&type eq DATA) %then %do;
   %* save values of &base and &comp for titles statement ;
   %let base_title=&base;
   %let comp_title=&comp;

   %* if BY parameter was specified, was it a metadata dataset? ;
   %if (&by ne ) %then %do;
      %* save value of current BY parameter as possible BY_DATASET ;
      %let by_dataset=&by;
      %if (%sysfunc(exist(&by_dataset))) %then %do;
         %if (&by_var eq ) %then %do;
            %let dsid   = %sysfunc(open(&by_dataset));
            %let by_var = %sysfunc(varname(&dsid,2));  %* dataset must be memname keys format, so "keys" is 2nd variable ;
            %let dsid   = %sysfunc(close(&dsid));
         %end;
         %let by=;
         data _null_;
            set &by_dataset;
            where upcase(memname)="%upcase(%scan(&base,2,.))";
            call symputx("by",&by_var);
         run;
      %end;
      %else %do;
         %* not a BY_DATASET, assume it is a valid list of variables ;
         %let by_dataset=;
      %end;
   %end;

   %* have to sort the datasets, PROC COMPARE will not use indexes ;
   %if (&by ne ) %then %do;
      %kill(data=work._temp_)

      %* put the BY variables at the beginning of the PDV ;
      data work._temp_/view=work._temp_;
         format &by dummy;
         set &base (obs=&obs);
         retain dummy "";
      run;

      proc sort data=work._temp_ out=workspde._base_ %if %varexist(work._temp_,loaddttm) %then (drop=loaddttm);;
         by &by;
      run;

      %kill(data=work._temp_)

      %* put the BY variables at the beginning of the PDV ;
      data work._temp_/view=work._temp_;
         format &by dummy;
         set &comp (obs=&obs);
         retain dummy "";
      run;

      proc sort data=work._temp_ out=workspde._comp_ %if %varexist(work._temp_,loaddttm) %then (drop=loaddttm);;
         by &by;
      run;

      %kill(data=work._temp_)

      %let base=workspde._base_;
      %let comp=workspde._comp_;

      data workspde.check;
         format in;
         merge
            &base (in=base keep=&by)
            &comp (in=comp keep=&by)
         ;
         by &by;
         if base and comp then delete;
         if base then in="BASE record";
         if comp then in="COMP record";
      run;
   %end;
   %else %do;
      %* no BY variables, so assume both datasets are in desired sort order ;
      %* interleave datasets (merge with no by statement) ;
      data workspde.check;
         format in;
         merge
            &base (in=base keep=&by)
            &comp (in=comp keep=&by)
         ;
         if base and comp then delete;
         if base then in="BASE record";
         if comp then in="COMP record";
      run;
   %end;

   title1 "Comparison of &base_title  (base) to &comp_title  (compare) datasets";
   title3 "Records not in both datasets";
   data _null_;
      if (nobs) then do;
         put / "There are " nobs "records that are not shared between the &base and &comp datasets" /;
      end;
      stop;
      set workspde.check nobs=nobs;
   run;

   %if (&checkobs eq %str( ) or &checkobs eq MAX or &checkobs gt 0) %then %do;
      proc print data=workspde.check
      %if (&checkobs ne ) %then
         (obs=&checkobs);
      %else
         (obs=max);
      ;
         var in &by;
      run;
   %end;

   %* now compare the two datasets themselves ;
   title1 "Comparing &base_title  and &comp_title  datasets";
   proc compare
      base=&base
      comp=&comp
      listbasevar
      listcompvar
      warning
      maxprint=(&maxprint)
      method=&method
      %if (&method ne EXACT) %then %do;
      criterion=&criterion
      %end;
      ;
      %if (&by ne ) %then %do;
      id &by;
      %end;
   run;

   %let by=&by_dataset;
%end;

%quit:
%mend;

/******* END OF FILE *******/
