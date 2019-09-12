/*=====================================================================
Program Name            : export_sas.sas
Purpose                 : Simple macro to copy a source dataset to a
                          target library with some additional error
                          checking.
SAS Version             : SAS 9.4
Input Data              : SAS dataset
Output Data             : SAS dataset in another library

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 04SEP2019
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

* cleanup from previous invocations ;
proc datasets lib=work nowarn nolist;
   delete class;
quit;

%export_sas(
   data=sashelp.class
)

or 

* cleanup from previous invocations ;
proc datasets lib=work nowarn nolist;
   delete class;
quit;

%export_sas(
   data=sashelp.class
   ,outlib=work
)

Copies sashelp.class to work.class,
preserving any indexes and integrity constraints (in this case none).

The default OUTLIB parameter is work.

=======================================================================

data class;
   set sashelp.class;
run;

* assumes sasuser.class does not already exist ;
%export_sas(
   data=class
   ,outlib=sasuser
)

* cleanup ;
proc delete data=sasuser.class;
run;

Copies work.class to sasuser.class using a one-level source dataset name.

=======================================================================

%let options=%sysfunc(getoption(USER, keyword));
%put &=options;
options USER=sasuser;

* this will create sasuser.class because of the USER option ;
data class;
   set sashelp.class;
run;

* cleanup from previous invocations ;
proc datasets lib=work nowarn nolist;
   delete class;
quit;

%export_sas(
   data=class
   ,outlib=work
)

* cleanup ;
options user='';
proc delete data=sasuser.class;
run;

Creates sasuser.class due to the USER option and a one-level name,
then copies sasuser.class to work.class.

If a one-level input data set is specified,
the USER system option is checked, otherwise work is used.

=======================================================================

data class;
   set sashelp.class;
run;

%export_sas(
   data=class
   ,outlib=work
)

No export (COPY) is done since the source dataset 
already exists in the target library.
In other words, the source and target libraries are the same.

=======================================================================

data work.myshoes;
   set sashelp.shoes;
   stop;  * empty dataset ;
run;

%export_sas(
   data=sashelp.shoes
   ,outlib=work
   ,outdata=myshoes
)

Copies sashelp.shoes to work.shoes using PROC COPY,
then renames work.shoes to work.myshoes.

If the target dataset (work.myshoes) already exists,
it will be overwritten.  The target dataset work.myshoes
will contain the complete set of sashelp.shoes data.

=======================================================================

%export_sas(
   data=sashelp.class (where=(sex='F'))
   ,outlib=work
   ,outdata=females
)

Copies females from sashelp.class to work.class using PROC COPY,
then renames work.class to work.females.

=======================================================================

Check that indexes and integrity constraints are preserved:

%let options=%sysfunc(getoption(dlcreatedir));
%put &=options;
options dlcreatedir;
libname temp "%sysfunc(pathname(work))\temp";
options &options;

data temp.class;
   set sashelp.class;
   where age between 12 and 16;
run;

proc datasets lib=temp nowarn nolist;
   modify class;
   index create name / unique;
   index create sex;
   ic create val_sex = 
      check (where=(sex in ('M','F')))
      message = "Valid values for variable SEX are either 'M' or 'F'."
   ;
   ic create val_age = 
      check (where=(age between 12 and 16))
      message = "An invalid AGE has been provided."
   ;
   run;
quit;

%export_sas(
   data=temp.class (where=(sex='M'))
   ,outlib=work
   ,outdata=males
)

* check that indexes and integrity constraints are preserved ;
proc contents data=work.males details;
run;

Copies males from temp.class to work.class, 
then renames work.class to work.males,
preserving indexes and integrity constraints.

=======================================================================

Error checking:

%export_sas(
   data=sashelp.doesnotexist
)

Fails, source dataset sashelp.doesnotexist does not exist.

%export_sas(
   data=sashelp.class
   ,outlib=work
   ,outdata=ClAsS
)

Fails, outdata name must be different than the source dataset name.

%export_sas(
   data=sashelp.class
   ,outlib=foo
)

Fails, the foo target library does not exist.
This error is not trapped by the macro but is gracefully handled by PROC COPY.

-----------------------------------------------------------------------
Notes:

If the source library and target library are the same,
no export is done since the target dataset already exists.

However, if the OUTDATA parameter is specified,
and the OUTDATA dataset already exists in the target library,
that dataset will be overwritten.

If dataset options are specified, they are supported via PROC COPY's
OVERRIDE= option.  Usually the dataset option is a WHERE clause.
No testing has been done for other dataset options.

PROC COPY's CLONE option is used to copy various source dataset options
(bufsize, compress, reuse, outrep, encoding, pointobs) to the 
target dataset.

PROC COPY's INDEX= and CONSTRAINT= options are used to copy any
source dataset indexes and integrity constraints to the target dataset.

---------------------------------------------------------------------*/

