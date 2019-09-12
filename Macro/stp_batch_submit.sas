/*=====================================================================
Program Name            : stp_batch_submit.sas
Purpose                 : Submit a SAS batch program from a Stored Process
SAS Version             : SAS 9.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 03MAY2012
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

* simulate macro variables created from a stored process ;
* best practice is that the macro variables have the prefix "batch_" ;

* macro variables sent to the batch job ;
* these macro variables are set outside this macro, ;
* either by the STP prompts or in the STP SAS code. ;
%let batch_username     = &_username;
%let batch_jobname      = Your SAS Batch Job;
%let batch_config_file  = C:\Temp\batch_test.cfg;

* create a message dataset ;
* this dataset is used to display a confirmation message to the user ;
* this dataset is set outside this macro ;
data message;
   infile datalines truncover;
   input message $200.;
   keep message;
   datalines4;
Job &batch_jobname submitted at %sysfunc(strip(%sysfunc(datetime(),datetime18.))).
You will receive an email when the job finishes.
;;;;
run;

* call this macro ;
%stp_batch_submit(config=path_to_sas_config_file);

=======================================================================

* call this macro, overriding default values ;
%stp_batch_submit(
   message=my_message_dataset
   ,mvars=name like 'BATCH_' or name in ('FOO','BAR','BLAH')
   ,sas=path_to_sas_executable
   ,config=path_to_sas_config_file
   ,pgm=path_to_sas_program_file
   ,log=path_to_sas_log_file
   ,lst=path_to_sas_print_file
   ,options=any desired SAS invocation options
   ,timeout=300
);

=======================================================================

* As an alternative to a message dataset, you can also use an external file ;
%stp_batch_submit(
   messagefile=C:\Temp\message.html
   ,config=path_to_sas_config_file
);

-----------------------------------------------------------------------
Notes:

The message dataset must be created outside this macro.  If the message
dataset does not exist, a default message is displayed to the end user.

The message dataset must contain valid HTML.  You could create anything
in the message dataset, for example displaying a message box via
javascript, then javascript to close the new window.

Alternatively, you can create any HTML/javascript/etc. code and save it
in an external file, then use that file via the MESSAGEFILE parameter.
If both MESSAGE and MESSAGEFILE parameters are specified, the
MESSAGEFILE parameter has priority.

By default, all macro variables created by the stored process that
begin with "BATCH_" are propagated to the batch job.  The list of macro
variables sent to the batch program can be changed by setting the MVARS
parameter.

Hidden stored process prompts (macro variables) (usually prefixed with
"batch_") can be used to pass additional metadata to the batch job.

The macro variables are propagated to the batch program via the dataset
SAVE.PARAMETERS, where "SAVE" is the temporary directory created by the
stored process session.  This dataset name is hard coded and cannot be
changed unless you edit the macro code.

The SAVE library is a temporary library created by the stored process
server.  It is created under the stored process server work directory,
and is deleted once the stored process session times out.  The stored
process session timeout default value is 2 minutes, which is more than
enough time for the batch job to start and re-initialize the macro
variables.  However, this timeout can be changed via the TIMEOUT
parameter, although this would rarely if ever be needed.

The batch job must contain this code (or the functional equivalent):

-----------------------------------------------------------------------

* Allocate the SAVE library passed in via sysparm ;
* Additional parameters could be passed in via sysparm, delimited by ^ or | ;
libname save "%scan(&sysparm,1,%str(^|))";

* Set macro variables passed in to the batch job by the Stored Process ;
data _null_;
   set save.parameters;
   call symputx(name,value,"G");
run;

* The rest of the batch program goes here... ;
* Macro variable processing would be done exactly as in a stored process ;

---------------------------------------------------------------------*/

