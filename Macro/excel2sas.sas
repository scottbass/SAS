/*=====================================================================
Program Name            : excel2sas.sas
Purpose                 : Read an Excel workbook into a SAS dataset(s)
                          using PROC IMPORT
SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : None

Macros Called           : parmv, seplist, subset_data, loop, kill

Originally Written by   : Scott Bass
Date                    : 01MAY2007
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
Date                    : 07MAY2009
Change/reason           : Changed to use scan function to work with Excel
                          worksheets named like SheetName$_
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 19APR2011
Change/reason           : Added processing for reading Excel files on UNIX
Program Version #       : 1.2

Programmer              : Scott Bass
Date                    : 04NOV2016
Change/reason           : Changed default engine to EXCEL2007 on Windows
                          (should probably add an ENGINE parameter)
Program Version #       : 1.3

Programmer              : Scott Bass
Date                    : 07JUL2017
Change/reason           : Changed SELECT and EXCLUDE parameters to use  
                          Perl Regular Expression syntax rather than 
                          SQL syntax (i.e. like FOO%)
Program Version #       : 1.3

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%let file = C:\Path_to_Excel_Workbook.xls;

%excel2sas(file=&file)
   Import entire workbook,
      saving output datasets to work,
      naming output datasets based on worksheet names

%excel2sas(file=&file,select=Table 1^Sheet 3^List of Notes)
   Import worksheets named Table 1, Sheet 3, and List of Notes
      saving output datasets to work,
      naming output datasets based on worksheet names

%excel2sas(file=&file,exclude=Instructions^Issue Log
   Import all worksheets except Instructions and Issue Log
      saving output datasets to work,
      naming output datasets based on worksheet names

%excel2sas(file=&file,select=(^Table.*),lib=mylib)
   Import worksheets whose names begin with "Table",
      saving output datasets to mylib,

%excel2sas(file=&file,select=Table 1^Table 2^Table3,out=mytable1^mytable2^mytable3)
   Import worksheets named Table 1, Table 2, and Table 3,
      saving output datasets to work
      naming output datasets as mytable1, mytable2, and mytable3

%excel2sas(file=&file,select=Sheet1,range=C5:J50)
   Import "Sheet1" worksheet,
      range C2:J50,
      saving output datasets to work,
      naming output datasets as Sheet1

-----------------------------------------------------------------------
Notes:

The main purpose of this macro is to read all worksheets from an Excel
workbook without knowing the worksheet names.  The macro will attempt
to convert the worksheet names into SAS-compliant dataset names if
required.  The macro also allows selection or exclusion of specific
worksheet names (whose names must be known, of course).  If incorrect
worksheet names are specified, the macro will attempt to import the
remaining worksheets without generating an error.

However, dynamically determining the worksheet names is currently only
supported on Windows (via the libname EXCEL engine).

If running this macro on UNIX, there is no (current) way for SAS to
dynamically get the sheet names from the Excel workbook.  Therefore,
you must specify the desired sheet names in the macro call, and there
is no error checking as to whether the specified sheet names are correct.

Since worksheet names can contain spaces, use a caret (^) as the
delimeter between sheet names for the SHEETS= parameter.  For consistency,
the same delimiter is used for the OUT= parameter.  SAS Name Literals
(i.e. data 'Sheet A B C'n;...) are not supported by this macro.

This macro may return incorrect results if the source workbook contains
sheet names with a dollar sign ($) in the worksheet name.

Use Perl Regular Expression (PRX) syntax to search for multiple worksheets.
Enclose the PRX within parentheses to indicate that it is a PRX instead
of a worksheet name.

Examples:  
(^Table):  Worksheet names beginning with "Table"
(Notes$):  Worksheet names ending with "Notes"
(^A):      Worksheet names beginning with "A"
(^FOO$|^BAR$|^BLAH$):  Worksheet names that are exactly FOO or BAR or BLAH

By default a PRX will match any part of the worksheet name,
i.e. FOO will match FOO, FOOBAR, BARFOO, WHOOPDEFOO, etc.

Use metacharacters such as ^ (beginning of line) or $ (end of line)
to anchor the text.

See the Perl Regular Expression documentation for more details.

---------------------------------------------------------------------*/

