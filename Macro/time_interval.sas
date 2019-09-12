/*=====================================================================
Program Name            : time_interval.sas
Purpose                 : Create a metadata dataset of date, time, or
                          datetime values for a specified time interval.
SAS Version             : Unknown (probably SAS 8.2)
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 12FEB2008
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

-----------------------------------------------------------------------
Notes:

---------------------------------------------------------------------*/

%macro time_interval
/*---------------------------------------------------------------------
Create a metadata dataset of date, time, or datetime values for a
specified time interval.
---------------------------------------------------------------------*/
(INTERVAL=     /* Specifies a time interval (REQ).  Valid values are */
               /* DAY, WEEK, WEEKDAY, MONTH, QTR, SEMIYEAR, YEAR,    */
               /* DTDAY, DTWEEK, DTWEEKDAY, DTMONTH, DTQTR,          */
               /* DTSEMIYEAR, DTYEAR, HOUR, MINUTE, SECOND.          */
               /* The time interval must match the type of the start */
               /* value.                                             */
,MULTIPLE=     /* Specifies a multiple of the interval (Opt).        */
               /* It sets the interval equal to a multiple of the    */
               /* interval type.  Valid values are NONNEGATIVE       */
               /* integers valid for the interval type.              */
,SHIFT=        /* Specifies the starting point of the interval (Opt).*/
               /* By default, the starting point is 1.  Valid values */
               /* are NONNEGATIVE integers valid for the interval    */
               /* type.                                              */
,START=        /* Starting date, time, or datetime value (REQ).      */
,END=          /* Ending date, time, or datetime value (Opt).        */
               /* Either END or INCREMENT must be specified, and are */
               /* mutually exclusive.  If both are specified, END    */
               /* takes precedence.                                  */
,INCREMENT=    /* Specifies a NONNEGATIVE integer that represents    */
               /* the number of date, time, or datetime intervals    */
               /* (REQ).  Increment is the number of intervals to    */
               /* shift the value of start from.                     */
,DIRECTION=B   /* Direction to shift the value of start from (REQ).  */
               /* Valid values are B BACKWARD F FORWARD.  Default    */
               /* value is BACKWARD, i.e. backwards in time from the */
               /* start value.                                       */
,ALIGNMENT=S   /* Controls the position of SAS dates within the      */
               /* interval (Opt).  Valid values are B BEGINNING      */
               /* M MIDDLE E END S SAME.  Default value is SAME.     */
               /* If not specified, BEGINNING is used.               */
,DATASET=TIME_INTERVAL
               /* Name of output dataset (REQ).  Default value is    */
               /* TIME_INTERVAL.                                     */
,MVAR=TIME_INTERVAL
               /* Macro variable to contain the time intervals (Opt).*/
               /* Default value is TIME_INTERVAL.  If not specified, */
               /* no macro variable is created.                      */
,FORMAT=YYMMDDN8.
               /* Format used to format the data in the dataset and  */
               /* macro variable (Opt).  Default value is YYMMDDN8.  */
               /* If not specified, no format is used, i.e. raw data.*/
               /* The parameter must be a valid format appropriate   */
               /* for the time interval specified.                   */
);

%local macro parmerr;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(INTERVAL,     _req=1,_words=0,_case=U,
                     _val=DAY WEEK WEEKDAY MONTH QTR SEMIYEAR YEAR
                          DTDAY DTWEEK DTWEEKDAY DTMONTH DTQTR DTSEMIYEAR DTYEAR
                          HOUR MINUTE SECOND)
%parmv(MULTIPLE,     _req=0,_words=0,_case=N,_val=NONNEGATIVE)
%parmv(SHIFT,        _req=0,_words=0,_case=N,_val=NONNEGATIVE)
%parmv(START,        _req=1,_words=1,_case=U)
%parmv(END,          _req=0,_words=1,_case=U)
%parmv(INCREMENT,    _req=0,_words=0,_case=N,_val=NONNEGATIVE)
%parmv(DIRECTION,    _req=1,_words=0,_case=U,_val=B BACKWARD F FORWARD)
%parmv(ALIGNMENT,    _req=0,_words=0,_case=U,_val=B BEGINNING M MIDDLE E END S SAME)
%parmv(DATASET,      _req=1,_words=0,_case=U)
%parmv(MVAR,         _req=0,_words=0,_case=U)
%parmv(FORMAT,       _req=0,_words=0,_case=U)

%* additional error checking ;
%* at least one of END or INCREMENT must be specified ;
%if (%quote(&end.&increment) eq ) %then %do;
   %parmv(_msg=END or INCREMENT must be specified)
%end;

%if (&parmerr) %then %goto quit;

%* if both END and INCREMENT are specified, print a warning, END takes precedence ;
%if (&end ne ) and (&increment ne ) %then %do;
   %put WARNING: END and INCREMENT are mutually exclusive.  END will be used.;
   %let increment = ;
%end;

%* build the interval string ;
%if (&multiple ne ) %then %let interval = &interval.&multiple;
%if (&shift    ne ) %then %let interval = &interval..&shift;

%* parse parameters that have an alias ;
%let direction = %substr(&direction,1,1);
%let alignment = %substr(%str(&alignment ),1,1);  /* use %str( ) in case alignment is blank */

%* build the metadata dataset ;
data &dataset;
   length n start end time_interval 8;
   call missing(of _all_);
   %if (&format ne ) %then %do;
   format start end time_interval &format;
   %end;
   start = &start;
   %if (&end ne ) %then %do;
   end   = &end;

   select("&direction");
      when("B") do;
         if start lt end then do;
            put "ERROR: START must be greater than or equal to END when direction is BACKWARD.";
            stop;
         end;
      end;
      when("F") do;
         if start gt end then do;
            put "ERROR: START must be less than or equal to END when direction is FORWARD.";
            stop;
         end;
      end;
   end;
   %end;

   n=0;
   do while (1);
      %if (&increment ne ) %then %do;
      if (n ge &increment) then leave;
      %end;
      time_interval=intnx(
         "&interval",
         &start,
         %if (&direction eq B) %then -;n
         %if (&alignment ne  ) %then ,"&alignment";
      );
      %if (&end ne ) %then %do;
         %if (&direction eq B) %then
            %let comp = lt;
         %else
            %let comp = gt;
      if (time_interval &comp &end) then leave;
      %end;
      output;
      n+1;
   end;
run;

%* if macro variable was specified, return the data as a string ;
%if (&mvar ne ) %then %do;
%global &mvar;
proc sql noprint;
   select time_interval into :&mvar separated by " " from &syslast;
quit;
%put >>> &mvar=&&&mvar;
%end;

%quit:
%mend;

/******* END OF FILE *******/