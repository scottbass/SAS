/*=====================================================================
Program Name            : sql_datetime.sas
Purpose                 : Converts a SAS datetime literal to a 
                          SQL Server datetime literal.
SAS Version             : SAS 9.3
Input Data              : SAS datetime literal (macro variable)
Output Data             : SQL Server literal


Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 18SEP2017
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

* this creates DATE7:TIME literal ;
%let dt=%sysfunc(datetime(),datetime16.);
%put %sql_datetime(&dt);
%put %squote(%sql_datetime(&dt));

=======================================================================

* this creates DATE9:TIME literal (length of 19-40 all work) ;
%let dt=%sysfunc(datetime(),datetime19.);
%put %sql_datetime(&dt);
%put %squote(%sql_datetime(&dt));

=======================================================================

* DATE9:TIME literal with milliseconds ;
%let dt=%sysfunc(datetime(),datetime24.3);
%put %sql_datetime(&dt);
%put %squote(%sql_datetime(&dt));

=======================================================================

* this creates ISO8601 (YYYY-MM-DDTHH:MM:SS) literal ;
%let dt=%sysfunc(datetime(),e8601dt.);
%put %sql_datetime(&dt);
%put %squote(%sql_datetime(&dt));

=======================================================================

* ISO8601 literal with milliseconds ;
%let dt=%sysfunc(datetime(),e8601dt24.3);
%put %sql_datetime(&dt);
%put %squote(%sql_datetime(&dt));

=======================================================================

* More extensive test ;
options sastrace=',,,d' sastraceloc=saslog nostsuffix;
options msglevel=I;
options mprint mrecall;

* Change the below to suit your environment ;
* libname foo odbc NOPROMPT="Driver={SQL Server Native Client 10.0};Server=YOURSERVER;Database=YOURDATABASE;Trusted_Connection=yes;";

%macro test(dt);
proc sql;
   connect using foo;
   select * from connection to foo (
      DECLARE @dt DATETIME2(0);
      SELECT @dt=%squote(%sql_datetime(&dt));
      SELECT @dt as [DATETIME];
   );
%mend;
%test(%sysfunc(datetime(),datetime16.));
%test(%sysfunc(datetime(),datetime19.));
%test(%sysfunc(datetime(),datetime24.3));
%test(%sysfunc(datetime(),e8601dt.));
%test(%sysfunc(datetime(),e8601dt24.3));
%test(%sysfunc(datetime(),best.));  * error checking, invalid input, this will fail ;

-----------------------------------------------------------------------
Notes:

SQL Server (as configured at our site) accepts strings such as these as
datetime literals:

25DEC18 20:12:34        (DATE7 + space + 24-hour time)
25DEC18 20:12:34.567    (DATE7 + space + 24-hour time with milliseconds)
25DEC2018 20:12:34      (DATE9 + space + 24-hour time)
25DEC2018 20:12:34.567  (DATE9 + space + 24-hour time with milliseconds)
2018-12-25T20:12:34     (ISO8601 time format (e8601dt. SAS format))
2018-12-25T20:12:34.567 (ISO8601 time format (e8601dt. SAS format) with milliseconds)
2018-12-25 20:12:34     (ISO8601 time format with space instead of "T"
2018-12-25 20:12:34.567 (ISO8601 time format with space instead of "T" with milliseconds)

Milliseconds is just an example; it could be other orders of magnitude as well.

This macro accepts either a DATETIME or E8601DT. ***STRING*** literal
as input.  

It does not accept the numeric datetime value - convert it to a string
first using an appropriate format.

This macro returns a string appropriate as a SQL Server datetime
literal in one of these formats:

DDMMMYY HH:MM:SS[.###]
DDMMMYYYY HH:MM:SS[.###]
YYYY-MM-DDTHH:MM:SS[.###]

If you want a datetime ***LITERAL*** that "works" as a literal in 
both SAS and SQL Server, use a SAS datetime literal, and pass that 
literal "as-is" to this macro.  

For example:

%let dt=25DEC2018:12:34:56;

* In SAS:
data test;
   datetime="&dt"dt;
   format datetime datetime.;
run;

* In SQL Server:
proc sql;
   connect using foo;
   execute (
      insert into dbo.mytable (datetime) values (%squote(%sql_datetime(&dt)))
   ) by foo;
quit;

It would be nice if SAS also accepted an ISO8601 datetime string as a 
datetime literal...but it doesn't.

---------------------------------------------------------------------*/

%macro sql_datetime
/*---------------------------------------------------------------------
Converts a SAS datetime literal to a SQL Server datetime literal.
---------------------------------------------------------------------*/
(SAS_DATETIME  /* SAS datetime string in either DATETIME. or         */
               /* E8601DT. (ISO8601 datetime) format.                */
);

%local macro parmerr rx1 rx2 rc1 rc2 sql_datetime;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(SAS_DATETIME,  _req=1,_words=0,_case=U)
%if (&parmerr) %then %goto quit;

%* datetime format ;
%let rx1=%sysfunc(prxparse(/(\d{2})(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)(\d{2,4}):(\d{2}):(\d{2}):(\d{2})/io));

%* e8601dt format ;
%let rx2=%sysfunc(prxparse(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/o));

%* is it datetime or e8601dt format? ;
%let rc1=%sysfunc(prxmatch(&rx1,&sas_datetime));
%let rc2=%sysfunc(prxmatch(&rx2,&sas_datetime));

%syscall prxfree(rx1);
%syscall prxfree(rx2);

%if (&rc1) %then %do;
   %let sql_datetime=%sysfunc(prxchange(s/:/ /o,1,&sas_datetime)); %* convert first colon to space ;
%end;
%else
%if (&rc2) %then %do;
   %let sql_datetime=&sas_datetime;  %* return ISO8601 datetime string as is ;
%end;
%else %do;
   %put %str(ERR)OR: Input string must be a valid datetime in DATETIME or E8601DT format.;
   %let sql_datetime=*** Invalid Input String ***;
%end;
      
&sql_datetime

%quit:
%mend;

/******* END OF FILE *******/