%macro stp_batch_submit
/*---------------------------------------------------------------------
Submit a SAS batch program from a Stored Process
---------------------------------------------------------------------*/
(MESSAGE=work.message
               /* Message dataset to display a confirmation message  */
               /* to the end user (REQ).  The MESSAGE parameter must */
               /* define a syntactically correct dataset.  If the    */
               /* dataset does not exist, a default dataset is       */
               /* created.                                           */
,MESSAGEFILE=  /* Absolute path to an HTML file to display a         */
               /* confirmation message to the end user (Opt).        */
               /* If MESSAGEFILE is specified it will take priority  */
               /* over MESSAGE (which has a default value).          */
,MVARS=name like 'BATCH_%'
               /* Macro variables to propagate to the batch job (Opt)*/
               /* If blank, then all macro variables are propagated  */
               /* to the batch job.  This parameter should be        */
               /* specified as a where clause appropriate for the    */
               /* SQL dictionary table dictionary.macros.            */
,SAS=/opt/sas/Config/Lev1/SASApp/BatchServer/sasbatch.sh
               /* Absolute path to SAS executable (REQ).             */
,CONFIG=       /* Absolute path to SAS config file (Opt).            */
,PGM=          /* Absolute path to SAS program file (Opt).           */
,LOG=          /* Absolute path to SAS log file or directory (Opt).  */
,LST=          /* Absolute path to SAS print file or directory (Opt).*/
,OPTIONS=      /* Any desired SAS invocation options (Opt).          */
,TIMEOUT=120   /* Stored process server session timeout in seconds   */
               /* (REQ).                                             */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(SAS,          _req=1,_words=1,_case=N)
%parmv(TIMEOUT,      _req=1,_words=1,_case=N)

%if (&parmerr) %then %goto quit;

%* Additional error checking ;
%* If both CONFIG and PGM are blank, abort to prevent a DMS session ;
%* from being launched on the server ;
%if (%superq(config) eq ) and (%superq(pgm) eq ) %then %do;
   %parmv(_msg=%str(ERR)OR: Either CONFIG or PGM must be specified)
   %goto quit;
%end;

/*
Propagate any extra STP variables by prefixing them with "BATCH_"
*/
%let batch_username = &_username;
%let batch_program  = &_program;
%let batch_progname = %scan(&batch_program,-1,/);

/*
Create a Stored Process (STP) session, which allocates the temporary SAVE library.
This library is used to pass parameters between the STP and the batch job.
*/
%if (%sysfunc(libref(SAVE)) ne 0) %then %do;
   %let rc=%sysfunc(stpsrv_session(create,&timeout));
%end;

/*
Check that the SAVE library was allocated
*/
libname save list;

/*
This macro variable must be set AFTER the session is created.
*/
%let batch_save_library=%sysfunc(pathname(save));

/*
If the message dataset does not exist, create a default message dataset.
If a messagefile was specified, create a message dataset from that file.
Bummer you cannot use cards/datalines in a macro.
*/
%if (not %sysfunc(exist(&message)) or (%superq(messagefile) ne )) %then %do;
   %if (%superq(messagefile) eq ) %then %do;
      data &message;
         length message $200 buffer $32767;
         keep message;
         buffer='
| <html>
| <head>
| <script type="text/javascript">
| alert("Your &batch_progname has been submitted. You will receive an email when your job has finished.");
| window.close()
| </script>
| </head>
| <body>
| </body>
| </html>
';
         i=1;
         do while (scan(buffer,i,"|") ne "");
            message=left(scan(buffer,i,"|"));
            output;
            i+1;
         end;
      run;
   %end;
   %else %do;
      data &message;
         length message $32767;
         infile "&messagefile";
         input;
         message=_infile_;
      run;
   %end;
%end;

/*
Now copy the desired parameters (macro variables) to the SAVE library.
This dataset will be used by the batch job to recreate the macro variables.
*/
%if (%sysfunc(exist(save.parameters))) %then %lock(member=save.parameters,action=lock);
proc sql noprint;
   create table save.parameters as
      select
         name
         ,value
      from
         dictionary.macros
      where
         &mvars
   ; 
quit;
%lock(member=save.parameters,action=clear)

/*
Setup the parameters for invoking SAS, then launch the SAS job.
You MUST pass in the path to the SAVE library location via sysparm.

My preference is to use a configuration file, rather than command line options,
with ALL other job configuration (eg. -sysin) done in the configuration file.
This gives the maintainer of the code ONE place to go to change the batch job options.
However, you can configure this however you wish.
*/

/*
NOTE:  Do NOT change the single/double quoting below, or you will likely break this!
*/
%let parms=;
%if (%superq(config)  ne ) %then %let parms=&parms -config '&config';
%if (%superq(pgm)     ne ) %then %let parms=&parms -sysin '&pgm';
%if (%superq(log)     ne ) %then %let parms=&parms -log '&log';
%if (%superq(lst)     ne ) %then %let parms=&parms -print '&lst';
%if (%superq(options) ne ) %then %let parms=&parms &options;

%let parms=&parms -sysparm '&batch_save_library';

/*
%* We need to specify a service user credentials for the spawned SAS job ;
%* For now just use my credentials until the service user is setup (including TeraProdAuth Domain) ;
*/
%let parms=&parms -metauser m49505 -metapass {sas002}5F4652380A480B7F1295D9FD49482080;

/*
Invoke the SAS batch job.
*/
%let options=%sysfunc(getoption(quotelenmax));
options noquotelenmax;
%if (&sysscp eq WIN) %then %do;
   systask command " ""&sas"" &parms " nowait;
%end;
%else %do;
   systask command "&sas &parms" nowait;
%end;
options &options;

/*
Resolve any embedded macro variables in the message dataset.
The options nomerror and noserror suppress warning messages in the log
for unresolved macro and unresolved macro variable references.
HTML code in particular can have tokens (eg. &_program=...) that look like macro variables
but are HTML tokens instead.
*/

%if (%sysfunc(fileref(_webout)) le 0) %then %do;

%let options=%sysfunc(getoption(merror,keyword)) %sysfunc(getoption(serror,keyword));
options nomerror noserror;
data work._message_ (compress=char);
   %* pick a variable not likely to be in the source dataset ;
   length ________ $32767;
   set &message;
   %* there should only be one variable, but this construct ;
   %* allows the variable name to be anything ;
   ________=cats(of _char_);
   ________=resolve(________);
run;
options &options;

/*
Now display the confirmation message to the user
*/
data _null_;
   file _webout;
   set work._message_;
   put ________;
run;

%end;

%quit:
%mend;

/******* END OF FILE *******/
