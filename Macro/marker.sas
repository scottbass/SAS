/*=====================================================================
Program Name            : marker.sas
Purpose                 : Process marker files used to control job
                          scheduling
SAS Version             : SAS 9.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 11NOV2011
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

%marker(path=C:\Temp\Stage1.mkr,action=create);
%put rc=&rc;

Create empty marker file C:\Temp\Stage1.mkr

=======================================================================

%marker(path=C:\Temp\Stage1.mkr,action=check,sleep=10,timeout=30);
%put rc=&rc;

Checks for marker file C:\Temp\Stage1.mkr
  Sleeping for 10 seconds before checking again
  Timing out after 30 seconds

Sets the macro variable &rc to 0 if the marker file is created
within the timeout period, otherwise &rc is set to 1.

=======================================================================

%macro executeCode;
   %marker(path=C:\Temp\Stage1.mkr,action=check,_rc=marker_rc);
   %if (&marker_rc eq 0) %then %do;
      %* processing if marker file exists ;
      %put MARKER FILE EXISTS;
   %end;
   %else %do;
      %* processing if marker file does not exist within the timeout period ;
      %put MARKER FILE DOES NOT EXIST;
   %end;
%mend;
%executeCode;

Same as above
   Within the context of a macro
   Using the default values for sleep and timeout periods
   Creating the &marker_rc status macro variable

=======================================================================

%marker(path=C:\Temp\*.mkr,action=delete,_rc=delete_rc);
%put delete_rc=&delete_rc;

Delete all marker files named *.mkr in directory C:\Temp

=======================================================================

%marker(path=C:\Temp\Stage1.mkr,action=check,check=notexists);
%put rc=&rc;

Checks that the marker file C:\Temp\Stage1.mkr does NOT exist
   Using the default values for sleep and timeout periods
   Returning success if the file is deleted within the timeout period

Sets the macro variable &rc to 0 if the marker file does not exist
within the timeout period, otherwise &rc is set to 1.

-----------------------------------------------------------------------
Notes:

Marker files are empty files used by scheduling software as a condition
for executing downstream job(s).

The condition can be either the existence or non-existence of the file,
depending on the upstream job processing.

It is the *existence* (or non-existence) of the file, not the contents
of the file itself, that serves as the trigger for the scheduling
software.

---------------------------------------------------------------------*/

%macro marker
/*---------------------------------------------------------------------
Process marker files used to control job scheduling.
---------------------------------------------------------------------*/
(PATH=         /* Full path to marker file (REQ).                    */
,ACTION=       /* Action to take (REQ).                              */
               /* Valid values are CHECK, CREATE, and DELETE.        */
,CHECK=EXISTS  /* Specifies whether to check for the existence or    */
               /* non-existence of the marker file (REQ).            */
               /* This parameter is ignored unless ACTION=CHECK.     */
               /* Valid values are EXISTS and NOTEXISTS.             */
,SLEEP=300     /* Period in seconds to sleep while checking for the  */
               /* existence or non-existence of the marker file (REQ)*/
               /* Default value is 5 minutes (300 seconds).          */
               /* Specify 0 to immediately fail if the check for the */
               /* marker file fails.                                 */
               /* This parameter is ignored unless ACTION=CHECK.     */
,TIMEOUT=3600  /* Period in seconds to wait for the marker file      */
               /* check to succeed before timing out (REQ).          */
               /* This parameter is ignored unless ACTION=CHECK.     */
,_RC=RC        /* Macro variable which contains the return code (REQ)*/
               /* Returned as a global macro variable.               */
               /* Default value is &rc.                              */
);

%local macro parmerr marker check now end temp;
%global &_rc;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(PATH,         _req=1,_words=1)  /* path could contain spaces */
%parmv(ACTION,       _req=1,_words=0,_case=U,_val=CHECK CREATE DELETE)
%parmv(CHECK,        _req=1,_words=0,_case=U,_val=EXISTS NOTEXISTS)
%parmv(SLEEP,        _req=1,_words=0,_case=U,_val=NONNEGATIVE)
%parmv(TIMEOUT,      _req=1,_words=0,_case=U,_val=NONNEGATIVE)
%parmv(_RC,          _req=1,_words=0,_case=U)

%if (&parmerr) %then %goto quit;

%if (&action eq CHECK) %then %do;
   %let now=%sysfunc(datetime());
   %let end=%sysevalf(&now + &timeout);
   %let marker=0;
   %if (&check eq EXISTS) %then
      %let check=1;
   %else
   %if (&check eq NOTEXISTS) %then
      %let check=0;

   %do %until (%sysevalf(&now ge &end));
      %let marker=%sysfunc(fileexist(&path));
      %if (&marker eq &check) %then %goto marker;
      %put %sysfunc(putn(&now,datetime.)): Sleeping for &sleep seconds...;
      %let temp=%sysfunc(sleep(&sleep,1));
      %let now=%sysfunc(datetime());
   %end;

%marker:
   %let &_rc=%eval(&marker ne &check);  %* returns 0 if success, 1 if timeout ;
%end;

%else
%if (&action eq CREATE) %then %do;
   systask command "type NUL > ""&path"" " wait status=&_rc taskname="Create Marker File";
%end;

%else
%if (&action eq DELETE) %then %do;
   systask command "del ""&path"" " wait status=&_rc taskname="Delete Marker File";
%end;

%quit:

%mend;

/******* END OF FILE *******/
