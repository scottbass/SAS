/*=====================================================================
Program Name            : export_dbms.sas
Purpose                 : Wrapper macro for PROC EXPORT
                          used to export a SAS dataset to an external file.
SAS Version             : SAS 9.4
Input Data              : SAS dataset
Output Data             : External file

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

Approach to deleting .bak files that are created by PROC COPY 
is derived from original ideas by SAS Communities user "LaurieF".
https://communities.sas.com/t5/SAS-Programming/Clean-bak-files-from-PROC-EXPORT/m-p/362602/highlight/true#M85677

=======================================================================

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%let path=\\sascs\linkage\RL_content_snapshots\Temp;  %* edit to suit your requirements ;

%export_dbms(
   data=sashelp.class
   ,path="&path"
)

Creates C:\Temp\class.xlsx as an XLSX file

Default output is an XLSX (Excel) file.
Default filename is <SAS dataset name>.xlsx 
if only a directory path is specified.

=======================================================================

%export_dbms(
   data=sashelp.class
   ,path="&path\file.xlsx"
);

Creates C:\Temp\file.xlsx as an XLSX file
   (explicitly specified output file name).
Aborts if C:\Temp\file.xlsx already exists.

=======================================================================

%export_dbms(
   data=sashelp.class
   ,path="&path\file.xlsx" 
   ,replace=Y
);

Creates C:\Temp\file.xlsx as an XLSX file,
replacing C:\Temp\file.xlsx if it already exists.

=======================================================================

%export_dbms(
   data=sashelp.shoes
   ,path="&path\"
   ,replace=Y
   ,label=Y
)

Creates C:\Temp\shoes.xlsx as an XLSX file,
replacing C:\Temp\shoes.xlsx if it already exists,
using the column labels for the header row.

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

%export_dbms(
   data=work.vwStocks
   ,path="&path\stocks.xlsx"
   ,replace=Y
   ,label=Y
)

Creates C:\Temp\stocks.xlsx as an XLSX file,
replacing C:\Temp\stocks.xlsx if it already exists,
using the column labels for the header row.

=======================================================================

%export_dbms(
   data=sashelp.class
   ,path="&path"
   ,dbms=xls
   ,replace=Y
);

Creates C:\Temp\class.xls as an XLS file,
replacing C:\Temp\class.xls if it already exists.

=======================================================================

%export_dbms(
   data=sashelp.class
   ,path="&path"
   ,dbms=spss
   ,replace=Y
);

Creates C:\Temp\class.sav as an SPSS file,
replacing C:\Temp\class.sav if it already exists.

=======================================================================

%export_dbms(
   data=sashelp.class
   ,path="&path\"
   ,dbms=stata
   ,replace=Y
);

Creates C:\Temp\class.dta as a STATA file,
replacing C:\Temp\class.dta if it already exists.

=======================================================================

%export_dbms(
   data=sashelp.shoes
   ,path="&path\labels.sav"
   ,dbms=spss
   ,replace=Y
   ,label=Y
);

Creates C:\Temp\labels.sav as an SPSS file,
replacing C:\Temp\labels.sav if it already exists,
using the column labels for the column names.

=======================================================================

%export_dbms(
   data=sashelp.shoes
   ,path="&path\labels.dta"
   ,dbms=stata
   ,replace=Y
   ,label=Y
);

Creates C:\Temp\labels.dta as a STATA file,
replacing C:\Temp\labels.dta if it already exists,
using the column labels for the column names.

=======================================================================

* test single level dataset name ;
data cars;
   set sashelp.cars;
run;

%export_dbms(
   data=cars (where=(make =: 'Mercedes' and type='Sports'))
   ,path="&path\MercedesBenzSportsCars.xlsx"
   ,replace=Y
);

Creates C:\Temp\MercedesBenzSportsCars.xlsx as an XLSX file,
replacing C:\Temp\MercedesBenzSportsCars.xlsx if it already exists,
containing Mercedes-Benz sports cars.

=======================================================================

filename temp temp;

%export_dbms(
   data=sashelp.class
   ,path=temp
   ,replace=Y
);

Writes sashelp.class to the fileref temp as an XLSX file.

Use an unquoted path to specify a fileref.

=======================================================================

Error checking:

%export_dbms(
   data=sashelp.DoesNotExist
   ,path="&path"
   ,replace=Y
);

Fails, SAS dataset sashelp.DoesNotExist does not exist.

%export_dbms(
   data=sashelp.class
   ,path="Z:\"
   ,replace=Y
);

Fails, drive letter Z: does not exist.

%export_dbms(
   data=sashelp.class
   ,path="C:\DoesNotExist"
   ,replace=Y
);

Fails, output directory does not exist.
The macro does not trap for this edge case error,
although the code fails as it should.

%export_dbms(
   data=sashelp.class
   ,path="C:\DoesNotExist\file.xlsx"
   ,replace=Y
);

Fails, output directory (part of file path) does not exist.

%export_dbms(
   data=sashelp.class
   ,path=FOO
   ,replace=Y
);

Fails, FOO fileref is not already allocated.

-----------------------------------------------------------------------
Notes:

Physical output paths MUST be single or double quoted.
This is to indicate that it is a physical path and not a fileref.

If you specify a non-existent directory only, this macro does not
trap for that error, although the code will fail when it attempts
to create a file in the non-existent path.

For example:

%export_dbms(
   data=sashelp.class
   ,path="C:\DoesNotExist"
   ,replace=Y
);

If you specify a non-existent directory as part of the file path,
this macro will trap for that error.

For example:

%export_sbms(
   data=sashelp.class
   ,path="C:\DoesNotExist\file.xlsx"
   ,replace=Y
);

Note the different error messages from the two different invocations.

PROC EXPORT creates an annoying backup of an external file
if it already exists, even if the replace option is specified.

For example, if you run this code twice:

proc export data=sashelp.class outfile="&path\file.xlsx" dbms=replace;
run;

The file "&path\file.xlsx.bak" will be created.

The macro will delete that .bak file if it exists.

---------------------------------------------------------------------*/

