/*=====================================================================
Program Name            : export_dlm.sas
Purpose                 : Replacement macro for PROC EXPORT for 
                          exporting a SAS dataset to a delimited file.
SAS Version             : SAS 9.4
Input Data              : SAS dataset
Output Data             : Delimited flat file

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

%let path=C:\Temp;  %* edit to suit your requirements ;

%export_dlm(
   data=sashelp.class
   ,path="&path"
)

Creates C:\Temp\class.csv as a CSV file

Default output is a CSV (comma separated values) file.
Default filename is <SAS dataset name>.csv 
if only a directory path is specified.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.csv"
   ,dbms=csv
);

Creates C:\Temp\file.csv as a CSV file
   (explicitly specified output file name).
Aborts if C:\Temp\file.csv already exists.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.csv" 
   ,replace=Y
);

Creates C:\Temp\file.csv as a CSV file,
replacing C:\Temp\file.csv if it already exists.

=======================================================================

%export_dlm(
   data=sashelp.shoes
   ,path="&path\"
   ,replace=Y
   ,label=Y
)

Creates C:\Temp\shoes.csv as a CSV file,
replacing C:\Temp\shoes.csv if it already exists,
using the column labels for the header row.

=======================================================================

%export_dlm(
   data=sashelp.cars
   ,path="&path\"
   ,replace=Y
   ,label=Y
   ,header=N
)

Creates C:\Temp\cars.csv as a CSV file,
replacing C:\Temp\cars.csv if it already exists,
without creating a header row.

The LABEL parameter is ignored if HEADER=N.

=======================================================================

data work.vwStocks / view=work.vwStocks;
   * reorder columns, moving volume to the end ;
   format Stock Date Open High Low Volume;
   set sashelp.stocks;
   * drop Close and AdjClose ;
   drop Close AdjClose;
   * use a different format for the Date column ;
   format Date e8601da.;
   * add labels ;
   label
      Open="Opening Price"
      High="Highest Price"
      Low="Lowest Price"
      Volume="Total Daily Volume"
   ;
run;

%export_dlm(
   data=work.vwStocks
   ,path="&path\stocks.csv"
   ,replace=Y
   ,label=Y
   ,header=Y
)

Creates C:\Temp\stocks.csv as a CSV file,
replacing C:\Temp\stocks.csv if it already exists,
using the column labels for the header row.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.tdf"
   ,dbms=tab
   ,replace=Y
);

Creates C:\Temp\file.tdf as a tab-delimited file,
replacing C:\Temp\file.tdf if it already exists.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.txt"
   ,dbms=dlm
   ,replace=Y
);

Creates C:\Temp\file.txt as a space delimited file,
   (probably not what you want)
replacing C:\Temp\file.txt if it already exists.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.txt"
   ,dbms=dlm
   ,replace=Y
   ,delimiter=|
);

Creates C:\Temp\file.txt as a pipe delimited file,
replacing C:\Temp\file.txt if it already exists.

You can use any sequence of characters (including hexadecimal constants)
as the field delimiter.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.txt"
   ,dbms=dlm
   ,replace=Y
   ,delimiter='A7'x
);

data _null_;
   infile "&path\file.txt";
   input;
   putlog _infile_;
run;

Creates C:\Temp\file.txt as a hex character delimited file,
replacing C:\Temp\file.txt if it already exists.

=======================================================================

%export_dlm(
   data=sashelp.class 
   ,path="&path\file.txt"
   ,dbms=dlm
   ,replace=Y
   ,dlm=|
);

dlm can be used as an alias for delimiter.

=======================================================================

* test single level dataset name ;
data cars;
   set sashelp.cars;
run;

%export_dlm(
   data=cars (where=(make =: 'Mercedes' and type='Sports'))
   ,path="&path\MercedesBenzSportsCars.csv"
   ,replace=Y
);

Creates C:\Temp\MercedesBenzSportsCars.csv as a CSV file,
replacing C:\Temp\MercedesBenzSportsCars.csv if it already exists,
containing Mercedes-Benz sports cars.

=======================================================================

filename temp temp;

%export_dlm(
   data=sashelp.class
   ,path=temp
   ,dbms=dlm 
   ,delimiter=|
);

data _null_;
   infile temp;
   input;
   putlog _infile_;
run;

Writes sashelp.class to the fileref temp as a pipe delimited file.

Use an unquoted path to specify a fileref.

=======================================================================

%export_dlm(
   data=sashelp.class
   ,path="&path\file.txt"
   ,dbms=dlm
   ,delimiter=|
   ,replace=Y
   ,header=Y
   ,lrecl=999999
);

Increases the output logical record length from the default of 32767.
Use if your combined output linesize overflows 32767 characters.

=======================================================================

Error checking:

%export_dlm(
   data=sashelp.DoesNotExist
   ,path="&path"
   ,replace=Y
);

Fails, SAS dataset sashelp.DoesNotExist does not exist.

%export_dlm(
   data=sashelp.class
   ,path="Z:\"
   ,replace=Y
);

Fails, drive letter Z: does not exist.

%export_dlm(
   data=sashelp.class
   ,path="C:\DoesNotExist"
   ,replace=Y
);

Fails, output directory does not exist.
The macro does not trap for this edge case error,
although the code fails as it should.

%export_dlm(
   data=sashelp.class
   ,path="C:\DoesNotExist\file.csv"
   ,replace=Y
);

Fails, output directory (part of file path) does not exist.

%export_dlm(
   data=sashelp.class
   ,path=FOO
   ,replace=Y
);

Fails, FOO fileref is not already allocated.

-----------------------------------------------------------------------
Notes:

One of the main reasons for this macro is that PROC EXPORT puts 
unwanted double-quotes around the header field names when the LABEL
option is used.

PROC EXPORT also has issues with long formats
(truncates the long format names)

This macro also allows specifying an output logical record length.

Physical output paths MUST be single or double quoted.
This is to indicate that it is a physical path and not a fileref.

If you specify a non-existent directory only, this macro does not
trap for that error, although the code will fail when it attempts
to create a file in the non-existent path.

For example:

%export_dlm(
   data=sashelp.class
   ,path="C:\DoesNotExist"
   ,replace=Y
);

If you specify a non-existent directory as part of the file path,
this macro will trap for that error.

For example:

%export_dlm(
   data=sashelp.class
   ,path="C:\DoesNotExist\file.csv"
   ,replace=Y
);

Note the different error messages from the two different invocations.

This code is based on (i.e. virtually copied from):
https://communities.sas.com/t5/ODS-and-Base-Reporting/How-to-use-labels-in-proc-export-or-create-tab-dlm-file-using/m-p/76789#M8698

---------------------------------------------------------------------*/