%macro excel2sas
/*---------------------------------------------------------------------
Read an Excel workbook into a SAS dataset(s)
---------------------------------------------------------------------*/
(              /* ===== PROC IMPORT / LIBNAME EXCEL OPTIONS =====    */

 FILE=         /* Excel workbook to import (REQ).                    */
,LIB=WORK      /* Output dataset library (REQ).                      */
               /* Default is WORK.                                   */
,OUT=          /* Output dataset name(s) (Opt).                      */
               /* If blank, output dataset name is based on          */
               /* worksheet name.                                    */
               /* If the number of output dataset names equals the   */
               /* number of sheet names, there is a one-to-one       */
               /* correspondence between the sheet names and output  */
               /* dataset names.                                     */
               /* If the output dataset names does not match the     */
               /* number of sheet names, or if SHEETS is blank, then */
               /* the FIRST output dataset name is used as a prefix  */
               /* for the output dataset names.                      */
,GETNAMES=NO   /* Set column names based on first row of data in     */
               /* the imported range? (Opt).                         */
               /* Default is NO.  Valid values are YES and NO.       */
,RANGE=        /* Specific range of cells to import from the         */
               /* worksheet (Opt).                                   */
               /* If blank, entire worksheet is imported.            */
,SELECT=       /* Specific worksheets to import from workbook (Opt). */
               /* If blank, all worksheets are imported.             */
               /* Multiple worksheets must be separated with a caret */
               /* (^) since worksheet names can contain spaces.      */
               /* Wildcards can be used for worksheets, see          */
               /* usage notes.                                       */
,EXCLUDE=      /* Specific worksheets to exclude from import (Opt).  */
               /* If blank, no worksheets are excluded.              */
               /* Multiple worksheets must be separated with a caret */
               /* (^) since worksheet names can contain spaces.      */
               /* Wildcards can be used for worksheets, see          */
               /* usage notes.                                       */
,MIXED=YES     /* Specifies whether to convert numeric data values   */
               /* into character data values for a column with mixed */
               /* data types.                                        */
               /* Default is YES.  If YES, mixed data will be        */
               /* imported as text.  If NO, mixed data will be       */
               /* imported as numeric if the majority of data is     */
               /* numeric (based on TypeGuessRows registry setting). */
               /* If blank, PROC IMPORT default is used.             */
,SCANTEXT=YES  /* Scan text data for longest data length, and use    */
               /* this length for the SAS column width? (Opt).       */
               /* Default is YES.                                    */
               /* If blank, PROC IMPORT default is used.             */
,SCANTIME=YES  /* Scan columns for DATETIME data, and automatically  */
               /* determine the TIME datatime if no DATE or DATETIME */
               /* data is found? (Opt).
               /* Default is YES.                                    */
               /* If blank, PROC IMPORT default is used.             */
,USEDATE=NO    /* Use DATE. format for DATETIME. data? (Opt).        */
               /* Default is NO.                                     */
               /* If blank, PROC IMPORT default is used.             */
,TEXTSIZE=32767
               /* Specifies the field length that is allowed for     */
               /* importing Memo fields (Opt).                       */
               /* Default is 32767.                                  */
               /* If blank, PROC IMPORT default is used.             */
,DBSASLABEL=NONE
               /* Set SAS labels to data source column names? (Opt). */
               /* Valid values are COMPAT or NONE.                   */
               /* Default is NONE.                                   */
               /* If blank, PROC IMPORT default is used.             */

               /* ===== POST-PROCESSING OPTIONS =====                */

,WHERE=        /* Where clause (Opt).                                */
,IF=           /* Subsetting If clause (Opt).                        */
,FIRSTOBS=     /* First observation (Opt).                           */
,LASTOBS=      /* Last  observation (Opt).                           */
,OBS=          /* Range of observations (Opt).                       */
,KEEP=         /* Variable list to keep (Opt).                       */
,DROP=         /* Variable list to drop (Opt).                       */
,RENAME=       /* Variable list to rename (Opt).                     */
);

