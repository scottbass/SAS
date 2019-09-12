/*=====================================================================
Program Name            : CreateTableOrView.sas
Purpose                 : Create either a table (SAS data set) or view
                          from either specified parameters, metadata
                          data set, or shell data sets.
SAS Version             : SAS 9.2
Input Data              : Specified in macro parameter
Output Data             : SAS / SQL data set or SAS / SQL view

Macros Called           : parmv, seplist

Originally Written by   : Scott Bass
Date                    : 07JUL2011
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

options mprint msglevel=i;

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,type=table
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,lang=sas
   ,type=table
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,type=view
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,lang=sas
   ,type=view
)

Creates SAS data set work.shoes and SAS data step view work.v_shoes
   from sashelp.shoes, keeping all variables.
Macro default is to create SAS data sets.

=======================================================================

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,lang=sql
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,lang=sql
   ,type=table
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,lang=sql
   ,type=view
)

Creates SQL data set work.shoes and SQL view work.v_shoes
   from sashelp.shoes, keeping all variables.

=======================================================================

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=table
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=table
)

Creates SAS data set and SQL data set work.shoes from sashelp.shoes
   keeping specified variables.

=======================================================================

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=view
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=view
)

Creates SAS data step view and SQL view work.v_shoes from sashelp.shoes
   keeping specified variables.

=======================================================================

* this will fail, indexes do not support the descending option ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=table
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary -Sales
   ,index=Y
)

* this will work, implemented as proc sort rather than an index ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=table
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary -Sales
   ,index=N
)

* this will work, no descending option present ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=table
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary Product
   ,index=Y
)

Creates SAS data set work.shoes from sashelp.shoes
   keeping specified variables.
Data is filtered by specified where clause.
Data is either indexed or sorted by specified by variables.
Data step views cannot be indexed, but they can be sorted after the
   view is created.
SAS data sets can be indexed or sorted.
SQL views can be sorted (order by).
SQL data sets can either be indexed or sorted (order by).

Use a leading minus sign (-) to specify descending order.  The correct
syntax will be derived based on whether the lang is SAS or SQL.

=======================================================================

* this will fail, indexes are not supported with views ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=view
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary Product
   ,index=Y
)

* this will work, implemented as proc sort rather than an index ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=view
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary -Sales
   ,index=N
)

Creates SAS data step view work.v_shoes and SAS data set work.shoes
   from sashelp.shoes, keeping specified variables.
Data is filtered by specified where clause.

Use a leading minus sign (-) to specify descending order.  The correct
syntax will be derived based on whether the lang is SAS or SQL.

=======================================================================

* this will fail, indexes do not support the descending option ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=table
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary -Sales
   ,index=Y
)

* this will work, implemented as output data set index ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=table
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary Sales
   ,index=Y
)

* this will work, implemented as SQL order by clause ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=table
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary -Sales
   ,index=N
)

Creates SQL data set set work.shoes from sashelp.shoes,
   keeping specified variables.
Data is filtered by specified where clause.

Use a leading minus sign (-) to specify descending order.  The correct
syntax will be derived based on whether the lang is SAS or SQL.

=======================================================================

* this will fail, indexes are not supported with views ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=view
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary Sales
   ,index=Y
)

* this will work, implemented as SQL order by clause ;
%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=view
   ,where=Region in ("United States", "Canada")
   ,by=Region Subsidiary -Sales
   ,index=N
)

Creates SQL view work.v_shoes from sashelp.shoes,
   keeping specified variables.
Data is filtered by specified where clause.

Use a leading minus sign (-) to specify descending order.  The correct
syntax will be derived based on whether the lang is SAS or SQL.

=======================================================================

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,drop=Stores Inventory Returns
   ,rename=Sales=TotalSales Region=Country
   ,lang=sas
   ,type=view
   ,where=Region in ("United States", "Canada")
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,drop=Stores Inventory Returns
   ,rename=Sales=TotalSales Region=Country
   ,lang=sql
   ,type=table
   ,where=Region in ("United States", "Canada")
)

Creates SAS data step view work.v_shoes and SQL data set work.shoes
   from sashelp.shoes, dropping and renaming specified variables.
Data is filtered by specified where clause.

=======================================================================

* create sample columns metadata data set ;
proc sql;
   create table meta_columns as
      select * from dictionary.columns
      where libname="SASHELP" and memname="SHOES"
   ;
quit;

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes (label="My Shoes Test SAS Data Set")
   ,meta_columns=meta_columns
   ,meta_columns_cond=upcase(Name) not in ("STORES","INVENTORY")
   ,lang=sas
   ,type=table
   ,where=Region contains ("America")
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes (label="My Shoes Test SQL View")
   ,meta_columns=meta_columns
   ,meta_columns_cond=upcase(Name) not in ("STORES","INVENTORY")
   ,lang=sql
   ,type=view
   ,where=Region contains ("America")
)

Creates SAS data set work.shoes and SQL vew work.v_shoes
   from sashelp.shoes, using columns in specified metadata data set.
Only the columns in the specified metadata data set are kept.
Data is filtered by specified where clause.

=======================================================================

* create sample shell data set ;
data shell (label="My SAS Shell Data Set");
   set sashelp.shoes;
   drop Stores Inventory Returns;
   stop;
run;

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes (label="My Shoes Test Data Set")
   ,shell=shell
   ,lang=sas
   ,type=table
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,shell=shell
   ,lang=sas
   ,type=view
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,shell=shell
   ,drop=stores
   ,rename=Product=Stuff Sales=TotalSales
   ,lang=sql
   ,type=table
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,shell=shell
   ,drop=stores inventory returns
   ,rename=Product=Stuff Sales=TotalSales
   ,lang=sql
   ,type=view
   ,by=product
   ,index=N
)

Creates data set work.shoes and view work.v_shoes
   from sashelp.shoes, using attributes in the specified shell data set (could also be a view).
If shell data set contains a data set label then that label is applied to the output data set/view.
If the output data set/view has a label specified then that value has precedence over the shell data set label.

=======================================================================

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sas
   ,type=table
   ,file=%sysfunc(pathname(work))/generatedCreateTableOrView.sas
)

%CreateTableOrView(
   data=sashelp.class
   ,out=work.v_class
   ,lang=sas
   ,type=table
   ,file=%sysfunc(pathname(work))/generatedCreateTableOrView.sas
   ,append=Y
)

%CreateTableOrView(
   data=sashelp.shoes
   ,out=work.v_shoes
   ,keep=Region Subsidiary Product Stores Sales
   ,lang=sql
   ,type=view
   ,file=_temp_
   ,run=Y
)

Generates code to creates SAS data set work.shoes and SQL view work.v_shoes
   from sashelp.shoes, keeping specified variables.
For the SAS data set, the code is written to <path to work library>/generatedCreateTableOrView.sas,
   but not executed.  It also uses the APPEND parameter to append to the output file.
For the SQL view, the code is written to a temporary file (default), and the code is executed.

In either scenario, the DMS command "fslist _code_" can be used to interactively debug the generated code.

-----------------------------------------------------------------------
Notes:

Note that the use cases above cover most, but not all, of the usage
scenarios.  See the macro code (esp. the parameter list) for all
usage scenarios.

The main purpose of this macro is to build SAS data sets/view or SQL
data sets/views using metadata from a metadata data set or shell data set
to enable metadata-driven programming.  Otherwise, it is easy enough
to "hard code" static data step or SQL code.

This code is not meant to generate any complex joins.  Its only
purpose is as a utility macro to generate a SAS data set/view or SQL
data set/view from a single input data set/view.  However, it could be
used as a utility macro within another macro for more complex
processing.

---------------------------------------------------------------------*/