%macro export_dlm
/*---------------------------------------------------------------------
Replacement macro for PROC EXPORT for 
exporting a SAS dataset to a delimited file.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */
,PATH=         /* Output directory or file path (REQ).               */
               /* Either a properly quoted physical file             */
               /* (single or double quotes), or an already allocated */
               /* fileref may be specified.                          */
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

%global syscc;
%local macro parmerr;
%local _rc _temp _pos _type _exist _fileref _is_dir _dir _lib _ds _dlm;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows multiple datasets */
%parmv(PATH,         _req=1,_words=1,_case=N)
%parmv(DBMS,         _req=1,_words=0,_case=U,_val=CSV TAB DLM)
%parmv(DELIMITER,    _req=0,_words=0,_case=N)
%parmv(DLM,          _req=0,_words=0,_case=N)
%parmv(REPLACE,      _req=0,_words=0,_case=U,_val=0 1)
%parmv(LABEL,        _req=0,_words=0,_case=U,_val=0 1)
%parmv(HEADER,       _req=0,_words=0,_case=U,_val=0 1)
%parmv(LRECL,        _req=0,_words=0,_case=U,_val=POSITIVE)

%if (&parmerr) %then %return;

%* additional error checking ;

%* parse off any dataset options ;
%let _temp=%superq(data);
%let _pos=%sysfunc(findc(%superq(_temp),%str(%()));
%if (&_pos) %then %do;
   %let _temp=%substr(%superq(_temp),1,&_pos-1);
%end;

%* does the SAS dataset exist? ;
%if not (%sysfunc(exist(%superq(_temp),DATA)) or %sysfunc(exist(%superq(_temp),VIEW))) %then %do;
   %let syscc=8;
   %parmv(_msg=SAS dataset %superq(_temp) does not exist)
   %return;
%end;

%* If the path is a quoted physical name, check: ;
%*    1) Is it a directory?
%*    2) If not:
%*       A) Does the directory path for the file exist? (error);
%*       B) Does the file itself exist (not an error), ;
%*          but we need to know to propery process the REPLACE option. ;

%* initialize as not exists ;
%let _exist=0;

