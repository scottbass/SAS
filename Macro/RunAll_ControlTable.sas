/*====================================================================
Program Name            : RunAll_ControlTable.sas
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

Modification History    : Original Version

====================================================================*/

/*--------------------------------------------------------------------
Usage:

----------------------------------------------------------------------
Notes:

This program is a template program to create a Programs control table
with specified program dependencies, then calls the %RunAll macro to
run the programs in batch mode, honoring the specified dependencies.

This program uses SAS as the "scripting engine" to submit additional
SAS programs in batch mode.  This makes this approach portable to both
Windows and Unix.

This program honors any dependencies specified in the list of programs.
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

The %dirlist macro 
(https://github.com/scottbass/SAS/blob/master/Macro/dirlist.sas)
could also be useful to seed the Programs control dataset from a 
directory of existing programs.

--------------------------------------------------------------------*/

%let start_time=%sysfunc(datetime());

* define parameters for batch run ;
%let abort              = Y;
%let abort_codes        = 0 1;  * 0 to abort on warnings and errors, 0 1 to abort on errors only ;
%let max_threads        = 10;
%let fs                 = /;    * Windows = \, Unix = / ;
%let env                = prod; * prod or qc ;
%let base               = /proj/009/tak491_303;
%let autoexec           = &base.&fs.&env.&fs.autoexec.sas;
%let source             = &base.&fs.&env.&fs.programs;
%let log                = &base.&fs.&env.&fs.output&fs.logs;
%let print              = &base.&fs.&env.&fs.output&fs.reports;
%let summary_rpt_type   = html;  * html or rtf or txt.  I prefer HTML since MS Word keeps a lock on the RTF file. ;
                                 * Use txt on Unix or else html then ftp protocol in your browser (ftp://sbass@prnapp17//proj/009/tak491_303/...) ;
%let summary_rpt        = &log.&fs.RunAll.&summary_rpt_type;

%let sas                = %sysget(SAS_ROOT)/sas;
%let config             = ;
%let options            = -autoexec &autoexec;
%let command            = &sas;

* debugging statement ;
%put %quote(&command);

* define list of programs to run here ;
* define dependency groups using the group variable ;
* if running programs across environments specify the env variable ;
data programs;
   length group 8 env $4 program $200 source $200 log print $200;
   input group /* env */ program;
   source   = "&source";
   env      = "&env";
   log      = quote("&log");
   print    = quote("&print");
/* alternative approach
   log      = quote(catx("&fs","&base",env,"output","logs"));
   print    = quote(catx("&fs","&base",env,"output","reports"));
*/
   datalines;
0  ..\..\..\formats.sas
1  test1.sas
1  test2.sas
1  test3.sas
2  test4.sas
2  test5.sas
3  test_error.sas
3  test_warning.sas
4  test6.sas
4  test7.sas
4  test8.sas
4  test9.sas
;
run;

* compile RunAll macro ;
%include "&base.&fs.RunAll.sas" / nosource nosource2;
%RunAll(debug=N);

%let end_time=%sysfunc(datetime());
%put %str(Ela)psed Time=%sysfunc(round(&end_time - &start_time,1E-2)) seconds.;

options ls=&ls;
