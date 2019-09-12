/*=====================================================================
Program Name            : export.sas
Purpose                 : Replacement macro for PROC EXPORT
SAS Version             : SAS 9.4
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 14JAN2016
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

Note: This macro is superceded by %export_dlm.

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%export(
   data=sashelp.class, 
   file="C:\Temp\file.csv"
);

Creates C:\Temp\file.csv as a comma separated values file 
   (default output file format).
Aborts if C:\Temp\file.csv already exists.

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.csv", 
   dbms=csv
);

Creates C:\Temp\file.csv as a comma separated values file
   (explicitly specified output file format).
Aborts if C:\Temp\file.csv already exists.

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.csv", 
   dbms=csv, 
   replace=Y
);

Overwrites C:\Temp\file.csv if it already exists.

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.tdf", 
   dbms=tab, 
   replace=Y
);

Creates C:\Temp\file.tdf as a tab delimited file.

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.txt", 
   dbms=dlm, 
   replace=Y
);

Creates C:\Temp\file.txt as a space delimited file
   (probably not what you want).

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.txt", 
   dbms=dlm, 
   replace=Y, 
   delimiter=|
);

Creates C:\Temp\file.txt as a pipe delimited file.
You can use any sequence of characters (including hexadecimal constants)
as the field delimiter.

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.txt", 
   dbms=dlm, 
   replace=Y, 
   dlm=|
);

dlm can be used as an alias for delimiter.

=======================================================================

data class;
   set sashelp.class;
   label
      name="Full Name"
      sex="Gender"
      height="How Tall?"
   ;
run;

%export(
   data=class, 
   file="C:\Temp\file.txt", 
   dbms=dlm, 
   delimiter=|,
   replace=Y,
   label=Y
);

Creates C:\Temp\file.txt as a pipe delimited file
Uses the labels from the data set for the header column name

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.txt"
   dbms=dlm, 
   delimiter=|,
   replace=Y,
   header=N
);

Creates C:\Temp\file.txt as a pipe delimited file.
Does not write a header row.

=======================================================================

filename temp temp;

%export(
   data=sashelp.class, 
   file=temp
   dbms=dlm, 
   delimiter=|
);

data _null_;
   infile temp;
   input;
   putlog _infile_;
run;

Writes sashelp.class to the fileref temp.

=======================================================================

%export(
   data=sashelp.class, 
   file="C:\Temp\file.txt
   dbms=dlm, 
   delimiter=|,
   replace=Y,
   header=Y,
   lrecl=999999
);

Increases the output logical record length from the default of 32767.
Use if your combined output linesize overflows 32767 characters.

-----------------------------------------------------------------------
Notes:

One of the main reasons for this macro is that PROC EXPORT puts 
unwanted double-quotes around the header field names when the LABEL
option is used.

This macro also allows specifying an output logical record length.

This code is based on (i.e. virtually copied from):
https://communities.sas.com/t5/ODS-and-Base-Reporting/How-to-use-labels-in-proc-export-or-create-tab-dlm-file-using/m-p/76789#M8698

---------------------------------------------------------------------*/

%macro export
/*---------------------------------------------------------------------
Replacement macro for PROC EXPORT.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */
,FILE=         /* Output file (REQ).                                 */
               /* Either a properly quoted physical file (single or) */
               /* double quotes), or an already allocated fileref    */
               /* may be specified.                                  */
,DBMS=CSV      /* Output file type (REQ).                            */
               /* CSV, TAB, or DLM may be specified.                 */
               /* Default value is CSV.                              */
               /* Ignored if DELIMITER is specified.                 */
,DELIMITER=    /* Output field delimiter (Opt).                      */
               /* If specified, the DBMS parameter is ignored.       */
               /* If not specified:                                  */
               /*    If DBMS=CSV, DELIMITER=,                        */
               /*    If DBMS=TAB, DELIMITER="09"x (tab)              */
               /*    If DBMS=DLM, DELIMITER=" " (space)              */
,DLM=          /* Output field delimiter (Opt).                      */
               /* DLM is an alias for DELIMITER.                     */
               /* If both are specified then DELIMITER is used.      */
