/*=====================================================================
Program Name            : get_lib_attr.sas
Purpose                 : Function style macro to return a library
                          attribute.
SAS Version             : SAS 9.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 20OCT2011
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

* allocate some sample libraries ;
libname v6    v6      "C:\";
libname v7    v7      "C:\";
libname v9    v9      "C:\";
libname spde  spde    "C:\";
libname excel excel   "C:\Temp\temp.xls";  * this file must exist ;

%put %get_lib_attr(v6,engine);
%put %get_lib_attr(v7,engine);
%put %get_lib_attr(v9,engine);
%put %get_lib_attr(work,engine);
%put %get_lib_attr(sashelp,engine);
%put %get_lib_attr(spde,engine);
%put %get_lib_attr(excel,engine);

* various other attributes ;
%put %get_lib_attr(v6,libname);   * a bit redundant since we supplied a libname! ;
%put %get_lib_attr(sashelp,path); * note it only reports the first level ;
%put %get_lib_attr(spde,fileformat);
%put %get_lib_attr(excel,readonly);
%put %get_lib_attr(spde,sequential);
%put %get_lib_attr(excel,sysdesc);
%put %get_lib_attr(v7,sysname);
%put %get_lib_attr(v9,sysvalue);
%put %get_lib_attr(sashelp,temp);
%put %get_lib_attr(work,temp);

* examples of returning all values of a multi-level library allocation ;
%put %get_lib_attr(sashelp,path,levels=0);

%macro parse_output;
  %put %get_lib_attr(spde,sysname,levels=0);
  %put %get_lib_attr(spde,sysvalue,levels=0);
  %let _sysname=%get_lib_attr(spde,sysname,levels=0);
  %let _sysvalue=%get_lib_attr(spde,sysvalue,levels=0);
  %put sysname=&_sysname;
  %put sysvalue=&_sysvalue;
  %do i=1 %to 4;
    %put %scan(&_sysname,&i,^)=%scan(&_sysvalue,&i,^);
  %end;
%mend;
%parse_output;

* and some error checking ;
%put >>> %get_lib_attr(doesnotexist,engine);  * no error thrown, just returns blank ;

-----------------------------------------------------------------------
Notes:

This macro would mainly be used to return the engine type of an existing
library allocation, but I have allowed all columns present in
sashelp.vlibnam to be passed in as parameters.

Some of these parameters are redundant, eg. path (better retrieved via
the pathname function).

By default, this macro only returns the first record fetched for the
specified libname.  However, if LEVELS=0 is specified, all items in a
multi-level library allocation are returned in a delimited list. This
list would usually be further processed by the calling program.

For a SPDE library, the first sysvalue parameter returns the free space
remaining on the drive.  An esoteric but perhaps handy little feature of
the SPDE engine.

---------------------------------------------------------------------*/

%macro get_lib_attr
/*---------------------------------------------------------------------
Function style macro to return a library attribute.
---------------------------------------------------------------------*/
(LIBNAME       /* Input libname (REQ).  Must already be allocated.   */
,ATTR          /* Desired library attribute (REQ).                   */
               /* See code for valid attributes.                     */
,LEVELS=1      /* Desired levels of a multi-level library allocation */
               /* (REQ).                                             */
               /* Usual value would be 1, and is the default value.  */
               /* Specify LEVELS=0 to return all levels of the       */
               /* specified attributes in a delimited list.          */
,DLM=^         /* Delimiter for multi-level library output (REQ).    */
);

%local macro parmerr &attr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(LIBNAME,      _req=1,_words=0,_case=U)
%parmv(LEVELS,       _req=1,_words=0,_case=U,_val=NONNEGATIVE)
%parmv(DLM,          _req=1,_words=0,_case=U)
%parmv(ATTR,         _req=1,_words=0,_case=U,_val=

/* Library attributes present in sashelp.vlibnam */
LIBNAME
ENGINE
PATH
LEVEL
FILEFORMAT
READONLY
SEQUENTIAL
SYSDESC
SYSNAME
SYSVALUE
TEMP
)

%if (&parmerr) %then %goto quit;

%* open sashelp.vlibnam ;
%let dsid=%sysfunc(open(sashelp.vlibnam (where=(libname="%upcase(&libname)"))));

%* was the open successful? ;
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open sashelp.vlibnam)
   %goto quit;
%end;

%* automatically set macro variables when a record is fetched ;
%syscall set(dsid);

%* if levels=0 then return all items in a delimited list ;
%* else just return the specified record (usually 1) ;
%if (&levels eq 0) %then %do;
  %do %while (%sysfunc(fetch(&dsid)) eq 0);
  %* do not indent the below line ;
%trim(%left(&&&attr)) &dlm
  %end;
%end;
%else %do;
  %let rc=%sysfunc(fetchobs(&dsid,&levels));
  %* do not indent the below line ;
%trim(%left(&&&attr))
%end;
%let dsid=%sysfunc(close(&dsid));

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
