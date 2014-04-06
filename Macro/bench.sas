/*=====================================================================
Program Name            : bench.sas
Purpose                 : Measures elapsed time between successive
                          invocations.
SAS Version             : SAS 8.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 24APR2006
Program Version #       : 1.0

=======================================================================

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* Start benchmarking.
* Both invocations are identical as long as start ;
* has not been previously invoked ;
%bench;
%bench(start);

data _null_;
   rc=sleep(3);
run;

* Get elapsed time, should be approx. 3 seconds elapsed, 3 seconds total ;
%bench(elapsed);

data _null_;
   rc=sleep(7);
run;

* Get another elapsed time, should be approx. 7 seconds elapsed, 10 seconds total ;
%bench;  * elapsed parm not required since start was already called ;

data _null_;
   rc=sleep(2);
run;

* End benchmarking, should be approx. 2 seconds elapsed, 12 seconds total ;
* Must be called after start.  Resets benchmarking. ;
%bench(end);

-----------------------------------------------------------------------
Notes:

If %bench has never been invoked, calling %bench without parameters
starts benchmarking.  You may also explicity specify the start
parameter.  Explicitly specifying the start parameter resets
benchmarking, although normally the end parameter would be used.

If %bench has been previously invoked with the start parameter, calling
%bench without parameters prints the elapsed time.  You may also
explicity specify the elapsed parameter.

To end benchmarking and reset the start time, specify the end
parameter.

Only the elapsed or end parameters (or equivalent processing) print
time measurements to the log.  The start parameter does not print
anything to the log.

The only parameter that needs to be explicitly specified is end.
Otherwise the macro should do the right thing, either starting
benchmarking or printing elapsed times.

Benchmarking a time period greater than 24 hours is "unpredictable".

---------------------------------------------------------------------*/

%macro bench
/*---------------------------------------------------------------------
Measures elapsed time between successive invocations.
---------------------------------------------------------------------*/
(PARM          /* Benchmarking parameter (Opt).                      */
               /* If not specified:                                  */
               /*    If first invocation, start benchmarking.        */
               /*    If subsequent invocation, print elapsed time.   */
               /* Valid values are START ELAPSED END.                */
);

%local macro parmerr time_elapsed time_total time_elapsed_str time_total_str h m s;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(PARM,         _req=0,_words=0,_case=U,_val=START ELAPSED END)

%if (&parmerr) %then %goto quit;

%* nested macro for printing ;
%macro print(_parm);
   %let time_elapsed       = %sysevalf(%sysfunc(datetime()) - &_elapsed);
   %let time_total         = %sysevalf(%sysfunc(datetime()) - &_start);

   %let h                  = %sysfunc(hour(&time_elapsed),z2.);
   %let m                  = %sysfunc(minute(&time_elapsed),z2.);
   %let s                  = %sysfunc(second(&time_elapsed),z2.);
   %let time_elapsed_str   = &h hours, &m minutes, &s seconds;

   %let h                  = %sysfunc(hour(&time_total),z2.);
   %let m                  = %sysfunc(minute(&time_total),z2.);
   %let s                  = %sysfunc(second(&time_total),z2.);
   %let time_total_str     = &h hours, &m minutes, &s seconds;

   %put;
   %put Benchmark &_parm:;
   %put;
   %put Elapsed seconds = &time_elapsed_str &time_elapsed;
   %put Total   seconds = &time_total_str &time_total;
   %put;
%mend;

%* declare global variables ;
%global _start _elapsed;

%if (&parm eq START) %then %do;
   %let _start    = %sysfunc(datetime());
   %let _elapsed  = &_start;
%end;
%else
%if (&parm eq ELAPSED) %then %do;
   %if (&_start eq ) %then %do;
      %put ERROR:  Benchmarking must be started before elapsed time can be printed.;
      %goto quit;
   %end;
   %else %do;
      %print(ELAPSED)
      %let _elapsed  = %sysfunc(datetime());
   %end;
%end;
%else
%if (&parm eq END) %then %do;
   %if (&_start eq ) %then %do;
      %put ERROR:  Benchmarking must be started before elapsed time can be printed.;
      %goto quit;
   %end;
   %else %do;
      %print(END)

      %* reset benchmarking ;
      %symdel _start _elapsed / nowarn;
   %end;
%end;
%else
%if (&parm eq ) %then %do;
   %* derive proper parm then recursively call this macro ;
   %if (&_start eq ) %then %do;
      %bench(start)
   %end;
   %else %do;
      %bench(elapsed)
   %end;
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
