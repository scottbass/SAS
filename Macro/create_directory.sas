/*=====================================================================
Program Name            : create_directory.sas
Purpose                 : Creates a directory using the dlcreatedir 
                          option, without requiring the ALLOWXCMD 
                          option to be active.
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : %parmv
                          %loop
                          %seplist

Originally Written by   : Scott Bass
Date                    : 11APR2017
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

* This must be a path from the perspective of the APPLICATION SERVER,
  not the local machine.  UNC paths are usually safest, and they must
  be accessible from and writeable by the application server ;
%let root=\\server\UNC\Path;

options nodlcreatedir;  * make sure it works even if the option is initially off ;

%create_directory(&root,dir1/Dir2/DIR3)
%create_directory(&root,dirA\DirB\DIRC)

%put %sysfunc(getoption(dlcreatedir));  * make sure option is restored by the macro ;

Create the directory path dir1/Dir2/DIR3 and dirA\DirB/DIRC.

Both invocations will work under both Windows and *nix.

-----------------------------------------------------------------------
Notes:

This macro uses the dlcreatedir option available in SAS 9.3+ to create
the directory, or to silently succeed if the directory already exists.

Therefore, this macro does not require the ALLOWXCMD option to be 
active, nor does it require any exit to the operating system
(X command, call systask, PIPE, etc)

However, the SAS Administrator can disable this functionality.
The below code will indicate whether the dlcreatedir functionality is
restricted or not:

* Lists which options you can restrict ;
proc options listrestrict;
run;

* Lists which options are restricted ;
proc options restrict;
run;

---------------------------------------------------------------------*/

%macro create_directory
/*---------------------------------------------------------------------
Creates a directory using the dlcreatedir option, without requiring the 
ALLOWXCMD option to be active. 
---------------------------------------------------------------------*/
(ROOT          /* Root directory, under which the additional         */
               /* directory(ies) are created (REQ).                  */
,PATH          /* Directory path to create under the ROOT directory  */
               /* (REQ).                                             */
,DLM=%str(/\)  /* Directory path delimiter(s) (REQ).                 */
               /* Default is /\, so either the Windows or *nix       */
               /* path delimiter will be used to delimit the         */
               /* directories in the specified path.                 */ 
,LIBREF=dummy  /* Dummy libref to use (REQ).  Default is dummy.      */ 
);

%local macro parmerr _data_;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(ROOT,         _req=1,_words=1,_case=N)  /* words allows directories containing spaces */
%parmv(PATH,         _req=1,_words=1,_case=N)
%parmv(DLM,          _req=1,_words=0,_case=N,_val=/\)  /* assume only delimiters allowed are / and \ */

%if (&parmerr) %then %goto quit;

%* This inner utility macro is used by the %loop macro to create a concatenated library path ;
%* Note: &concat must be global ;
%macro create_directory_concat;
%global concat;
%if (&__iter__ eq 1) %then 
   %let concat=&root/&word;
%else
   %let concat=&concat/&word;
&concat|
%mend;

%* Capture the current dlcreatedir option ;
%let dlcreatedir=%sysfunc(getoption(dlcreatedir));
options dlcreatedir;

%* The %loop macro will create a delimited (|) path from the users PATH parameter ;
%* The %seplist macro will parse that path to create the correct syntax for a SAS concatenated library ;
libname &libref (%seplist(%loop(&path,dlm=&dlm,mname=create_directory_concat),indlm=|,nest=qq));
libname &libref clear;

options &dlcreatedir;
%symdel concat / nowarn;

%quit:

%mend;

/******* END OF FILE *******/
