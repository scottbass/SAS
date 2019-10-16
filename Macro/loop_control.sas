/*=====================================================================
Program Name            : loop_control.sas
Purpose                 : A "wrapper" macro to execute code over a
                          list of items defined in a control table
SAS Version             : SAS 9.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 16MAY2016
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
Date                    : 16OCT2019
Change/reason           : Added __iter__ row counter.
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%macro code;
    %put &name &sex &age &height &weight;
%mend;
%loop_control(control=sashelp.class)

=======================================================================

* The macro variables are not automatically trimmed ;
* Sometimes this is useful, sometimes not ;
%macro cars;
    %put |#&make# *&type* +&model+|;
%mend;
%loop_control(control=sashelp.cars,mname=cars)

=======================================================================

* If you need trimmed macro variables, do so in the child macro ;
%macro cars;
    %let make=%trim(&make);
    %let model=%trim(&model);
    %let type=%trim(&type);
    %put |#&make# *&type* +&model+|;
%mend;
%loop_control(control=sashelp.cars,mname=cars)

=======================================================================

* firstobs and obs dataset options are ignored ;
* see http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148395.htm ;
%macro code;
    %put &name &sex &age &height &weight;
%mend;
%loop_control(control=sashelp.class(firstobs=5 obs=10))

=======================================================================

* So, use a view instead ;
data v_class / view=v_class;
   set sashelp.class (firstobs=5 obs=10);
run;
%macro code;
    %put &name &sex &age &height &weight;
%mend;
%loop_control(control=v_class)

=======================================================================

* But a where clause and other dataset options are honoured ;
* This will generate "unresolved macro variable reference" for weight ;
%macro code;
    %put &name &sex &age &height &weight;
%mend;
%loop_control(control=sashelp.class (where=(sex="F") drop=weight))

=======================================================================

* A more complex (albeit contrived) example ;
data metadata;
   length proc $32 data vars $100;
   infile datalines dsd dlm="|";
   input proc data vars;
   datalines;
PRINT    | SASHELP.SHOES (where=(region="Pacific"))  | _all_
SUMMARY  | SASHELP.CLASS   | height weight
FREQ     | SASHELP.CARS    | type
PRINT    | SASHELP.STOCKS (where=(close between 90 and 100))   | stock date close
;
run;

%macro code;
   %let proc=%upcase(&proc);
   %if (&proc eq SUMMARY) %then %do;
      PROC SUMMARY DATA=&data nway
         FW=12
         PRINTALLTYPES
         CHARTYPE
         NOLABELS
            MEAN 
            MIN 
            MAX 
            NONOBS
         ;
         VAR &vars;
      RUN;
   %end;
   %else
   %if (&proc eq FREQ) %then %do;
      PROC FREQ DATA=&data ORDER=INTERNAL;
         TABLES &vars /  SCORES=TABLE;
      RUN;
   %end;   
   %else
   %if (&proc eq PRINT) %then %do;
      PROC PRINT DATA=&data;
         var &vars;
      RUN;
   %end;   
%mend;
%loop_control(control=metadata)

=======================================================================

* error checking ;
%macro code;
   %put _local_;
%mend;
%loop_control(control=doesnotexist)

-----------------------------------------------------------------------
Notes:

The child macro "%code" must be created at run time before calling
this macro.

A local macro variable will be created whose name matches the name
of every variable in the control dataset.  The child macro is 
responsible for referencing the macro variables by the correct name.

The child macro will be called for each logical observation that is
read from the control dataset.

There is no need to globalize any of the macro variables, since the 
names are "reused" during each iteration.  If you REALLY need a 
"macro array" of macro variables (i.e. MVAR1, MVAR2, MVAR3, etc), 
you should use a different approach, rather than trying to force 
this macro to do this for you.

---------------------------------------------------------------------*/

%macro loop_control
/*---------------------------------------------------------------------
A "wrapper" macro to execute code over a list of items defined in a 
control table 
---------------------------------------------------------------------*/ 
(CONTROL=      /* Control table defining the data used by the child  */
               /* macro (REQ).                                       */
,MNAME=code    /* Macro name (REQ).  Default is "%code"              */
);

%local macro parmerr __iter__ _data_;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(CONTROL,      _req=1,_words=1,_case=N)  /* words allows ds options */
%parmv(MNAME,        _req=1,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* parse off any data set options ;
%let _data_=%scan(&control,1,%str( %());

%* does the control table exist? ;
%if not (%sysfunc(exist(&_data_,data)) or %sysfunc(exist(&_data_,view))) %then %do;
   %parmv(_msg=The &control dataset or view does not exist)
   %goto quit;
%end;

%* open control table for input ;
%let dsid=%sysfunc(open(&control,i));

%* if unable to open the control table abort ;
%if (not &dsid) %then %do;
   %parmv(_msg=Unable to open &control for input)
   %goto quit;
%end;

%* create a local macro variable for each variable in the PDV ;
%* the macro variable name will be the same as the dataset variable name ;
%syscall set(dsid);

%* iterate over the control dataset, calling the child macro for each record ;
%* the macro variable names in the child macro must match the variable names in the control dataset ;
%let __iter__ = 1;
%do %while (%sysfunc(fetch(&dsid)) eq 0);
%&mname
%let __iter__ = %eval(&__iter__+1);
%end;

%* close the open control table ;
%let dsid=%sysfunc(close(&dsid));

%quit:

%mend;

/******* END OF FILE *******/
