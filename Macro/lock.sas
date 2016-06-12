/*====================================================================
Program Name            : lock.sas
Purpose                 : Obtain or clear a dataset lock
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Michael Dixon
Date                    : 05JAN2010
Program Version #       : 1.0

======================================================================

Modification History    :

Programmer              : Michael Dixon
Date                    : 10AUG2010
Change/reason           : Remove Data Step
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 19OCT2011
Change/reason           : Added support for SPDE libraries, 
                          changed to use inner utility macros.
Program Version #       : 1.2

Programmer              : Scott Bass
Date                    : 29NOV2011
Change/reason           : Added call to %handle macro if lock fails.  
                          Handle output echoed in SAS log.
Program Version #       : 1.3

Programmer              : Scott Bass
Date                    : 07MAY2013
Change/reason           : Added additional parameters to %handle 
                          macro invocation, changed the timing of
                          the call to the %handle macro.  
                          Added unlock and email parameters to %lock,
                          which are passed to %handle.  
                          Fixed logic error where &syscc was not properly
                          preserved when handle was called on a SPDE dataset.
Program Version #       : 1.4

+===================================================================*/

/*--------------------------------------------------------------------
Usage:

%lock(member=sashelp.cars)

Create lock on sashelp.cars

======================================================================

%lock(member=sashelp.cars, action=clear)

Clear lock on sashelp.cars

----------------------------------------------------------------------
Notes:

--------------------------------------------------------------------*/

%macro lock
/*--------------------------------------------------------------------
Obtain or clear a dataset lock
--------------------------------------------------------------------*/
(MEMBER=       /* Dataset to lock or unlock (REQ).                  */
,TIMEOUT=120   /* Number of minutes to wait for the lock before     */
               /* taking the ONFAIL action (REQ).                   */
,RETRY=2       /* Number of minutes to wait between retries to      */
               /* obtain the lock (REQ).                            */
,ACTION=LOCK   /* Action to take (REQ).                             */
               /* Valid values are LOCK (obtain a lock) and         */ 
               /* CLEAR (clear a previous lock).                    */
               /* Default value is LOCK.                            */
,ONFAIL=STOP   /* Action to take when a lock cannot be obtained     */
               /* within the specified timeout period (REQ).        */
               /* Valid values are STOP (abort) or                  */
               /* SYSCC (set the SYSCC return code to non-zero).    */
               /* Default value is STOP (abort the job).            */ 
,UNLOCK=YES    /* Use the handle.exe program to forcibly close any  */
               /* open handles on the dataset in order to obtain    */
               /* the lock? (REQ).                                  */
               /* Default value is YES.  Valid values are:          */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
,EMAIL=YES     /* Send email to the end user (or other parties)     */
               /* when the handle.exe utility was used to close     */
               /* open handles? (REQ).
               /* Default value is YES.  Valid values are:          */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);


%local macro parmerr dsname save_syscc;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(MEMBER,       _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(TIMEOUT,      _req=1,_words=0,_case=N,_value=POSITIVE)  
%parmv(RETRY,        _req=1,_words=1,_case=N,_value=POSITIVE)  
%parmv(ACTION,       _req=1,_words=1,_case=U,_value=LOCK CLEAR)  
%parmv(ONFAIL,       _req=1,_words=1,_case=U,_value=STOP SYSCC)  
%parmv(UNLOCK,       _req=1,_words=1,_case=U,_value=0 1)  
%parmv(EMAIL,        _req=1,_words=1,_case=N,_value=0 1)  

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* does the dataset exist? ;
%* parse off any dataset options ;
%let dsname=%scan(%superq(member),1,%str(%());

%if (^%sysfunc(exist(&dsname,data)) and ^%sysfunc(exist(&dsname,view))) %then %do;
   %parmv(_msg=&dsname does not exist)
%end;

%if (&parmerr) %then %goto quit;

%global handle_rc;
%let handle_rc=0;

%* create inner utility macros ;
%macro lock_base(member=,timeout=,retry=,action=,onFail=,unlock=,email=);
   %local starttime;
   %let starttime = %sysfunc(datetime());
   %if (%upcase(&ACTION) eq LOCK) %then %do;
      lock &member;
      %if (&syslckrc le 0) %then %do;
         %return;
      %end;
      %else 
      %do %until (%sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout)));
         %let SLEPT=%sysfunc(sleep(&retry));
         %put NOTE:: Trying to lock %UPCASE(&MEMBER)...;
         lock &member;
         %if (&syslckrc le 0) %then %do;
            %return;
         %end;
      %end;

      %* At this point, we have timed out ;
      %* Use the %handle macro to list and then close file locks, ;
      %* and try one last time to lock the member ;
      %handle(data=&member,unlock=&unlock,email=&email)
      lock &member;
      %if (&syslckrc le 0) %then %do;
         %return;
      %end;
      %else %do;
         %put WARNING:: Timed out waiting for update access to %upcase(&member)...;
         %if (%upcase(&ONFAIL) eq STOP) %then %do;
            %abort cancel;
         %end;
         %else
         %if (%upcase(&ONFAIL) eq SYSCC) %then %do;
            %let SYSCC=&SYSLCKRC;
            %return;
         %end;
      %end;
   %end;
   %else
   %if (%upcase(&ACTION) eq CLEAR) %then %do;
      lock &member query;
      %if (&SYSLCKRC eq %sysrc(_SWLKYOU)) %then %do;
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