%macro CreateTableOrView
/*---------------------------------------------------------------------
Create either a table (SAS data set) or view from either specified
parameters, metadata data set, or shell data sets.
---------------------------------------------------------------------*/
(
DATA=          /* Input data set/view (REQ).                         */
,OUT=          /* Output data set/view (REQ).                        */
,KEEP=         /* Keep specified variables? (Opt).                   */
               /* If specified, only the specified variables are     */
               /* kept in the output data set/view.                  */
               /* If blank, then all variables are kept.             */
,DROP=         /* Drop specified variables? (Opt).                   */
               /* If specified, those variables are dropped from the */
               /* output data set/view.  If both DROP and KEEP are   */
               /* specified then DROP has precedence and KEEP is     */
               /* ignored.                                           */
,BY=           /* Sort output data set/view? (Opt).                  */
               /* If specified, the output data set/view is sorted   */
               /* by the specified variables.  BY is invalid if the  */
               /* output is a data step view.                        */
,INDEX=Y       /* How should the output data set be sorted? (Opt).   */
               /* This is a required parameter if BY is specified.   */
               /* If INDEX=YES, an index is used to logically sort   */
               /* the output data set.  If INDEX=NO, PROC sort is    */
               /* used to physically sort the output data set.       */
               /* INDEX is ignored if the output type is a view.     */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,WHERE=        /* Filter observations from input data set/view?(Opt).*/
               /* If specified, the observations are filtered by the */
               /* where condition.                                   */
               /* Do not specify the "where" keyword.                */
,RENAME=       /* Rename output variables? (Opt).                    */
               /* Specify as oldvar1=newvar1 oldvar2=newvar2 ...     */
,META_COLUMNS= /* Metadata columns data set (Opt).                   */
               /* If specified, the attributes as specified in the   */
               /* metadata will be used for the output variables.    */
               /* The metadata should be specified with the same     */
               /* structure as PROC CONTENTS output, as well as any  */
               /* optional filtering variables.                      */
,META_COLUMNS_COND=
               /* Filter metadata columns data set? (Opt).           */
               /* If specified, the metadata columns data set will   */
               /* be filtered and only those returned columns will   */
               /* be in the output data set/view.                    */
,SHELL=        /* Shell data set (Opt).                              */
               /* If specified, the output data set/view will have   */
               /* the same structure as in the shell data set.       */
,LANG=SAS      /* Output language type (REQ).                        */
               /* Valid values are SAS (SAS data set/data step view) */
               /* or SQL (SQL data set/view).                        */
,TYPE=TABLE    /* Output type (REQ).                                 */
               /* Valid values are TABLE or VIEW.                    */
,FILE=         /* Output file for generated code (Opt).              */
               /* If blank, the code is executed via normal macro    */
               /* processing.  If non-blank, the generated code is   */
               /* written to the specified file.  If FILE=_TEMP_,    */
               /* the code is written to a temporary file.           */
               /* This only makes sense if RUN=Y.                    */
               /* A temporary file, pre-allocated fileref, or SAS    */
               /* catalog entry are all supported.                   */
,APPEND=N      /* Append to output file? (Opt).                      */
               /* If NO, the output file will be overwritten.        */
               /* If YES, the output file will be appended.          */
               /* If YES, the output file parameter must not be      */
               /* blank.                                             */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,RUN=N         /* Run generate code? (Opt).                          */
               /* If NO, the code is written to the output file but  */
               /* not executed.  If YES, the code is %included and   */
               /* thus executed.                                     */
               /* This parameter is ignored unless GENERATE=YES.     */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,PRE_PROCESS=  /* Pre-processing code (Opt).                         */
               /* If specified, this code is executed immediately    */
               /* after the DATA or PROC SQL statement.              */
,POST_PROCESS= /* Post-processing code (Opt).                        */
               /* If specified, this code is executed immediately    */
               /* before the RUN or QUIT statement.                  */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,               _req=1,_words=1,_case=N)   /* _words=1 allows ds options */
