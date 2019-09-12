/*=====================================================================
Program Name            : lock.sas
Purpose                 : Obtain or clear a dataset lock.
SAS Version             : SAS 9.2
Input Data              : None
Output Data             : None

Macros Called           : parmv
                          get_data_attr
                          handle

Originally Written by   : Michael Dixon
Date                    : 05JAN2010
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

Programmer              : Michael Dixon
Date                    : 10AUG2010
Change/reason           : Remove Data Step
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 19OCT2011
Change/reason           : Added support for SPDE libraries, changed to
                          use inner utility macros.
Program Version #       : 1.2

Programmer              : Scott Bass
Date                    : 29NOV2011
Change/reason           : Added call to %handle macro if lock fails.
                          Handle output echoed in SAS log.
Program Version #       : 1.3

Programmer              : Scott Bass
Date                    : 07MAY2013
Change/reason           : Added additional parameters to %handle macro
                          invocation, changed the timing of the call to
                          the %handle macro.  Added unlock and email
                          parameters to %lock, which are passed to
                          %handle.  Fixed logic error where &syscc was
                          not properly preserved when handle was called
                          on a SPDE dataset.
Program Version #       : 1.4

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%lock(member=sashelp.cars)

Obtain a lock on sashelp.cars

%lock(member=sashelp.cars, action=clear)

Clear a lock on sashelp.cars

-----------------------------------------------------------------------
Notes:

This macro was originally written by Michael Dixon.

I have modified it extensively to add support for SPDE datasets, calling
the handle.exe utility, and sending an optional email when a locked
dataset is encountered.

---------------------------------------------------------------------*/

%macro lock
/*---------------------------------------------------------------------
Obtain or clear a dataset lock.
---------------------------------------------------------------------*/
(MEMBER=       /* Dataset on which to obtain or clear a lock (REQ).  */
,TIMEOUT=120   /* Timeout period in seconds on which to abort        */
               /* attempting to obtain a lock (REQ).                 */
,RETRY=2       /* Number of seconds to sleep between attempts to     */
               /* obtain a lock (REQ).                               */
,ACTION=LOCK   /* Action to take (REQ).                              */
               /* Valid values are LOCK or CLEAR.                    */
,ONFAIL=STOP   /* Action to take when a lock cannot be obtained (REQ)*/
               /* Valid values are STOP or SYSCC.                    */
               /* If STOP, the %abort cancel statement is submitted  */
               /* to abort the calling job.                          */
               /* If SYSCC, the &syscc macro variable is set for     */
               /* further processing by the calling job.             */
,UNLOCK=YES    /* Unlock a locked dataset? (Opt).                    */
               /* This parameter is passed to the %handle macro.     */
               /* Valid values are YES or NO.                        */
               /* If YES, the %handle macro will close any open      */
               /* handles on the dataset, unlocking it so processing */
               /* can continue in the calling program.               */
,EMAIL=YES     /* Send an email if open handles are closed? (Opt.)   */
               /* This parameter is passed to the %handle macro.     */
               /* Valid values are YES or NO.                        */
               /* If YES, the %handle macro will send an email to    */
               /* interested parties informing them that a database  */
               /* was locked and who was locking it.                 */
);

%local macro parmerr dsname save_syscc;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(MEMBER,       _req=1,_words=0,_case=N)
%parmv(TIMEOUT,      _req=1,_words=0,_case=U,_val=POSITIVE)
%parmv(RETRY,        _req=1,_words=0,_case=U,_val=POSITIVE)
%parmv(ACTION,       _req=1,_words=0,_case=U,_val=LOCK CLEAR)
%parmv(ONFAIL,       _req=1,_words=0,_case=U,_val=STOP SYSCC)
%parmv(UNLOCK,       _req=0,_words=0,_case=U,_val=YES NO)
%parmv(EMAIL,        _req=0,_words=0,_case=U,_val=YES NO)