%local macro parmerr os engine sheets
       outdsn sheet startrow startcol endrow endcol
       word _flag
;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(FILE,         _req=1,_words=1,_case=N)
%parmv(LIB,          _req=1,_words=0,_case=U)
%parmv(GETNAMES,     _req=0,_words=0,_case=U,_val=YES NO)
%parmv(RANGE,        _req=0,_words=0,_case=U)
%parmv(SELECT,       _req=0,_words=1,_case=N)
%parmv(EXCLUDE,      _req=0,_words=1,_case=N)
%parmv(MIXED,        _req=0,_words=0,_case=U,_val=YES NO)
%parmv(SCANTEXT,     _req=0,_words=0,_case=U,_val=YES NO)
%parmv(SCANTIME,     _req=0,_words=0,_case=U,_val=YES NO)
%parmv(USEDATE,      _req=0,_words=0,_case=U,_val=YES NO)
%parmv(TEXTSIZE,     _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(DBSASLABEL,   _req=0,_words=0,_case=U,_val=NONE COMPAT)
%parmv(FIRSTOBS,     _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(LASTOBS,      _req=0,_words=0,_case=U,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

%*---------------------------------------------------------------------
Get the operating system and set the desired import engine
----------------------------------------------------------------------;
%if (%upcase(%scan(&sysscp,1)) eq WIN) %then %do;
   %let os=WIN;
   %let engine=EXCEL2007;
   %* let engine=XLSX;  %* testing ;
%end;
%else
%if (%upcase(%scan(&sysscp,1)) eq HP) %then %do;
   %let os=UNIX;
   %let engine=XLS;
%end;
%else
%if (%upcase(%scan(&sysscp,1)) eq LIN) %then %do;
   %let os=UNIX;
   %let engine=XLS;
%end;

%*---------------------------------------------------------------------
Windows processing...
----------------------------------------------------------------------;
%if (&os eq WIN) %then %do;

   %*---------------------------------------------------------------------
   If both SELECT and OUT were specified, we need to maintain the
   specified parameter order in order to maintain the one-to-one
   correspondence between the specified worksheets and the output dataset
   names. However, the dictionary tables will return the actual worksheet
   names in alphabetical order.

   If SELECT, EXCLUDE, and/or OUT were specified, save the worksheet names
   into a working dataset for later processing.
   ----------------------------------------------------------------------;
   %if (%superq(select) ne ) %then %do;
      %if (not %index(%superq(select),%str(%())) %then %do;
         data _select_;
            length sort 8 memname $32;
            do memname=%seplist(%superq(select),indlm=^,nest=QQ);
               sort+1;
               output;
            end;
         run;
      %end;
   %end;

   %if (%superq(exclude) ne ) %then %do;
      %if (not %index(%superq(exclude),%str(%())) %then %do;
         data _exclude_;
            length sort 8 memname $32;
            do memname=%seplist(%superq(exclude),indlm=^,nest=QQ);
               sort+1;
               output;
            end;
         run;
      %end;
   %end;

   %* no need to check for PRX wildcard on OUT parameter ;
   %if (%superq(out) ne ) %then %do;
      data _out_;
         length sort 8 memname $32;
         do memname=%seplist(%superq(select),indlm=^,nest=QQ);
            sort+1;
            output;
         end;
      run;
   %end;

   %*---------------------------------------------------------------------
   Use the ODBC engine to get list of worksheets in the Excel workbook
   This seems to be quicker than the libname excel engine.
   ----------------------------------------------------------------------;
   /* libname _XCEL_ odbc noprompt="dsn=Excel Files; dbq=&file"; */

   %* issue libname statement using excel engine ;
   libname _XCEL_ excel "&file" access=READONLY;

   /* libname _XCEL_ xlsx "&file" access=READONLY; */

   %*---------------------------------------------------------------------
   Get a list of all sheet names.
   Filter out any print areas, etc.
   ----------------------------------------------------------------------;
   proc sql noprint;
      * create list of all worksheets in the workbook ;
      create table _worksheets_all_ as
         select distinct
            scan(compress(memname,'''"'),1,"$") as memname length=32
         from
            dictionary.tables
         where
            upcase(libname) = "_XCEL_"
            and
            upcase(compress(memname,'''"')) like "%$%"
      ;

      * now filter the list ;
      %let _flag=0;
      create table _worksheets_ as
         select
            w.memname
         from
            _worksheets_all_ w

         %* an inner join will select those items in the _select_ table ;
         %if (%superq(select) ne ) %then %do;
            %if (not %index(%superq(select),%str(%())) %then %do;
               inner join
                  _select_ s
               on
                  upcase(w.memname)=upcase(s.memname)
            %end;
            %else %do;
               %sysfunc(ifc(&_flag=0,where,and)) prxmatch("/&select/io",strip(w.memname))
               %let _flag=1;
            %end;
         %end;

         %* use a left join and appropriate where clause to implement exclude functionality ;
         %if (%superq(exclude) ne ) %then %do;
            %if (not %index(%superq(exclude),%str(%())) %then %do;
               left join
                  _exclude_ e
               on
                  upcase(w.memname)=upcase(e.memname)
               where
                  e.memname is null
            %end;
            %else %do;
               %sysfunc(ifc(&_flag=0,where,and)) not prxmatch("/&exclude/io",strip(w.memname))
            %end;
         %end;

         %* keep the worksheets in the sorted order as specified in SELECT ;
         %if (%superq(select) ne ) %then %do;
            %if (not %index(%superq(select),%str(%())) %then %do;
               order by
                  s.sort
            %end;
         %end;
      ;

      * create the SHEETS macro variable ;
      select memname into :sheets separated by "^" from _worksheets_
      ;

      %if (&sqlobs eq 0) %then %let sheets=;
   quit;

   libname _XCEL_ clear;
%end;

%*---------------------------------------------------------------------
UNIX processing...
----------------------------------------------------------------------;
%else
%if (&os eq UNIX) %then %do;
   %* additional error checking ;
   %* On UNIX SELECT is a required parameter ;
   %parmv(SELECT,_req=1,_words=1,_case=N)

   %if (&parmerr) %then %do;
      %parmv(_msg=SELECT is a required parameter on UNIX)
      %goto quit;
   %end;

   %let sheets=&select;
%end;

%put;
%put sheets=&sheets;
%put;

%* now import all the desired worksheets via PROC IMPORT ;
%macro import;

   %*---------------------------------------------------------------------
   If an output dataset was specified, use it.
   If no output dataset was specified, translate the worksheet name into
   an acceptable output dataset name.
   ----------------------------------------------------------------------;
   %let outdsn=%qscan(%superq(out),&__iter__,^);

   %*---------------------------------------------------------------------
   If outdsn is blank, either OUT was not specified,
   or there is not a one-to-one correspondence with the SHEETS list.
   In either case, convert the sheet name to a valid SAS dataset name
   and append the LIB parameter
   ----------------------------------------------------------------------;

   %*---------------------------------------------------------------------
   WORK AROUND BUG IN PROC IMPORT on Unix, where PROC IMPORT sporadically
   creates WORK.WORK datasets, even though this does not match the OUT=
   PROC IMPORT parameter.  The workaround is to convert two-level names
   to one-level names, i.e. WORK.my_dataset to my_dataset.
   ----------------------------------------------------------------------;
   %if (&os eq UNIX) and (%upcase(&LIB) eq WORK) %then %let lib=;

   %if (&outdsn eq ) %then %do;
      %let outdsn=%sysfunc(translate(&word,%str(______),%str( ,#!-%%)));
   %end;
   %if (&lib ne ) %then %let outdsn=&lib..&outdsn;

   %* make sure output dataset name is not too long ;
   %let outdsn = %substr(%str(&outdsn                                   ),1,32);

   %let sheet=%left(%trim(&word));

   %* do not specify both SHEET= and RANGE= with PROC IMPORT ;
   %* It generates the warning "WARNING: SHEET name will be ignored if conflict occurs with RANGE name specified." ;
   %* Instead, concatenate the range onto the sheet name ;
   %if (&range ne ) and (&engine ne XLS) %then %do;
      %let sheet=&sheet$&range;
   %end;

   %* if range was specified and engine=XLS, parse to create STARTROW/COL & ENDROW/COL ;
   %* assume range was specified like A1:Z20 or A1 : Z20 ;
   %* no other error checking is done ;
   %if (&engine eq XLS) and (&range ne ) %then %do;
      %let rx=%sysfunc(prxparse(/([a-zA-Z]+)(\d+)\s*:\s*([a-zA-Z]+)(\d+)/o));
      %let rc=%sysfunc(prxmatch(&rx,&range));
      %let startcol=%sysfunc(prxposn(&rx,1,&range));
      %let startrow=%sysfunc(prxposn(&rx,2,&range));
      %let endcol  =%sysfunc(prxposn(&rx,3,&range));
      %let endrow  =%sysfunc(prxposn(&rx,4,&range));

      %syscall prxfree(rx);
   %end;

   %* if outdsn name is invalid prefix with an underscore ;
   %let rx = %sysfunc(prxparse(/[a-zA-Z_]/));
   %let rc = %sysfunc(prxmatch(&rx,%substr(&outdsn,1,1)));
   %syscall prxfree(rx);

   %if (&rc eq 0) %then %let outdsn = _&outdsn;

   proc import
      datafile="&file"
      out=&outdsn
      dbms=&engine replace;
      sheet="&sheet";
      %if (&startcol ne ) and (&engine eq XLS) %then %do;
         startcol=&startcol;
      %end;
      %if (&startrow ne ) and (&engine eq XLS) %then %do;
         startrow=&startrow;
      %end;
      %if (&endcol   ne ) and (&engine eq XLS) %then %do;
         endcol=&endcol;
      %end;
      %if (&endrow   ne ) and (&engine eq XLS) %then %do;
         endrow=&endrow;
      %end;
      %if (&getnames ne ) %then %do;
         getnames=&getnames;
      %end;
      %if (&mixed ne ) %then %do;
         mixed=&mixed;
      %end;
      %if (&scantext ne ) and (&engine ne XLS) %then %do;
         scantext=&scantext;
      %end;
      %if (&scantime ne )  and (&engine ne XLS) %then %do;
         scantime=&scantime;
      %end;
      %if (&usedate ne )  and (&engine ne XLS) %then %do;
         usedate=&usedate;
      %end;
      %if (&textsize ne ) %then %do;
         textsize=&textsize;
      %end;
      %if (&dbsaslabel ne ) %then %do;
         dbsaslabel=&dbsaslabel;
      %end;
   run;

   %* if errors, the likely cause is the user has the workbook open in Excel ;
   %if (&syserr ne 0) %then %do;
      %put;
      %put >>> Make sure &file is not already open in Excel <<<;
      %put;
   %end;

   %* were any post-processing options specified? ;
   %if (%length(%superq(where)%superq(if)&firstobs.&lastobs.&obs.%superq(keep)%superq(drop)%superq(rename)) gt 0) %then %do;  %* if any options were specified ;

      %subset_data(
         data=&syslast,
         out=&syslast,
         where=%str(&where),
         if=%str(&if),
         firstobs=&firstobs,
         lastobs=&lastobs,
         obs=%str(&obs),
         keep=%str(&keep),
         drop=%str(&drop),
         rename=%str(&rename)
      )
   %end;
%mend;

%if (%superq(sheets) ne ) %then %loop(%superq(sheets),dlm=^,mname=import);

%kill(delete=_select_ _exclude_ _out_ _worksheets_all_ _worksheets_)

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
