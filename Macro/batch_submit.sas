/*=====================================================================
Program Name            : batch_submit.sas
Purpose                 : Submits the current SAS DMS editor session in
                          batch mode, routing the log and print files
                          to the correct output locations.

SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 08JUN2011
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

%batch_submit()

Submits the current SAS DMS editor session in batch, using the default
config file name.

=======================================================================

%batch_submit(,config=C:\Temp\myconfig.cfg)

Submits the current SAS DMS editor session in batch, using the specified
configuration file.  Best practice is to use an absolute path if you
specify a configuration file.

-----------------------------------------------------------------------
Notes:

This macro should be used on Windows SAS DMS only.

This macro is meant to be assigned to your SAS DMS Application Toolbar.
To do so, follow these steps:

* Ensure a SAS DMS editor window is active
* RMB the Application Toolbar and choose Customize...
* Scroll to the bottom of the Customize Tools window
* Select Add Tool
* Enter the text:  submit '%batch_submit()'; for the command
* Enter desired text for Help Text and Tip Text
* Change the icon if desired (recommended)
* Use the arrows to position the new command where desired on the toolbar
* Click OK and Save to save the new tool.

Alternative to the above, you could also assign the macro to a
function or hot-key setting.

You should create a configuration file specifying desired options,
such as -LOG, -PRINT, -AUTOEXEC, etc.

By default the expected configuration filename is config_batch.cfg,
but this can be changed via the macro CONFIG parameter.

The configuration file should set ALL other desired SAS options, eg.
-AUTOEXEC, -LOG, -PRINT, -RSASUSER, -ICON, -NOSPLASH, -AWSTITLE, etc.

However, if the configuration file cannot be found (either it wasn't
created, has the wrong name, or you're submitting a batch program from
a non-standard location, such as c:\temp), then the program will be
submitted in batch, with the log and print files written to the
directory containing the SAS program.

If the input filename is blank, it will be set to
%sysget(SAS_EXECFILEPATH) which, for a SAVED editor session under
SAS Windows DMS, is the full path to the editor session file.

This macro will first save out your current editor session to disk
before invoking the saved file in batch.

---------------------------------------------------------------------*/

%macro batch_submit
/*---------------------------------------------------------------------
Submits the current SAS DMS editor session in batch mode.
---------------------------------------------------------------------*/
(FILE          /* File to submit (Opt).                              */
                      /* If blank, the file will be set to                  */
                      /* %sysget(SAS_EXECFILEPATH)                          */
,CONFIG=       /* Default name of config file (Opt).                 */
                      /* If blank, it is set to config_batch.cfg.           */
                      /* If specified, a full path to the desired config    */
                      /* file should be specified.                          */
);

%* compile sub-macro ;
%macro dump_mvars(mvars);

%* dump list of macro variables to the log ;
%let line=%sysfunc(repeat(=,%sysfunc(getoption(ls))-1));
%let line=%substr(&line,1,80);
%put &line;

%let i=1;
%let mvar=%scan(&mvars,&i);
%do %while (&mvar ne );
    %put %sysfunc(putc(&mvar,$12.)) = %unquote(&&&mvar);
    %let i=%eval(&i+1);
    %let mvar=%scan(&mvars,&i);
%end;

%put &line;
%mend;

%* begin main macro ;
%local sas pos path basename log lst;

%* path to SAS command ;
%let sas=D:\Program Files\SASHome\SASFoundation\9.3\sas.exe;

%* if input file was not specified, set to SAS_EXECFILEPATH environment variable ;
%if (&file eq ) %then %let file=%sysget(SAS_EXECFILEPATH);

%* search backwards for the string "\prod\" (case insensitive) ;
%let pos=%sysfunc(find(&file,\prod\,i,-9999));
%if (&pos) %then %let path=%substr(&file,1,&pos)prod\;

%* search backwards for the string "\test\" (case insensitive) ;
%let pos=%sysfunc(find(&file,\qc\,i,-9999));
%if (&pos) %then %let path=%substr(&file,1,&pos)qc\;

%* if path is not found then the program is likely in a non-standard location ;
%* set the path to the directory containing the current program ;
%if (&path eq ) %then %do;
    %let pos=%sysfunc(find(&file,\,i,-9999));
    %if (&pos) %then %let path=%substr(&file,1,&pos);
    %let basename=%scan(%substr(&file,&pos+1),-2,.);
    %let log=&path.&basename..log;
    %let lst=&path.&basename..lst;
%end;

%* if config is missing set to &path.config_batch.cfg ;
%* otherwise assume an absolute path was specified ;
%if (&config eq ) %then %let config=&path.config_batch.cfg;

%* make sure the current editor session is saved to disk ;
dm "file";

%* if the config file is found use it, otherwise just submit without a config file ;
%let quotelenmax=%sysfunc(getoption(quotelenmax,keyword));
options noquotelenmax;
%if (%sysfunc(fileexist(&config)) and (%length(&log.&lst) eq 0)) %then %do;
    %dump_mvars(sas file path config)
    systask command " ""&sas"" -config ""&config"" -sysin ""&file"" " nowait;
%end;
%else %do;
    %dump_mvars(sas file path log lst)
    systask command " ""&sas"" -sysin ""&file"" -log ""&log"" -print ""&lst"" -sasinitialfolder ""&path"" " nowait;
%end;
options &quotelenmax;

%mend;

/******* END OF FILE *******/
