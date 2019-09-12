/*=====================================================================
Program Name            : export_tab.sas
Purpose                 : Wrapper macro for the %export_dlm macro
                          used to export a SAS dataset to a TDF file.
SAS Version             : SAS 9.4
Input Data              : SAS dataset
Output Data             : CSV flat file

Macros Called           : export_dlm, parmv

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

See Usage in the %export_dlm macro header.

-----------------------------------------------------------------------
Notes:

See Notes in the %export_dlm macro header.

---------------------------------------------------------------------*/

%macro export_tab
/*---------------------------------------------------------------------
Wrapper macro for the %export_dlm macro 
used to export a SAS dataset to a tab delimited file.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */
,PATH=         /* Output directory or file path (REQ).               */
               /* Either a properly quoted physical file             */
               /* (single or double quotes), or an already allocated */
               /* fileref may be specified.                          */
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

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows multiple datasets */
%parmv(PATH,         _req=1,_words=1,_case=N)
%parmv(REPLACE,      _req=0,_words=0,_case=U,_val=0 1)
%parmv(LABEL,        _req=0,_words=0,_case=U,_val=0 1)
%parmv(HEADER,       _req=0,_words=0,_case=U,_val=0 1)
%parmv(LRECL,        _req=0,_words=0,_case=U,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

%* call the %export_dlm macro with the correct parameters ;
%* all further error trapping is done by the %export_dlm macro ;
%export_dlm(
   data=%superq(data)
   ,path=%superq(path)
   ,dbms=tab
   ,replace=%superq(replace)
   ,label=%superq(label)
   ,header=%superq(header)
   ,lrecl=%superq(lrecl)
)

%quit:

%mend;

/******* END OF FILE *******/