%macro export_sas
/*---------------------------------------------------------------------
Simple macro to copy a source dataset to a target library 
with some additional error checking.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */
,OUTLIB=WORK   /* Output library (REQ).                              */
,OUTDATA=      /* Output dataset name (Opt).                         */
               /* If specified, the source dataset is copied         */
               /* to the target library with the source dataset      */
               /* name, then the target dataset is renamed           */
               /* to the OUTDATA name.                               */
);

%local macro parmerr;
%local _temp _pos _options _inlib _inds _outlib _outds _target;
%let macro = &sysmacroname;


%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(OUTLIB,       _req=1,_words=0,_case=U)
%parmv(OUTDATA,      _req=0,_words=0,_case=U)

%if (&parmerr) %then %return;

%* parse off dataset options (usually a where clause) ;
%let _temp = %superq(data);
%let _pos = %sysfunc(findc(%superq(data),%str(%()));
%if (&_pos) %then %do;
   %let _temp = %substr(%superq(data),1,&_pos-1);
   %let _options = %substr(%superq(data),&_pos);
%end;

%* does the source dataset exist? ;
%if not (%sysfunc(exist(%superq(_temp),DATA)) or %sysfunc(exist(%superq(_temp),VIEW))) %then %do;
   %let syscc=8;
   %parmv(_msg=SAS dataset %superq(_temp) does not exist)
   %return;
%end;

%* parse the source dataset name ;
%let _inlib = %scan(%superq(_temp),1,.);
%let _inds  = %scan(%superq(_temp),2,.);

%* if one-level source dataset was specified, check the USER system option, otherwise use WORK ;
%if (&_inds eq ) %then %do;
   %let _inds = &_inlib;
   %let _inlib = %sysfunc(getoption(USER));
   %let _inlib = %sysfunc(compress(&_inlib,%str(%'%")));
   %if (&_inlib eq ) %then %let _inlib=WORK;
%end;
%let _inlib=%upcase(&_inlib);

%* if the OUTDATA parameter matches the source dataset name, abort with an ERROR ;
%if (%upcase(&outdata) eq %upcase(&_inds)) %then %do;
   %let syscc=8;
   %parmv(_msg=OUTDATA (&outdata) must be different than the input dataset (%upcase(&_inds)))
   %return;
%end;

%* create the target dataset name ;
%if (&outdata eq ) %then %do;
   %let _outlib = &outlib;
   %let _outds  = &_inds;
%end;
%else %do;
   %let _outlib = &outlib;
   %let _outds  = &outdata;
%end;
%let _target = %superq(_outlib).%superq(_outds);

%* if the input and output libraries are the same, abort with a WARNING ;
%if (%upcase(&_inlib) eq %upcase(&_outlib)) %then %do;
   %let syscc=4;
   %let _msg = %str(WAR)NING: Source library (%upcase(&_inlib)) and Target library (%upcase(&_outlib)) are the same.  No export was done.;
   %put &_msg;
   %return;
%end;

%* if the target dataset exists and will not be renamed, abort with a WARNING ;
%if (&outdata eq ) and (%sysfunc(exist(&_target,DATA)) or %sysfunc(exist(&_target,VIEW))) %then %do;
   %let syscc=4;
   %let _msg = %str(WAR)NING: Target dataset (&_target) already exists in the target library (&_outlib).  No export was done.;
   %put &_msg;
   %return;
%end;

%* copy the source dataset, including indexes and integrity constraints, to the output library ;
proc copy in=&_inlib out=&_outlib index=yes constraint=yes clone
   %if (%superq(_options) ne ) %then %do;
   override=%unquote(%superq(_options))
   %end;
   ;
   select &_inds;
run;

%* rename target dataset if requested ;
%if (&outdata ne ) %then %do;
   proc datasets lib=&_outlib nowarn nolist;
      delete &_outds;  %* no error message if &_outds does not exist ;
      change &_inds=&_outds;
   quit;
%end;

%mend;

/******* END OF FILE *******/