%* parse off any dataset options ;
%let dsname=%scan(%superq(member),1,%str(%());

%* additional error checking ;
%* does the dataset exist? ;
%if (^%sysfunc(exist(&dsname,data)) and ^%sysfunc(exist(&dsname,view))) %then %do;
   %parmv(_msg=&dsname does not exist)
   %goto quit;
%end;

%if (&parmerr) %then %goto quit;

%global handle_rc;
%let handle_rc=0;

%* create inner utility macros ;
%macro lock_base(member=,timeout=,retry=,action=,onFail=,unlock=,email=);
   %let action=%upcase(&action);
   %let onfail=%upcase(&onfail);

   %local starttime;
   %let starttime = %sysfunc(datetime());
   %if (&action eq LOCK) %then %do;
      lock &member;
      %if &syslckrc LE 0 %then %do;
         %return;
      %end;
      %else
      %do %until(%sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout)));
         %let SLEPT=%sysfunc(sleep(&retry));
         %put NOTE:: Trying to lock %upcase(&member)...;
         lock &member;
         %if &syslckrc LE 0 %then %do;
            %return;
         %end;
      %end;
      %* At this point, we have timed out ;
      %* Use the %handle macro to list and then close file locks, ;
      %* and try one last time to lock the member ;
      %handle(data=&member,unlock=&unlock,email=&email)
      lock &member;
      %if &syslckrc LE 0 %then %do;
         %return;
      %end;
      %else %do;
         %put WARNING:: Timed out waiting for update access to %upcase(&member)...;
         %if (&onfail eq STOP) %then %do;
            %abort cancel;
         %end;
         %else
         %if (&onfail eq SYSCC) %then %do;
            %let syscc=&SYSLCKRC;
            %return;
         %end;
      %end;
   %end;
   %else
   %if (&action eq CLEAR) %then %do;
      lock &member query;
      %if &SYSLCKRC = %sysrc(_SWLKYOU) %then %do;
         lock &member clear;
      %end;
   %end;
%mend;

%* Version 1 of SPDE locking macro ;
%macro lock_spde(member=,timeout=,retry=,action=,onFail=,unlock=,email=);
   %let action=%upcase(&action);
   %let onfail=%upcase(&onfail);

   %if (&action eq LOCK) %then %do;
      %local starttime locked timedout notes source mprint slept;
      %let starttime = %sysfunc(datetime());
      %let locked    = 1;
      %let timedout  = %sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout));
      %let notes     = %sysfunc(getoption(notes));
      %let source    = %sysfunc(getoption(source));
      %let mprint    = %sysfunc(getoption(mprint));

      %* do not combine these two options statements ;
      options nomprint;
      options nosource;
      %do %while (&locked and not &timedout);
         options nonotes;
         data &member;
            modify &member;
            call symputx("locked",0);
            stop;
         run;
         options notes;
         %if (&locked) %then %do;
            %put NOTE:: Waiting for update access to %upcase(&member)...;
            %let slept=%sysfunc(sleep(&retry));
         %end;
         %let timedout = %sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout));
      %end;
      options &notes;
      options &source;
      options &mprint;
      %if (&timedout) %then %do;
         %* At this point, we have timed out ;
         %* Use the %handle macro to list and close file locks, ;
         %* and try one last time to lock the member ;
         %handle(data=&member,unlock=&unlock,email=&email)
         options nomprint;
         options nosource;
         options nonotes;
         data &member;
            modify &member;
            call symputx("locked",0);
            stop;
         run;
         options &notes;
         options &source;
         options &mprint;
         %if (not &locked) %then %do;
            %put NOTE:: Update access is available for %upcase(&member)...;
            %return;
         %end;
         %else %do;
            %put WARNING:: Timed out waiting for update access to %upcase(&member)...;
            %if (%upcase(&onFail) eq STOP) %then %do;
               %abort cancel;
            %end;
            %else
            %if (%upcase(&onFail) eq SYSCC) %then %do;
               %* Since we do not have &SYSLCKRC, make up a generated return code meaning "timeout" ;
               %* 70031 seems to be the value of &SYSLCKRC when the lock statement fails on a base dataset ;
               %* so use it to be consistent with the base locking macro ;
               %let syscc=70031;
            %end;
         %end;
      %end;
      %else %do;
         %put NOTE:: Update access is available for %upcase(&member)...;
      %end;
   %end;
   %else
   %if (&action eq CLEAR) %then %do;
      %* dummy action ;
   %end;
