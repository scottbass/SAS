/*====================================================================
Program Name            : RunAll.sas
Purpose                 : Runs SAS programs asynchronously and
                          multi-threaded, honoring any job
                          dependencies.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 01MAY2010
Program Version #       : 1.0
======================================================================

Scott Bass (sas_l_739@yahoo.com.au)

This code is licensed under the Unlicense license.
For more information, please refer to http://unlicense.org/UNLICENSE.

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

=======================================================================

Modification History    : Original Version

====================================================================*/

/*--------------------------------------------------------------------
Usage:

Create required macro variables and programs dataset in a separate
program, then %include this program.

This program would normally be located in the base directory of the
study.

----------------------------------------------------------------------
Notes:

This program uses SAS as the "scripting engine" to submit additional
SAS programs in batch mode.  This makes this approach portable to both
Windows and Unix.

The program honors any dependencies specified in the list of programs.
Programs dependent on the completion of other programs will not run
until the "parent" program(s) finish.  This is usually relevant to SDTM
or ADAM processing, although this program can also be used to
asynchronously run independent TFL programs.

Set the macro variable abort=Y to abort processing if any upstream
program ends in error.

Set the macro variable max_threads to limit concurrent threads to that
number.  In principle, there should always be a value for max_threads,
so always set it to to some value, i.e. a number high enough to get
maximum throughput. However, you should pay attention to any decreased
machine performance when running multiple SAS processes, and adjust
max_threads accordingly.

More threads is not necessarily better.  On my dual core laptop, I get
the best elapsed time with max_threads=2.  Use the elapsed time results
at the bottom of the log to derive the best value for max_threads for
your environment.

It is a good idea to set abort=Y and run with a small number of
programs until all parameters are correct and the process is debugged.
If SAS fails to initialize (usually due to bad configuration settings),
it is difficult to break out of the main SAS driver program. Setting
abort=Y and max_threads=1 should be sufficient to abort if the SAS
configuration parameters are incorrect.

If running programs from a single directory under a programming
environment (prod or qc), you can either define -log and -print options
in an (environment specific) SAS configuration file, as parameters to
the command string (&cmd), or in the programs dataset.

If running programs from multiple directories, or across programming
environments (eg. all of SDTM, ADAM, and TFLs, or from both prod and qc
environments), then the program paths and/or -log and -print options
must be specified in the programs dataset since these values are now
dynamic rather than static.

You can specify a list of programs via the -sysparm invocation
option to limit the list of programs to run.  The program names
specified on the sysparm option must exactly match the >basenames<
as specified in the datalines statement below
(eg. without path, with extension)

A run summary report is created at the end of the job run, indicating
the run status for each program.

To debug the code generation process, comment out the line
"%include code", then review the code via "fslist code".

To prevent warning messages in the log about unable to read
sasuser.profile, create a copy of your sasuser directory, and
configure the batch runs to use the copied sasuser directory and
the -rsasuser option.

--------------------------------------------------------------------*/

/* ===================================================================
Define required macro variables and programs dataset in separate program
=================================================================== */

%macro RunAll(data=programs, debug=N);

proc optsave out=options;
run;

options ls=200;

proc sort data=&data;
   by group program;
run;

%* further process programs dataset ;
data &data;
   length group 8 env $32 program $200 source $200 path $200 basename filename $32 ext $3 fullpath log print $200 taskname status $32;
   set &data;
   pos = findc(program,"&fs",-1000);
   if pos then path=substr(program,1,pos-1);
   basename = substr(program,pos+1);
   filename = scan(basename,1,".");
   ext      = scan(basename,2,".");
   if (missing(ext)) then ext="sas";
   fullpath = quote(catx("&fs",source,path,catx(".",filename,ext)));
   taskname = filename;
   status   = filename;
run;

%* delete all status macro variables from any previous runs ;
proc sql noprint;
   select status into :status_vars separated by " " from &data;
quit;

%symdel &status_vars / nowarn;

%* Note:  a (temporary) physical file results in "truncated record" on the %include statement. ;
%* A source catalog entry does not have this issue.  I tried the S2= option on the %include ;
%* statement but this did not fix the issue.  A catalog entry also does not have a lock on the ;
%* file if it is open via fslist (for example if you forget to close fslist while debugging). ;
%* So why bother, just use a catalog entry ;
filename code catalog "work.run.runall.source";

