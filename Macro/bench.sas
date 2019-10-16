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
Date                    : 09JUL2015
Change/reason           : Added DATA, MESSAGE, and PRINT parameters
                          to capture running metrics.
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* Start benchmarking.
* Both invocations are identical as long as start ;
* has not been previously invoked ;
%bench;
%bench(start);

%let rc=%sysfunc(sleep(3));

* Get elapsed time, should be approx. 3 seconds elapsed, 3 seconds total ;
%bench(elapsed);

%let rc=%sysfunc(sleep(7));

* Get another elapsed time, should be approx. 7 seconds elapsed, 10 seconds total ;
%bench;  * elapsed parm not required since start was already called ;

%let rc=%sysfunc(sleep(2));

* End benchmarking, should be approx. 2 seconds elapsed, 12 seconds total ;
* Must be called after start.  Resets benchmarking. ;
%bench(end);

* Capture running metrics ;
%bench(start,data=metrics);  * this will delete work.metrics if it exists ;
%let rc=%sysfunc(sleep(3));
%bench(elapsed,data=metrics,message=Option 1); * add current metrics to work.metrics ;
%let rc=%sysfunc(sleep(5));
%bench(elapsed,data=metrics,message=Option 2xxx);
%let rc=%sysfunc(sleep(11));
%bench(elapsed,data=metrics,message=Option 3yyyyy);
%bench(end,data=metrics,print=Y);  * prints default metrics output to log ;

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

If you don't like the default metrics output, specify
%bench(end); or %bench(end,print=N);, then write your own output
using the metrics dataset that was created.

There may be very slight differences between the output written to the
log and the output captured in the metrics dataset.  This is likely
due to precision differences between the %sysevalf macro function and
the data step.

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
,DATA=         /* Output dataset for running metrics (Opt).          */
               /* If specified, the &_START and &_ELAPSED data are   */
               /* written out to the specified dataset.              */
,MESSAGE=      /* Message to include with running metrics (Opt).     */
               /* If specified, the message is included with the     */
               /* running metrics.  This parameter is ignored if     */
               /* DATA= is not specified.                            */
,PRINT=N       /* Print default metrics to log? (Opt).               */
,DELETE=Y      /* Delete output dataset for running metrics? (Opt)   */
);

%local macro parmerr time_elapsed time_total time_elapsed_str time_total_str h m s;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(PARM,         _req=0,_words=0,_case=U,_val=START ELAPSED END)
%parmv(DATA,         _req=0,_words=0,_case=N)
%parmv(MESSAGE,      _req=0,_words=1,_case=N)
%parmv(PRINT,        _req=0,_words=0,_case=U,_val=0 1)
%parmv(DELETE,       _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %return;

%* if print=Y then data must be specified ;
%if (&print and &data eq ) %then %do;
   %parmv(_msg=If PRINT=Y then DATA must be specified)
   %return;
%end;

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
   %put Elapsed time: &time_elapsed_str &time_elapsed;
   %put Total   time: &time_total_str &time_total;
   %put;
%mend;

%* declare global variables ;
%global _start _elapsed;

%if (&parm eq START) %then %do;
   %let _start    = %sysfunc(datetime());
   %let _elapsed  = &_start;

   %* If DATA= was specified then delete existing dataset ;
   %if (&delete and &data ne ) %then %do;
      %if (%sysfunc(exist(&data))) %then %do;
         proc delete data=&data;
         run;
      %end;
   %end;
%end;
%else
%if (&parm eq ELAPSED) %then %do;
   %if (&_start eq ) %then %do;
      %put ERROR:  Benchmarking must be started before elapsed time can be printed.;
      %return;
   %end;
   %else %do;
      %print(ELAPSED);
      %let _elapsed  = %sysfunc(datetime());

      %* If DATA= was specified capture running metrics ;
      %if (&data ne ) %then %do;
         %if (%sysfunc(exist(&data))) %then %do;
            data &data;
               set &data end=eof;
               output;
               if eof then do;
                  %* do not reorder these lines ;
                  message="&message";
                  start=&_start;
                  elapsed=&_elapsed-current;
                  current=&_elapsed;
                  total=total+elapsed;
                  output;
               end;
            run;
         %end;
         %else %do;
            data &data;
               length  message $200 start current elapsed total 8;
               message="&message";
               start=&_start;
               current=&_elapsed;
               elapsed=current-start;
               total=elapsed;
               format start current datetime.;
            run;
         %end;
      %end;
   %end;
%end;
%else
%if (&parm eq END) %then %do;
   %if (&_start eq ) %then %do;
      %put ERROR:  Benchmarking must be started before elapsed time can be printed.;
      %return;
   %end;
   %else %do;
      %print(END)

      %* reset benchmarking ;
      %symdel _start _elapsed / nowarn;

      %* if PRINT=Y then print default metrics to log ;
      %if (&print) %then %do;
         %let ls=%sysfunc(getoption(ls));
         options ls=max;
         data _null_;
            set &data end=eof;
            retain maxlen;
            maxlen=max(length(strip(message)),maxlen);
            if eof then call symputx("maxlen",maxlen,"L");
         run;
         data _null_;
            set &data end=eof;
            file log;
            if _n_=1 then
            put
               @1 "Benchmark Metrics:"
               /
               @1 "=================="
            ;
            put
               @1 message $&maxlen..
               +2 "Elapsed:" elapsed 12.4-R
               +2 "Total:"   total   12.4-R
            ;
            if eof then put "0A0D"x @;
         run;
         options ls=&ls;
      %end;
   %end;
%end;
%else
%if (&parm eq ) %then %do;
   %* derive proper parm then recursively call this macro ;
   %if (&_start eq ) %then %do;
      %bench(start);
   %end;
   %else %do;
      %bench(elapsed);
   %end;
%end;

%mend;

/******* END OF FILE *******/