%mend;

%* Version 2 of SPDE locking macro ;
/*
%macro lock_spde_v2(member=,timeout=,retry=,action=,onFail=,unlock=,email=);
   %let action=%upcase(&action);
   %let onfail=%upcase(&onfail);

   %if (&action eq LOCK) %then %do;
      %local dsid locked starttime timedout slept;
      %let dsid       = %sysfunc(open(&member));
      %let locked     = %eval(&dsid le 0);
      %let starttime  = %sysfunc(datetime());
      %let timedout   = %sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout));
      %do %while (&locked and not &timedout);
         %put NOTE:: Waiting for update access to %upcase(&member)...;
         %let slept    = %sysfunc(sleep(&retry,1));
         %let dsid     = %sysfunc(open(&member));
         %let locked   = %eval(&dsid le 0);
         %let timedout = %sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout));
      %end;
      %do dsid=&dsid %to 0 %by -1;
         %let rc = %sysfunc(close(&dsid));
      %end;
      %if (&timedout) %then %do;
         %* At this point, we have timed out ;
         %* Use the %handle macro to list and then close file locks, ;
         %* and try one last time to lock the member ;
         %handle(data=&member,unlock=&unlock,email=&email);
         %let dsid     = %sysfunc(open(&member));
         %let locked   = %eval(&dsid le 0);
         %let rc = %sysfunc(close(&dsid));
         %if (not &locked) %then %do;
            %put NOTE:: Update access is available for %upcase(&member)...;
            %return;
         %end;
         %put WARNING:: Timed out waiting for update access to %upcase(&member)...;
         %if (%upcase(&onFail) eq STOP) %then %do;
            %abort cancel;
         %end;
         %else
         %if (%upcase(&onFail) eq SYSCC) %then %do;
            %* Since we do not have &SYSLCKRC, make up a generated return code meaning "timeout" ;
            %* 70031 seems to be the value of &SYSLCKRC when the lock statement fails on a base dataset ;
            %* so use it to be consistent with the base locking macro ;
            %let syscc=70031;
         %end;
      %end;
      %else %do;
         %put NOTE:: Update access is available for %upcase(&member)...;
      %end;
   %end;
   %else
   %if (&action eq CLEAR) %then %do;
      %* dummy action ;
   %end;
%mend;
*/

%* Now check the engine type of the source dataset and call the correct utility macro ;
%let engine=%get_data_attr(&member,engine);

%* Save the current system error code up to this point ;
%let save_syscc=&syscc;

%if (&engine eq SPDE) %then %do;
   %* use the V1 version of the SPDE locking macro ;
   %lock_spde(member=&dsname,timeout=&timeout,retry=&retry,action=&action,onFail=&onFail,unlock=&unlock,email=&email)
%end;
%else %do;
   %* assume other engines (BASE, V6, V7, V9, etc) are base and support the lock statement ;
   %lock_base(member=&dsname,timeout=&timeout,retry=&retry,action=&action,onFail=&onFail,unlock=&unlock,email=&email)
%end;

%* If the %handle macro was called with unlock=yes, ;
%* and if the file handles were closed, ;
%* then reset the system error code to its previous value ;
%if (&handle_rc eq 0) %then %let syscc=&save_syscc;

%quit:
%mend;

/******* END OF FILE *******/