%parmv(OUT,                _req=1,_words=1,_case=N)   /* _words=1 allows ds options */
%parmv(KEEP,               _req=0,_words=1,_case=N)
%parmv(DROP,               _req=0,_words=1,_case=N)
%parmv(BY,                 _req=0,_words=1,_case=N)
%parmv(INDEX,              _req=0,_words=1,_case=U,_val=0 1)
%parmv(WHERE,              _req=0,_words=1,_case=N)
%parmv(RENAME,             _req=0,_words=1,_case=N)
%parmv(META_COLUMNS,       _req=0,_words=1,_case=N)
%parmv(META_COLUMNS_COND,  _req=0,_words=1,_case=N)
%parmv(SHELL,              _req=0,_words=0,_case=N)
%parmv(LANG,               _req=1,_words=0,_case=U,_val=SAS SQL)
%parmv(TYPE,               _req=1,_words=0,_case=U,_val=TABLE VIEW)
%parmv(FILE,               _req=0,_words=1,_case=N)
%parmv(APPEND,             _req=0,_words=0,_case=U,_val=0 1)
%parmv(RUN,                _req=0,_words=0,_case=U,_val=0 1)
%parmv(PRE_PROCESS,        _req=0,_words=1,_case=N)
%parmv(POST_PROCESS,       _req=0,_words=1,_case=N)

%if (&parmerr) %then %goto quit;

%* parse any data set options out of the data and out parameters ;
%local data_options out_options;
%let rx=%sysfunc(prxparse(/^(.*?)\((.*)\)/));
%if (%sysfunc(prxmatch(&rx,%superq(data)))) %then %do;
   %let data_options=%sysfunc(prxposn(&rx,2,%superq(data)));
   %let data        =%sysfunc(prxposn(&rx,1,%superq(data)));
%end;
%if (%sysfunc(prxmatch(&rx,%superq(out)))) %then %do;
   %let out_options=%sysfunc(prxposn(&rx,2,%superq(out)));
   %let out        =%sysfunc(prxposn(&rx,1,%superq(out)));
%end;
%syscall prxfree(rx);

%* additional error checking ;

%* check if the source data set exists ;
%if (not (%sysfunc(exist(&data,data)) or %sysfunc(exist(&data,view)))) %then %do;
   %parmv(_msg=&data data set or view does not exist)
   %goto quit;
%end;

%* descending option is not allowed for indexes ;
%if (&index and %index(&by,%str(-))) %then %do;
   %parmv(_msg=The descending option is not supported for indexes)
   %goto quit;
%end;

%* indexes are not supported for views ;
%* (INDEX parameter is ignored unless BY is specified) ;
%if (%superq(by) ne ) %then %do;
      %if (&index and &type eq VIEW) %then %do;
         %parmv(_msg=Indexes are not supported for views)
         %goto quit;
   %end;
%end;

%* was a label specified on the out parameter? ;
%* if so, give it precedence over any label in the shell data set ;
%* otherwise, if a shell data set was specified, get the label from the shell data set ;
%local dslabel;
%let rx=%sysfunc(prxparse(/label\s*=\s*[%"%'](.*?)[%'%"]/i));
%if (%sysfunc(prxmatch(&rx,&out_options))) %then %do;
   %* do nothing, label is part of the options ;
%end;
%else %do;
   %if (&shell ne ) %then %do;
      %let dslabel=%data_attr(&shell,label);
   %end;
%end;
%syscall prxfree(rx);

%* format the label for later processing ;
%if (&dslabel ne ) %then %let dslabel=%sysfunc(quote(&dslabel));

%* get the libname and memname of the data and out parameters ;
%local data_libname data_memname out_libname out_memname temp;
%let data_libname=%scan(&data,1,.);
%let data_memname=%scan(&data,2,.);
%if (&data_memname eq ) %then %do;
   %let data_memname=&data_libname;
   %let temp=%sysfunc(getoption(user));
   %let data_libname=%sysfunc(ifc(&temp ne ,&temp,work));
%end;
%let out_libname=%scan(&out,1,.);
%let out_memname=%scan(&out,2,.);
%if (&out_memname eq ) %then %do;
   %let out_memname=&out_libname;
   %let temp=%sysfunc(getoption(user));
   %let out_libname=%sysfunc(ifc(&temp ne ,&temp,work));
%end;

%* get the libname and memname of the shell dataset if it was specified ;
%local shell_libname shell_memname;
%if (&shell ne ) %then %do;
   %let shell_libname=%scan(&shell,1,.);
   %let shell_memname=%scan(&shell,2,.);
   %if (&shell_memname eq ) %then %do;
      %let shell_memname=&shell_libname;
      %let temp=%sysfunc(getoption(user));
      %let shell_libname=%sysfunc(ifc(&temp ne ,&temp,work));
   %end;
%end;