,REPLACE=N     /* Replace output file? (Opt).                        */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,LABEL=N       /* Use data set labels instead of names? (Opt).       */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
               /* If the data set variable does not have a label     */
               /* then the variable name is used.                    */
,HEADER=Y      /* Output a header row? (Opt).                        */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
               /* If the data set variable does not have a label     */
               /* then the variable name is used.                    */
,LRECL=32767   /* Logical record length for output file (Opt).       */
               /* Default value is 32767 (32K)                       */
);

%local macro parmerr _dlm _type _exist;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(FILE,         _req=1,_words=1,_case=N)
%parmv(DBMS,         _req=1,_words=0,_case=U,_val=CSV TAB DLM)
%parmv(DELIMITER,    _req=0,_words=0,_case=N)
%parmv(DLM,          _req=0,_words=0,_case=N)
%parmv(REPLACE,      _req=0,_words=0,_case=U,_val=0 1)
%parmv(LABEL,        _req=0,_words=0,_case=U,_val=0 1)
%parmv(HEADER,       _req=0,_words=0,_case=U,_val=0 1)
%parmv(LRECL,        _req=0,_words=0,_case=U,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

%* additional error checking ;
%* if DELIMITER or DLM was specified then explicitly set the delimiter ;
%* and ignore the DBMS setting ;
%if (%superq(DELIMITER)%superq(DLM) ne ) %then %do;
   %let _dlm = %superq(DELIMITER);
   %if (%superq(_dlm) eq ) %then %let _dlm = %superq(DLM);
   %let _dlm = %sysfunc(compress(&_dlm,%str(%"%')));
   %let _dlm = "&_dlm";
%end;
%else %do;
   %if (&DBMS eq CSV) %then %let _dlm = %str(",");
   %else
   %if (&DBMS eq TAB) %then %let _dlm = %str("09"x);
   %else
   %if (&DBMS eq DLM) %then %let _dlm = %str(" ");
%end;
   
%* does the output file exist? ;
%let _exist=0;

%* quoted physical file ;
%if (%sysfunc(indexc(%superq(file),%str(%"%')))) %then %do;  
   %let _type=FILE;
   %let _exist=%sysfunc(fileexist(%superq(file)));
%end;
%* fileref ;
%else %do;
   %let _type=FILEREF;
   %* is the fileref allocated? ;
   %if (%sysfunc(fileref(%superq(file))) gt 0) %then %do;
      %let msg=%str(NO)TE: The &file fileref is not allocated. No output created.;
      %put &msg;
      %goto quit;
   %end;
   %let _exist=%sysfunc(fexist(%superq(file)));
%end;

%* file exists but replace was not specified ;
%if (&_exist and not &replace) %then %do;
   %if (&_type eq FILE) %then %do;
      %let file=%sysfunc(compress(%superq(file),%str(%"%')));
      %let msg=%str(NO)TE: &file already exists.;
      %let msg=&msg Specify REPLACE to overwrite.;
      %let msg=&msg No output created.;
   %end;
   %else
   %if (&_type eq FILEREF) %then %do;
      %let msg=%str(NO)TE: %sysfunc(pathname(%superq(file))) already exists.;
      %let msg=&msg Specify REPLACE to overwrite.;
      %let msg=&msg No output created.;
   %end;
   %put &msg;
   %goto quit;
%end;

data _null_;
   file &file dsd dlm=&_dlm lrecl=&lrecl;
   set &data;
   %if (&header) %then %do;
   if _n_ eq 1 then link header;
   %end;
   put (_all_)(:);
return;

%if (&header) %then %do;
header:
   length _LABEL_ $128 _NAME_ $32;
   if _n_ eq 1 then do;
      do while(1);
      call vnext(_name_);
      if _name_ eq '_LABEL_' then leave;
      _label_ = ifc(&label,vlabelx(_name_),_name_);
      put _label_ @;
   end;
   put;
   end;
return;
%end;

run;
%quit:

%mend;

/******* END OF FILE *******/
