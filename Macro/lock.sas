%** V0004 *****************************************************************************************;
%** Program   : lock.sas                                                                         **;
%** On LAN    : No                                                                               **;
%** On Server : Yes                                                                              **;
%** Date      : 05JAN2010                                                                        **;
%** Author    : Michael Dixon                                                                    **;
%** Owner     : BCA                                                                              **;
%** Purpose   : Obtain or clear a dataset lock                                                   **;
%**                                                                                              **;
%** Notes     : Examples: lock(member=sashelp.cars)                                              **;
%**                       lock(member=sashelp.cars, action=clear)                                **;
%**                                                                                              **;
%** ---------------------------------------------------------------------------------------------**;
%** History                                                                                      **;
%**                                                                                              **;
%** Version   : V0001                                                                            **;
%** Date      : 10AUG2010                                                                        **;
%** Author    : Michael Dixon                                                                    **;
%** Reason    : Remove Data Step                                                                 **;
%**                                                                                              **;
%** Version   : V0002                                                                            **;
%** Date      : 19OCT2011                                                                        **;
%** Author    : Scott Bass                                                                       **;
%** Reason    : Added support for SPDE libraries, changed to use inner utility macros.           **;
%**                                                                                              **;
%** Version   : V0003                                                                            **;
%** Date      : 29NOV2011                                                                        **;
%** Author    : Scott Bass                                                                       **;
%** Reason    : Added call to %handle macro if lock fails.  Handle output echoed in SAS log.     **;
%**                                                                                              **;
%** Version   : V0004                                                                            **;
%** Date      : 07MAY2013                                                                        **;
%** Author    : Scott Bass                                                                       **;
%** Reason    : Added additional parameters to %handle macro invocation, changed the timing of   **;
%**             the call to the %handle macro.  Added unlock and email parameters to %lock,      **;
%**             which are passed to %handle.  Fixed logic error where &syscc was not properly    **;
%**             preserved when handle was called on a SPDE dataset.                              **;
%**                                                                                              **;
%**************************************************************************************************;

%macro lock(member=,timeout=120,retry=2,action=LOCK,onfail=STOP,unlock=YES,email=YES);
  %local macro parmerr dsname save_syscc;
  %let macro = &sysmacroname;

  %* check input parameters ;
  %parmv(MEMBER,       _req=1,_words=1,_case=N)

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
    %local starttime;
    %let starttime = %sysfunc(datetime());
    %if %UPCASE(&ACTION)=LOCK %then %do;
      lock &member;
      %if &syslckrc LE 0 %then %do;
        %return;
      %end;
      %else %do %until(%sysevalf(%sysfunc(datetime()) gt (&starttime + &timeout)));
        %let SLEPT=%sysfunc(sleep(&retry));
        %put NOTE:: Trying to lock %UPCASE(&MEMBER)...;
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
        %if %upcase(&ONFAIL)=STOP %then %do;
          %abort cancel;
        %end;
        %if %upcase(&ONFAIL)=SYSCC %then %do;
          %let SYSCC=&SYSLCKRC;
          %return;
        %end;
      %end;
    %end;
    %if %UPCASE(&ACTION)=CLEAR %then %do;
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