%* quoted physical file ;
%if (%sysfunc(findc(%superq(path),%str(%"%')))) %then %do;  
   %let _type=FILE;
   %* remove quotes to derive output file path ;
   %let path=%sysfunc(compress(%superq(path),%str(%'%")));
%end;
%* fileref ;
%else %do;
   %let _type=FILEREF;
%end;

%if (&_type eq FILE) %then %do;
   %* create temporary fileref ;
   %let _fileref=;
   %let _rc=%sysfunc(filename(_fileref,"%superq(path)"));

   %* is the file a directory? ;
   %let _is_dir=%sysfunc(dopen(&_fileref));
   %let _msg=%sysfunc(sysmsg());
   %let _rc=%sysfunc(dclose(&_is_dir));
   %let _rc=%sysfunc(filename(_fileref));
   %*put &=_is_dir &=_msg;  %* for debugging, comment out in production ;

   %* if not a directory, assume it is a file and get the directory path ;
   %if (not &_is_dir) %then %do;
      %let _pos=%sysfunc(findc(%superq(path),\,-9999));
      %*put &=_pos;  %* for debugging, comment out in production ;
      %if (&_pos) %then %do;
         %let _dir=%substr(%superq(path),1,&_pos);
         %*put &=_dir;  %* for debugging, comment out in production ;

         %* does the directory exist? ;
         %let _fileref=;
         %let _rc=%sysfunc(filename(_fileref,"%superq(_dir)"));
         %let _is_dir=%sysfunc(dopen(&_fileref));
         %let _msg=%sysfunc(sysmsg());
         %let _rc=%sysfunc(dclose(&_is_dir));
         %let _rc=%sysfunc(filename(_fileref));
         %*put &=_is_dir &=_msg;  %* for debugging, comment out in production ;

         %if (not &_is_dir) %then %do;
            %let syscc=8;
            %parmv(_msg=The directory %superq(_dir) does not exist.  No output created)
            %return;
         %end;

         %* does the file exist? (which is not an error) ;
         %let _fileref=;
         %let _rc=%sysfunc(filename(_fileref,"%superq(path)"));
         %let _exist=%sysfunc(fexist(&_fileref));
         %let _msg=%sysfunc(sysmsg());
         %let _rc=%sysfunc(filename(_fileref));
         %*put &=_exist &=_msg;  %* for debugging, comment out in production ;  
      %end;
   %end;

   %* it is a directory, so derive the output file name ;
   %else %do;
      %let _lib=%scan(%superq(_temp),1,.);
      %let _ds =%scan(%superq(_temp),2,.);
      %if (%superq(_ds) eq ) %then %let _ds=&_lib;
      %let path=%superq(path)\%superq(_ds);  %* this works whether the input path has a trailing \ or not ;
      %if (&dbms=CSV) %then
         %let path=%superq(path).csv;
      %else
      %if (&dbms=TAB) %then
         %let path=%superq(path).tdf;
      %else
      %if (&dbms=DLM) %then
         %let path=%superq(path).txt;

      %* does the file exist? (which is not an error) ;
      %let _fileref=;
      %let _rc=%sysfunc(filename(_fileref,"%superq(path)"));
      %let _exist=%sysfunc(fexist(&_fileref));
      %let _msg=%sysfunc(sysmsg());
      %let _rc=%sysfunc(filename(_fileref));
      %*put &=_exist &=_msg;  %* for debugging, comment out in production ;  
   %end;
%end;

%* already allocated fileref ;
%else
%if (&_type eq FILEREF) %then %do;
   %* is the fileref allocated? ;
   %if (%sysfunc(fileref(%superq(path))) gt 0) %then %do;
      %let syscc=8;
      %parmv(_msg=The %superq(path) fileref is not allocated. No output created)
      %return;
   %end;
   %let _exist=%sysfunc(fexist(%superq(path)));
   %*put &=_exist;  %* for debugging, comment out in production ;    
%end;

%* file exists but replace was not specified ;
%if (&_exist and not &replace) %then %do;
   %if (&_type eq FILE) %then %do;
      %let msg=%str(WAR)NING: "%superq(path)" already exists.;
      %let msg=&msg Specify REPLACE to overwrite.;
      %let msg=&msg No output created.;
   %end;
   %else
   %if (&_type eq FILEREF) %then %do;
      %let msg=%str(WAR)NING: "%sysfunc(pathname(%superq(path)))" already exists.;
      %let msg=&msg Specify REPLACE to overwrite.;
      %let msg=&msg No output created.;
   %end;
   %put &msg;  %* do not comment out this line ;
   %let syscc=4;
   %return;
%end;

%* add back the quotes to indicate that it is a physical filename ;
%if (&_type eq FILE) %then %do;
   %let path="%superq(path)";
%end;

%* if DELIMITER or DLM was specified then explicitly set the delimiter ;
%* and ignore the DBMS setting ;
%if (%superq(DELIMITER)%superq(DLM) ne ) %then %do;
   %let _dlm = %superq(DELIMITER);
   %if (%superq(_dlm) eq ) %then %let _dlm = %superq(DLM);

   %* if the delimiter is not a hex character then ensure it is properly quoted, ;
   %* otherwise assume that a hex character is properly quoted ;
   %let _rx=%sysfunc(prxparse(/['|"][0-9a-f]+["|']x/i));
   %if not (%sysfunc(prxmatch(&_rx,%superq(_dlm)))) %then %do;
      %let _dlm = %sysfunc(compress(&_dlm,%str(%"%')));
      %let _dlm = "&_dlm";
   %end;
   %syscall prxfree(_rx);
%end;
%else %do;
   %if (&DBMS eq CSV) %then %let _dlm = %str(",");
   %else
   %if (&DBMS eq TAB) %then %let _dlm = %str("09"x);
   %else
   %if (&DBMS eq DLM) %then %let _dlm = %str(" ");
%end;
%let _dlm=%unquote(&_dlm);

data _null_;
   file &path dsd dlm=&_dlm lrecl=&lrecl;
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

%mend;

/******* END OF FILE *******/