%* build the index clause ;
%* we have already tested for the descending option with an index, ;
%* so &by will be ok for use in the index_stmt ;
%local index_stmt out_saved;
%if (%quote(&by) ne ) %then %do;
   %if (&index) %then %do;
      %if (%count_words(&by) eq 1) %then
         %let index_stmt=index=(&by);
      %else
         %let index_stmt=index=(_sort_=(&by));
   %end;
   %else
   %if (&lang eq SAS) %then %do;
      %* create a temporary data set or view ;
      %let out_saved=&out;
      %let out=_meta_temp_;
   %end;
%end;

%* dump macro variables to the log for debugging ;
%dump_mvars(
   data     data_libname   data_memname   data_options
   out      out_libname    out_memname    out_options
   shell    shell_libname  shell_memname
   dslabel
   keep
   drop
   rename
   where
   by
   index    index_stmt
   file     run
)

%*---------------------------------------------------------------------
START OF SAS CODE GENERATION
--------------------------------------------------------------------- ;

%* start with a clean slate ;
proc datasets lib=work nowarn nolist memtype=(data view);
   delete _meta_:;
quit;

%* parse the output file parameter to determine the output file type ;
%local _fileref _out_type _out_fileref;
%if (%superq(file) ne ) %then %do;
   %* was a physical file or a fileref specified? ;
   %if (%sysfunc(findc(%superq(file),%str(:./\%'%")))) or
       (%length(%superq(file)) gt 8) %then
      %let _fileref=0;
   %else
      %let _fileref=1;

   %* what type of file was specified? ;
   %if (not &_fileref) %then %do;
      %if (%scan(%upcase(%superq(file)),-1,.) eq SOURCE) %then %do;
         %let _out_type=catalog;
         %let _out_fileref=_code_;
      %end;
      %else
      %if (%scan(%upcase(%superq(file)),-1,.) eq SAS) %then %do;
         %let _out_type=file;
         %let _out_fileref=_code_;
      %end;
   %end;
   %else %do;
      %let _out_type=fileref;
      %let _out_fileref=%superq(file);
   %end;

   %* if the output fileref is _TEMP_, allocate a temporary fileref ;
   %* otherwise if the output type is a fileref, check if it is allocated ;
   %* otherwise allocate the file ;
   %if (&_out_type eq fileref) %then %do;
      %if (%upcase(&_out_fileref) eq _TEMP_) %then %do;
         %let _out_fileref=_code_;
         filename &_out_fileref temp %if (&append) %then mod;;
      %end;
      %else %do;
         %* is the fileref allocated? ;
         %if (%sysfunc(fileref(&_out_fileref)) gt 0) %then %do;
            %parmv(_msg=&_out_fileref fileref is not allocated)
         %end;
      %end;
   %end;
   %else
   %if (&_out_type eq file) %then %do;
      filename &_out_fileref "&file" %if (&append) %then mod;;
   %end;
   %else
   %if (&_out_type eq catalog) %then %do;
      filename &_out_fileref catalog "&file" %if (&append) %then mod;;
   %end;
%end;

%* if either a shell or metadata dataset was specified, build a keep statement ;
%* if both were specified, merge the data, giving precedence to shell dataset variable order ;
%* if either a shell or metadata dataset was specified, also check the source dataset for expected variables ;
%* and print warnings to the log if any expected variables are missing ;

%* if the lang is SQL, build metadata from the source dataset, since we want to explicitly ;
%* specify each select line (rather than select *) ;
%let vars=name type length varnum label format informat;
%let vars_sql=%seplist(&vars);

%if ( (%superq(meta_columns)%superq(shell) ne ) or (&lang eq SQL) ) %then %do;
   %* unconditionally create source dataset metadata ;
   %* used to check if source data contains all expected variables ;
   %* as specified in the shell or metadata dataset ;
   proc sql;
      create table _meta_source_ (index=(_uname_)) as
         select
             monotonic()+2000 as _order_
            ,upcase(name) as _uname_
            ,&vars_sql
         from
            dictionary.columns
         where
            libname="%upcase(&data_libname)" and memname="%upcase(&data_memname)"
         order by
            varnum
      ;
   quit;

   %if (&shell ne ) %then %do;
      proc sql;
         create table _meta_shell_ (index=(_uname_)) as
            select
                monotonic() as _order_
               ,upcase(name) as _uname_
               ,&vars_sql
            from
               dictionary.columns
            where
               libname="%upcase(&shell_libname)" and memname="%upcase(&shell_memname)"
            order by
               varnum
         ;
      quit;
   %end;

   %if (&meta_columns ne ) %then %do;
      proc sql;
         create table _meta_columns_ (index=(_uname_)) as
            select
               monotonic()+1000 as _order_
               ,upcase(name) as _uname_
               ,*
            from &meta_columns
            %if (%superq(meta_columns_cond) ne ) %then %do;
            where &meta_columns_cond
            %end;
         ;
      quit;
   %end;


   %* if rename parameter was specified, parse rename parameter to create rename metadata dataset ;
   %* to merge in with metadata.  this allows the rename parameter to override shell or metadata specifications ;
   %if (&rename ne ) %then %do;
      data _meta_rename_ (index=(_uname_));
         length _uname_ name rename $32 word $70 buffer $32767;
         buffer="&rename";

         %* remove any embedded spaces surrounding the equals sign ;
         rx=prxparse("s/\s*=\s*/=/");
         buffer=prxchange(rx,-1,buffer);

         i=1;
         word=scan(buffer,i," ");
         do while (word ne "");
            name=scan(word,1,"=");
            rename=scan(word,2,"=");
            _uname_=upcase(name);
            output;
            i+1;
            word=scan(buffer,i," ");
         end;
         keep _uname_ name rename;
      run;
   %end;

   data _meta_columns_ (index=(_order_));
      length _order_ 8 _uname_ name rename $32 type $4 length 8 format informat $49 label $256;
      length _order_so _order_sh _order_md in_source in_shell in_columns in_rename 8;
      call missing(of _all_);
      merge
         %if %sysfunc(exist(_meta_source_))  %then _meta_source_  (in=in_source  rename=(_order_=_order_so));
         %if %sysfunc(exist(_meta_shell_))   %then _meta_shell_   (in=in_shell   rename=(_order_=_order_sh));
         %if %sysfunc(exist(_meta_columns_)) %then _meta_columns_ (in=in_columns rename=(_order_=_order_md));
         %if %sysfunc(exist(_meta_rename_))  %then _meta_rename_  (in=in_rename);
      ;
      by _uname_;
      _order_=coalesce(_order_sh,_order_md,_order_so);

      %* if drop or keep were specified, drop or keep that metadata ;
      %* if both were specified, drop has precedence ;
      %if (&drop ne )                        %then %do; if _uname_ in (%upcase(%seplist(&drop,nest=QQ))) then delete; %end;
      %if (&keep ne )                        %then %do; if _uname_ in (%upcase(%seplist(&keep,nest=QQ))); %end;

      %* check if variables were specified in shell, metadata, or rename, but are not in source ;
      in_meta=max(0,in_shell,in_columns,in_rename);

      if (in_meta and not in_source) then do;
         putlog "WAR" "NING: " _uname_ "variable is not in &data data set.  Check log for further WAR" "NINGS or ERR" "ORS.";
      end;

      %* only keep those variables specified in the metadata ;
      if in_meta;

      drop _order_so _order_sh _order_md in_source in_shell in_columns in_rename;
   run;
   data _meta_columns_;
      set _meta_columns_ end=eof;
      by _order_;

      %* build keep and rename statements from metadata, overriding KEEP and/or RENAME parameters ;
      length buffer buffer2 $32767;
      retain buffer buffer2;
      buffer=catx(" ",buffer,name);
      if ^missing(rename) then buffer2=catx(" ",buffer2,catx("=",name,rename));
      if (eof) then call symputx("keep",buffer,"F");
      if (eof) then call symputx("rename",buffer2,"F");
      drop buffer buffer2;
   run;
%end;

%*---------------------------------------------------------------------
CREATE UTILITY MACROS
--------------------------------------------------------------------- ;

%* Utility macro to parse the BY parameter, ;
%* implementing correct descending syntax for both SAS and SQL ;
%macro parse_by(by=, lang=);
   %local temp;
   %let lang=%upcase(&lang);
   %let i=1;
   %let word=%scan(&by,&i,%str( ));
   %do %while (%quote(&word) ne );
      %if (%qsubstr(&word,1,1) eq %str(-)) %then %do;
         %if (&lang eq SAS) %then %do;
            %let word=descending %substr(&word,2);
         %end;
         %else %do;
            %let word=%substr(&word,2) desc;
         %end;
      %end;
      %if (&lang eq SAS) %then %do;
         %let temp=&temp &word;
      %end;
      %else %do;
         %if (&i gt 1) %then %let temp=&temp,;
         %let temp=&temp &word;
      %end;
      %let i=%eval(&i+1);
      %let word=%scan(&by,&i,%str( ));
   %end;
&temp
%mend;

%* if generating output code, get length of longest variables for cleaner code generation ;
%local max_name max_length max_format max_informat max_rename;
%if (%superq(file) ne ) %then %do;
   %if (%sysfunc(exist(_meta_columns_))) %then %do;
      proc sql noprint;
         select
             max(lengthn(name))
            ,case
                when missing(length) then 0
                else max(lengthn(put(length,8.-L)))
             end
            ,max(lengthn(format))
            ,max(lengthn(informat))
            into :max_name, :max_length, :max_format, :max_informat
         from
            _meta_columns_
         ;
         %if (%varexist(_meta_columns_,rename)) %then %do;
         select
            max(lengthn(rename))
            into :max_rename
         from
            _meta_columns_
         ;
         %end;
      quit;

      %* remove leading spaces ;
      %let max_name=&max_name;
      %let max_length=&max_length;
      %let max_format=&max_format;
      %let max_informat=&max_informat;
      %let max_rename=&max_rename;
   %end;
%end;

%macro SASMacro(
DATA=
,OUT=
,KEEP=
,DROP=
,BY=
,INDEX=
,WHERE=
,RENAME=
,META_COLUMNS=
,META_COLUMNS_COND=
,SHELL=
,TYPE=
,PRE_PROCESS=
,POST_PROCESS=
);

%local name rename type length label format informat;

%* parse by variable to build descending option ;
%let by=%parse_by(by=&by,lang=&lang);

%* create SAS data set / view ;
data &out
   %if (%superq(dslabel)%superq(index_stmt)%superq(out_options) ne ) %then %do; (   %end;
   %if (%superq(dslabel)            ne )              %then %do; label=&dslabel     %end;
   %if (%superq(index_stmt)         ne )              %then %do; &index_stmt        %end;
   %if (%superq(out_options)        ne )              %then %do; &out_options       %end;
   %if (%superq(dslabel)%superq(index_stmt)%superq(out_options) ne ) %then %do; )   %end;

   %if (&type eq VIEW)                                %then %do; / view=&out        %end;
   ;

   %if (%superq(pre_process)        ne )              %then %do; &pre_process;      %end;

   %* if shell data set or metadata data set was specified then create attrib statements ;
   %if (%sysfunc(exist(_meta_columns_))) %then %do;
      %let dsid=%sysfunc(open(_meta_columns_,i));
      %syscall set(dsid);
      %if (%superq(length) eq 0 or %superq(length) eq .) %then %let length=;
      %do %while (%sysfunc(fetch(&dsid)) eq 0);
         %if (%superq(label)        ne ) %then %let label=%sysfunc(quote(&label));
         attrib
            &name
            %if (&length            ne )              %then %if (&type eq char) %then %let length=$&length;
            %if (&length            ne )              %then %do; length=&length     %end;
            %if (&format            ne )              %then %do; format=&format     %end;
            %if (&informat          ne )              %then %do; informat=&informat %end;
            %if (&label             ne )              %then %do; label=&label       %end;
         ;
      %end;
      %let dsid=%sysfunc(close(&dsid));
   %end;

   set &data
   %if (%superq(data_options)       ne )              %then %do; (&data_options)    %end;
   ;

   %if (%superq(where)              ne )              %then %do; where &where;      %end;
   %if (%superq(rename)             ne )              %then %do; rename &rename;    %end;
   %if (%superq(keep)               ne )              %then %do; keep &keep;        %end;
   %if (%superq(drop)               ne )              %then %do; drop &drop;        %end;

   %if (%superq(post_process)       ne )              %then %do; &post_process;     %end;
run;

%* if by was specified and index=N then sort the output data set ;
%if (%superq(by) ne ) %then %do;
   %if (&index_stmt eq ) %then %do;
      proc sort data=&out out=&out_saved;
         by &by;
      run;
   %end;
%end;

%mend;

%macro SASCode(
DATA=
,OUT=
,KEEP=
,DROP=
,BY=
,INDEX=
,WHERE=
,RENAME=
,META_COLUMNS=
,META_COLUMNS_COND=
,SHELL=
,TYPE=
,PRE_PROCESS=
,POST_PROCESS=
,FILE=
,RUN=
);

%* parse by variable to build descending option ;
%let by=%parse_by(by=&by,lang=&lang);

%* account for leading $ for character variables ;
%let max_length=%eval(&max_length+1);

%* generate SAS code ;
data _null_;
   length buffer $32767;
   call missing(buffer);

   * create column pointers for generated code fragments ;
   c_spacing   = 2;
   c_name      = 7;
   c_length    = c_name       + (&max_name     gt 0) * (                       &max_name     + c_spacing);
   c_format    = c_length     + (&max_length   gt 0) * (lengthn("length=")   + &max_length   + c_spacing);
   c_informat  = c_format     + (&max_format   gt 0) * (lengthn("format=")   + &max_format   + c_spacing);
   c_label     = c_informat   + (&max_informat gt 0) * (lengthn("informat=") + &max_informat + c_spacing);

   %macro dsvar;
      %local temp;
      %let temp=%unquote(&&&word);
      %if (%superq(temp) eq ) %then %do;
         &word = "";
      %end;
      %else %do;
         &word = %sysfunc(quote(%superq(temp)));
      %end;
   %mend;
   %loop(
      data data_options out out_options out_saved dslabel
      where keep drop rename
      by index_stmt
      pre_process post_process
      ,mname=dsvar
   )

   file &_out_fileref col=c;

   link start;
   link pre_process;
   link attrib;
   link set;
   link where;
   link post_process;
   link keep;
   link drop;
   link rename;
   link run;
   link sort;

   stop;

start:
   c=1;                                                        put @c "data " out @;
   if (^missing(cats(dslabel,index_stmt,out_options)))   then  put "(" @;
   if (^missing(dslabel))                                then  put "label=" dslabel @;
   if (^missing(index_stmt))                             then  put index_stmt @;
   if (^missing(out_options))                            then  put out_options @;
   c=c-1;
   if (^missing(cats(dslabel,index_stmt,out_options)))   then  put @c ") " @;
   if ("&type" eq "VIEW")                                then  put "/ view=" out @;
   put +(-1) ";";
return;

attrib:
   %if (%sysfunc(exist(_meta_columns_))) %then %do;
      c=4;                                                     put @c "attrib";
      eof=0;
      do until (eof);
         call missing(buffer);
         set _meta_columns_ (drop=rename) end=eof;
         c=c_name;                                             put @c name $%eval(&max_name+2).-L @;
         if (^missing(length))                           then  buffer=ifc(type eq "char",cats("$",length),cats(length));
         c=c_length;   if (^missing(buffer))             then  put @c "length=" buffer $%sysfunc(max(1,&max_length)).-R @;
         c=c_format;   if (^missing(format))             then  put @c "format=" format $%eval(&max_format+2).-L @;
         c=c_informat; if (^missing(informat))           then  put @c "informat=" informat $%eval(&max_informat+2).-L @;
         c=c_label;    if (^missing(label))              then  do;
            buffer=quote(trim(label));
                                                               put @c "label=" buffer @;
         end;
         put;
      end;
      c=4;                                                     put @c ";";
   %end;
return;

set:
   c=4;                                                        put @c "set " data @;
   if (^missing(data_options))                           then  put "(" data_options +(-1) ")" @;
   c=c-1;                                                      put @c ";";
return;

where:
   c=4; if (^missing(where))                            then  put @c "where " where +(-1) ";";
return;

keep:
   %splitvar(keep, 70, split=~, hanging_indent=0)
   c=4; if (^missing(keep))                             then  put @c "keep";
   i=1;
   buffer=scan(keep,i,"~");
   do while (buffer ne "");
      c=7;
      put @c buffer;
      i+1;
      buffer=scan(keep,i,"~");
   end;
   c=4;                                                       put @c ";";
return;

drop:
   c=4; if (^missing(drop))                             then  put @c "drop " drop +(-1) ";";
return;

rename:
   %splitvar(rename, 70, split=~, hanging_indent=0)
   c=4; if (^missing(rename))                           then  put @c "rename";
   i=1;
   buffer=scan(rename,i,"~");
   do while (buffer ne "");
      c=7;
      put @c buffer;
      i+1;
      buffer=scan(rename,i,"~");
   end;
   c=4;                                                       put @c ";";
return;

run:
   c=1;                                                        put @c "run;" /;
return;

%* if by was specified and index=N then sort the output data set ;
sort:
   if (^missing(by) and missing(index_stmt))             then do;
   c=1;                                                        put @c "proc sort data=" out "out=" out_saved @;
   if (^missing(cats(dslabel,out_options)))              then  put "(" @;
   if (^missing(dslabel))                                then  put "label=" dslabel @;
   if (^missing(out_options))                            then  put out_options @;
   c=c-1;
   if (^missing(cats(dslabel,out_options)))              then  put @c ") " @;
   c=c-1;                                                      put @c ";";
   c=4;                                                        put @c "by " by +(-1) ";";
   c=1;                                                        put @c "run;" /;
   end;
return;

pre_process:
   c=4; if (^missing(pre_process))                       then  put @c pre_process +(-1) ";";
return;

post_process:
   c=4; if (^missing(post_process))                      then  put @c post_process +(-1) ";";
return;

run;

%if (&run) %then %do;
   %let options=%sysfunc(getoption(mprint,keyword));
   options nomprint;
   %include &_out_fileref / source source2;
   options &options;
%end;

%mend;

%macro SQLMacro(
DATA=
,OUT=
,KEEP=
,DROP=
,BY=
,INDEX=
,WHERE=
,RENAME=
,META_COLUMNS=
,META_COLUMNS_COND=
,SHELL=
,TYPE=
,PRE_PROCESS=
,POST_PROCESS=
);

%* parse by variable to build descending option ;
%let by=%parse_by(by=&by,lang=&lang);

%* generate SQL code ;
proc sql;
   create %sysfunc(ifc(&type eq VIEW,view,table)) &out

   %if (%superq(dslabel)%superq(index_stmt)%superq(out_options) ne ) %then %do; (   %end;
   %if (%superq(dslabel)            ne )              %then %do; label=&dslabel     %end;
   %if (%superq(index_stmt)         ne )              %then %do; &index_stmt        %end;
   %if (%superq(out_options)        ne )              %then %do; &out_options       %end;
   %if (%superq(dslabel)%superq(index_stmt)%superq(out_options) ne ) %then %do; )   %end;

   as
      select

      %if (%sysfunc(exist(_meta_columns_))) %then %do;
         %let i=0;
         %let dsid=%sysfunc(open(_meta_columns_,i));
         %syscall set(dsid);
         %if (%superq(length) eq 0 or %superq(length) eq .) %then %let length=;
         %do %while (%sysfunc(fetch(&dsid)) eq 0);
            %if (%superq(label)     ne ) %then %let label=%sysfunc(quote(&label));
            %if (&i ne 0)                             %then %do; ,                  %end;
            &name
            %if (%superq(rename)    ne )              %then %do; as &rename         %end;
            %if (%superq(length)    ne )              %then %do; length=&length     %end;
            %if (%superq(format)    ne )              %then %do; format=&format     %end;
            %if (%superq(informat)  ne )              %then %do; informat=&informat %end;
            %if (%superq(label)     ne )              %then %do; label=&label       %end;
            %let i=1;
         %end;
         %let dsid=%sysfunc(close(&dsid));
      %end;

      from &data
      %if (%superq(data_options)    ne )              %then %do; (&data_options)    %end;

      %if (%superq(where)           ne )              %then %do; where &where       %end;
      %if ((%superq(by) ne ) and (&index_stmt eq ))   %then %do; order by &by       %end;
      ;
   quit;
run;

%mend;

%macro SQLCode(
DATA=
,OUT=
,KEEP=
,DROP=
,BY=
,INDEX=
,WHERE=
,RENAME=
,META_COLUMNS=
,META_COLUMNS_COND=
,SHELL=
,TYPE=
,PRE_PROCESS=
,POST_PROCESS=
,FILE=
,RUN=
);

%* parse by variable to build descending option ;
%let by=%parse_by(by=&by,lang=&lang);

%* generate SQL code ;
data _null_;
   length buffer $32767;
   call missing(buffer);

   * create column pointers for generated code fragments ;
   c_spacing   = 2;
   c_name      = 10;
   c_rename    = c_name + 1   + (&max_name     gt 0) * (&max_name + c_spacing);
   c_length    = c_rename     + (&max_rename   gt 0) * (lengthn(" as")       + &max_rename   + c_spacing);
   c_format    = c_length     + (&max_length   gt 0) * (lengthn("length=")   + &max_length   + c_spacing);
   c_informat  = c_format     + (&max_format   gt 0) * (lengthn("format=")   + &max_format   + c_spacing);
   c_label     = c_informat   + (&max_informat gt 0) * (lengthn("informat=") + &max_informat + c_spacing);

   %macro dsvar;
      %local temp;
      %let temp=%unquote(&&&word);
      %if (%superq(temp) eq ) %then %do;
         &word = "";
      %end;
      %else %do;
         &word = %sysfunc(quote(%superq(temp)));
      %end;
   %mend;
   %loop(
      data data_options out out_options out_saved dslabel
      where keep drop
      by index_stmt
      pre_process post_process
      ,mname=dsvar
   )

   file &_out_fileref col=c;

   link start;
   link pre_process;
   link create;
   link select;
   link post_process;
   link from;
   link where;
   link by;
   link quit;

   stop;

start:
   c=1;                                                        put @c "proc sql;";
return;

create:
   c=4;                                                        put @c "create " @;
   buffer=ifc("&type" eq "VIEW","view","table");
   buffer=catx(" ",buffer,out);
                                                               put buffer @;
   if (^missing(cats(dslabel,index_stmt,out_options)))   then  put "(" @;
   if (^missing(dslabel))                                then  put "label=" dslabel @;
   if (^missing(index_stmt))                             then  put index_stmt @;
   if (^missing(out_options))                            then  put out_options @;
   c=c-1;
   if (^missing(cats(dslabel,index_stmt,out_options)))   then  put @c ") " @;

   put "as";
return;

select:
   c=7;                                                        put @c "select";
   i=0;
   do until (eof1);
      call missing(buffer);
      c=c_name+(i=0);                                          put @c @;
      if (i ne 0)                                        then  put "," @;
      set _meta_columns_ end=eof1;
                                                               put name $%eval(&max_name+1).-L @;
      c=c_rename; if (^missing(rename))                  then  put @c "as " rename $%eval(&max_rename+1).-L @;
      c=c_length; if (^missing(length))                  then  put @c "length=" length %sysfunc(max(1,&max_length)).-R @;
      c=c_format; if (^missing(format))                  then  put @c "format=" format $%eval(&max_format+1).-L @;
      c=c_informat; if (^missing(informat))              then  put @c "informat=" informat $%eval(&max_informat+1).-L @;
      if (^missing(label))                               then  do;
         buffer=quote(trim(label));
         c=c_label;                                            put @c "label=" buffer @;
      end;
      put;
      i=1;
   end;
return;

from:
   c=7;                                                        put @c "from";
   c=10;                                                       put @c data @;
   if (^missing(data_options))                           then  put "(" data_options +(-1) ")" @;
   put;
return;

where:
   if (^missing(where))                                  then do;
      c=7;                                                     put @c "where";
      c=10;                                                    put @c where;
   end;
return;

by:
   if (^missing(by))                                     then do;
      c=7;                                                     put @c "order by";
      c=10;                                                    put @c by;
   end;
return;

quit:
   c=4;                                                        put @c ";";
   c=1;                                                        put @c "quit;" /;
return;

pre_process:
   c=4; if (^missing(pre_process))                       then  put @c pre_process;
return;

post_process:
   c=7; if (^missing(post_process))                      then  put @c post_process;
return;

run;

%if (&run) %then %do;
   %let options=%sysfunc(getoption(mprint,keyword));
   options nomprint;
   %include &_out_fileref / source source2;
   options &options;
%end;

%mend;

%* now generate and/or execute the desired code ;
%if (&lang eq SAS and %superq(file) eq ) %then %do;
   %SASMacro(
      DATA=&data
      ,OUT=&out
      ,KEEP=&keep
      ,DROP=&drop
      ,BY=&by
      ,INDEX=&index
      ,WHERE=&where
      ,RENAME=&rename
      ,META_COLUMNS=&meta_columns
      ,META_COLUMNS_COND=&meta_columns_cond
      ,SHELL=&shell
      ,TYPE=&type
      ,PRE_PROCESS=&pre_process
      ,POST_PROCESS=&post_process
   )
%end;
%else
%if (&lang eq SAS and %superq(file) ne ) %then %do;
   %SASCode(
      DATA=&data
      ,OUT=&out
      ,KEEP=&keep
      ,DROP=&drop
      ,BY=&by
      ,INDEX=&index
      ,WHERE=&where
      ,RENAME=&rename
      ,META_COLUMNS=&meta_columns
      ,META_COLUMNS_COND=&meta_columns_cond
      ,SHELL=&shell
      ,TYPE=&type
      ,PRE_PROCESS=&pre_process
      ,POST_PROCESS=&post_process
      ,FILE=&file
      ,RUN=&run
   )
%end;
%else
%if (&lang eq SQL and %superq(file) eq ) %then %do;
   %SQLMacro(
      DATA=&data
      ,OUT=&out
      ,KEEP=&keep
      ,DROP=&drop
      ,BY=&by
      ,INDEX=&index
      ,WHERE=&where
      ,RENAME=&rename
      ,META_COLUMNS=&meta_columns
      ,META_COLUMNS_COND=&meta_columns_cond
      ,SHELL=&shell
      ,TYPE=&type
      ,PRE_PROCESS=&pre_process
      ,POST_PROCESS=&post_process
   )
%end;
%else
%if (&lang eq SQL and %superq(file) ne ) %then %do;
   %SQLCode(
      DATA=&data
      ,OUT=&out
      ,KEEP=&keep
      ,DROP=&drop
      ,BY=&by
      ,INDEX=&index
      ,WHERE=&where
      ,RENAME=&rename
      ,META_COLUMNS=&meta_columns
      ,META_COLUMNS_COND=&meta_columns_cond
      ,SHELL=&shell
      ,TYPE=&type
      ,PRE_PROCESS=&pre_process
      ,POST_PROCESS=&post_process
      ,FILE=&file
      ,RUN=&run
   )
%end;

%quit:
%if (%sysfunc(fileref(_code_)) le 0) %then %do;
   /* filename _code_ clear; */
%end;

%mend;

/******* END OF FILE *******/