%* generate code ;
options noquotelenmax;
data _null_;
   length tasklist statuslist $1000;
   call missing(tasklist, statuslist);
   file code lrecl=1000;

   if (_n_=1) then do;
      put @1 '%global abort;';
      put @1 '%macro RunPgms;';
   end;

   do i=1 to &max_threads until (last.group);
      set &data;
      by group;
      if (^missing("&sysparm")) then
         if (^find(cats("&fs",basename,"&fs"),cats("&fs","&sysparm","&fs"),"t")) then
            continue;
      tasklist   = catx(" ",tasklist,taskname);
      statuslist = catx(" ",statuslist,status);
      put @4 '%global ' status +(-1) ";";
      put @4 "systask command " "'" "%superq(command)" @;
      if ^missing(log)   then put "-log "   log @;
      if ^missing(print) then put "-print " print @;
      put "-sysin " fullpath +(-1) @;
      put "' " taskname= status= "nowait;";
   end;

   if (^missing(tasklist)) then
      put @4 "waitfor _all_ " tasklist +(-1) ";";

   do i=1 to &max_threads until (last.group);
      set &data end=end;
      by group;
      if (^missing("&sysparm")) then
         if (^find(cats("&fs",basename,"&fs"),cats("&fs","&sysparm","&fs"),"t")) then
            continue;
      put @4 '%if (%upcase(&abort)=Y and not %index(&abort_codes,&' status +(-1) ')) %then %return;';  /* poor mans macro IN operator */
   end;

   if (end) then do;
      put '%mend;';
      put '%RunPgms;';
   end;
run;

%* Run generated code.  Run "fslist code" command to preview generated code ;
%if (&debug=N) %then %do;
   %include code / source2;

   proc format;
   value status_code
      .           = "Program was not run"
      low -< 0    = "SAS Failed to Initialize"
      0           = "SAS Ended Successfully"
      1           = "SAS Ended With Warnings"
      2           = "SAS Ended With Errors"
      3           = "User issued the ABORT statement"
      4           = "User issued the ABORT RETURN statement"
      5           = "User issued the ABORT ABEND statement"
      6           = "SAS internal error"
      >6 - high   = "User specified RETURN code"
   ;
   run;

   data status;
      format program return_code results log;
      set &data;
      if (^missing("&sysparm")) then
         if (^find(cats("&fs",basename,"&fs"),cats("&fs","&sysparm","&fs"),"t")) then
            delete;
      if (symexist(status)) then return_code = symgetn(status);
      results = put(return_code,status_code.);
      log     = cats(dequote(log),"&fs",filename,".log");
      keep program return_code results log;
   run;

   * create batch run summary report ;
   filename summrpt "&summary_rpt";
   %let rc=%sysfunc(fdelete(summrpt));

   ods _all_ close;
   %if (&summary_rpt_type eq html) %then %do;
      ods results on;
      ods &summary_rpt_type (id=summrpt) file=summrpt;
      options center;
      %let log=display;
   %end;
   %else
   %if (&summary_rpt_type eq rtf) %then %do;
      ods results off;
      ods &summary_rpt_type (id=summrpt) file=summrpt;
      options center;
      %let log=display;
   %end;
   %else
   %if (&summary_rpt_type eq txt) %then %do;
      ods listing file=summrpt;
      options nocenter;
      %let log=noprint;
   %end;

   options formchar="|----|+|---+=|-/\<>*" nonumber;
   options ls=max ps=max;

   title1 "RunAll Summary Report";
   title2 "%sysfunc(date(),date9.)";
   proc report data=status nowd box;
      column program return_code results log;
      define program       / display   width=32 "Program Name";
      define return_code   / display   width=6  "Return Code";
      define results       / display   width=40 "Results";
      define log           / &log      width=80 "Program Log";
      compute return_code;
         select (return_code);
            when (.)  call define(_row_,"style","style=[background=lightyellow]");  /* program was not run */
            when (0)  call define(_row_,"style","");
            when (1)  call define(_row_,"style","style=[background=lightorange]");
            otherwise call define(_row_,"style","style=[background=red]");
         end;
      endcomp;
      compute log;
         urlstring=cats("file://",trim(log));
         call define(_col_,"url",urlstring);
      endcomp;
   run;

   ods _all_ close;
   ods results on;
   ods listing;

   title;
   * display batch run summary report ;
   * use default application associated with the file extension ;
   systask command " ""%sysfunc(pathname(summrpt))"" " taskname="Display Summary Report" nowait cleanup;
   killtask "Display Summary Report";
   options ls=&ls ps=&ps;
%end;
%else %do;
   %* write the generated code to the log ;
   data _null_;
      infile code;
      input;
      putlog _infile_;
   run;
%end;

proc optload data=options;
run;

%mend;