%macro export_dbms
/*---------------------------------------------------------------------
Wrapper macro for PROC EXPORT used to export a SAS dataset 
to an external file.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */
,PATH=         /* Output directory or file path (REQ).               */
               /* Either a properly quoted physical file             */
               /* (single or double quotes), or an already allocated */
               /* fileref may be specified.                          */
,DBMS=XLSX     /* Output file type (REQ).                            */
               /* XLSX, XLS, SPSS, or STATA may be specified.        */
               /* Default value is XLSX.                             */
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
);

%global syscc;
%local macro parmerr;
%local _rc _temp _pos _type _exist _fileref _is_dir _dir _lib _ds _dlm;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows multiple datasets */
%parmv(PATH,         _req=1,_words=1,_case=N)
%parmv(DBMS,         _req=1,_words=0,_case=U,_val=XLSX XLS SPSS STATA)
%parmv(REPLACE,      _req=0,_words=0,_case=U,_val=0 1)
%parmv(LABEL,        _req=0,_words=0,_case=U,_val=0 1)

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
            %parmv(_msg=The directory "%superq(_dir)" does not exist.  No output created)
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
      %if (&dbms=XLSX) %then
         %let path=%superq(path).xlsx;
      %else
      %if (&dbms=XLS) %then
         %let path=%superq(path).xls;
      %else
      %if (&dbms=SPSS) %then
         %let path=%superq(path).sav;
      %else
      %if (&dbms=STATA) %then
         %let path=%superq(path).dta;

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

%* export to external file ;
proc export data=&data outfile=&path dbms=&dbms replace
   %if (&label) %then %do;
   label
   %end;
   ;
   %if %sysfunc(cexist(work.formats)) %then %do;
   fmtlib=work.formats; 
   %end;
run;

%* Delete PROC EXPORT annoying .bak file ;
%if (&_type eq FILE) %then %do;
   %let path=%sysfunc(compress(%superq(path),%str(%'%")));
   %if (%sysfunc(fileexist("&path..bak"))) %then %do;
      %let _rc=%sysfunc(filename(_fileref,"&path..bak"));
      %let _rc=%sysfunc(fdelete(&_fileref));
      %let _rc=%sysfunc(filename(_fileref));
   %end;
%end;

%mend;

/******* END OF FILE *******/
