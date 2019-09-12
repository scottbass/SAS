/*====================================================================
Program Name            : handle.sas
Purpose                 : Print a list of open file handles to the 
                          SAS log
SAS Version             : SAS 9.2
Input Data              : None
Output Data             : None

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 29NOV2011
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

Modification History    : 

Programmer              : Scott Bass
Date                    : 03MAY2013
Change/reason           : Added unlock and email options to close
                          handles that are locking SAS datasets and
                          send and email to the process owner.
Program Version #       : 1.1

====================================================================*/

/*--------------------------------------------------------------------
Usage:

%handle;

Lists all open file handles on the server (probably not what you want)

======================================================================

Base Engine:

data one two;
   x=1;
run;

%handle(lib=work,           unlock=no, email=no);
%handle(data=work._all_,    unlock=no, email=no);
%handle(lib=work,data=one,  unlock=no, email=no);
%handle(lib=work,data=two,  unlock=no, email=no);
%handle(data=work.one,      unlock=no, email=no);
%handle(data=work.two,      unlock=no, email=no);

Will list nothing, since work.one and work.two are not locked.

Now open work.one via viewtable in another SAS session and repeat the above.

Now also open work.two via viewtable (so both one and two are open)
and repeat the above.

See log for results.

======================================================================

Repeat the above, specifying unlock=yes.

WARNING: This may have repercussions on your Base SAS DMS Session.

You can also try this using Enterprise Guide, which will only affect
your Workspace Server session.

======================================================================

SPDE Engine:

Open two datasets in claimdm via viewtable (eg. coverdim and datedim)

%handle(lib=claimdm);
%handle(data=claimdm._all_);
%handle(lib=claimdm,data=addressdim);
%handle(lib=claimdm,data=hcpcodesdim);
%handle(data=claimdm.addressdim);
%handle(data=claimdm.hcpcodesdim);

See log for results.

======================================================================

Explicit path specified:

Open any dataset in Lev2 meta, which uses a concatenated libref.
For example, meta.dmcolumndefinitions.

%handle(lib=meta,data=dmcolumndefinitions);
%handle(data=meta.dmcolumndefinitions);

These invocations should both fail since meta is a concatenated libref
in Lev2.

%handle(lib=Q:\tier0\test\meta);
%handle(lib=Q:\tier0\test\meta,data=dmcolumndefinitions);

This should work, see log for results.

----------------------------------------------------------------------
Notes:

The handle command does not accept usual filename wildcards, but will
filter the results based on a partial file fragment, including the file
path.  So, we can filter the results by specifying a path, a filename
(even a partial filename), or both.  See the help for handle.exe for 
more details.

If LIB is specified, it will override the library portion if you also
specify a two-level DATA parameter.

If you do not specify the LIB parameter, best practice is to specify a
two-level DATA parameter.  Otherwise, you could get the results of a
like-named file locked in another library (eg. a Lev2 dataset instead of
a Lev1 dataset).

If the dataset name for a two-level DATA parameter is "_ALL_", this is
equivalent to specifying only the LIB parameter, and the open file
handles for all files in that library will be returned.

I have not bothered adding support for multiple datasets in the same
macro call.  So, if you need to check locks for multiple datasets,
either check the library (which may return more than you want), or call
the macro multiple times.

This macro with NOT work with concatenated libraries.  The library
allocation must point to a single path.  If you want to test for open
handles on a concatenated library, explicitly specify the path in the
LIB parameter.

--------------------------------------------------------------------*/

%macro handle
/*--------------------------------------------------------------------
Print a list of open file handles to the SAS log
--------------------------------------------------------------------*/
(LIB=          /* SAS Library (Opt).                                */
               /* If not specified, the DATA parameter is checked   */
               /* for a two-level dataset name.  If so, that library*/
               /* is used.                                          */
,DATA=         /* SAS Dataset (Opt).                                */
               /* Either a one-level or two-level name can be       */
               /* specified.                                        */
,UNLOCK=NO     /* Kill the SAS process locking the dataset? (Opt).  */
               /* The default value is NO.                          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
,EMAIL=NO      /* Send email to SAS process owner? (Opt.)           */
               /* The default value is NO.                          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);

%local macro parmerr _lib _data path;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(UNLOCK,       _req=0,_words=0,_case=U,_val=0 1)
%parmv(EMAIL,        _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%global handle_rc;
%let handle_rc=0;

%* set various defaults ;
%let handle       = E:\SAS\Config\Utilities\handle64.exe;
%let handle_opts  = -accepteula -u;

%* options for email message ;
%let to=John.Doe@acme.com;  %* default email address, will get replaced if %useridToEmail lookup succeeds ;
%let cc=John.Doe@acme.com ^ Billy.Bob@acme.com ^ Suzie.Que@acme.com;
%* let cc=John.Doe@acme.com;  %* for development ;
%let subject=Your SAS session was locking Acme Datamart Datasets;
%let email_path=E:\SAS\Config\%sysget(lev)\SASApp\SASEnvironment\SASMacro\handle_email.txt;

%* Set library and dataset ;
%let _lib= %scan(&data,1,.);
%let _data=%scan(&data,2,.);

%* One-level name was specified ;
%if (&_data eq ) %then %do;
   %let _data=&_lib;
   %let _lib=work;
%end;

%* The library in a two-level dataset name takes precedence over the lib parameter, ;
%if (&_lib eq ) %then %let _lib=&lib;

%if (%upcase(&_data) eq _ALL_) %then %let _data=;

%* Now set the path filter ;
%if (%superq(_lib) ne ) %then %do;
   %* if an explicit path was specified, use the path as is ;
   %* assume an explict path contains at least one backslash ;
   %if (%index(%superq(_lib),\)) %then %do;
      %* nothing ;
   %end;
   %else %do;
      %* assume it is a libref ;

      %* is the library allocated ;
      %if (%sysfunc(libref(%superq(_lib))) ne 0) %then %do;
         %put ERROR:: Libref &_lib is not allocated.;
         %goto quit;
      %end;
      %else %do;
         %let _lib=%sysfunc(pathname(%superq(_lib)));

         %* if the library is a concatenated path print a message and quit ;
         %if (%index(%superq(_lib),%str(%())) %then %do;
            %put NOTE:: The handle macro does not work with concatenated library allocations.;
            %goto quit;
         %end;
      %end;
   %end;
   %* remove trailing slash ;
   %if (%substr(%superq(_lib),%length(%superq(_lib))) eq \) %then %let _lib=%substr(%superq(_lib),1,%length(%superq(_lib))-1);
%end;

%* Set path ;
%if (%superq(_lib) ne ) %then
   %let path=&_lib\&_data;
%else
   %let path=&_data;
%if (%superq(path) eq ) %then
   %let path=\;

%* Now invoke handle via filename pipe and echo the results to the log ;
%put;
%put Invoking Handle Macro:;
%put Current PID: &sysjobid;
%put;

/*
The below regular expression means:
^               = beginning of line
(.+?) pid: +    = one or more of any character (non-greedy matching (ngm)), until <space>pid:<one or more spaces>
pid: +(\d+) +   = pid:<one or more spaces>, one or more digits, <one or more spaces>
(\d+) +type: +  = one or more digits, <one or more spaces>, type:, <one or more spaces>
type: +(.+?) +  = type:, <one or more spaces>, one or more of any character (ngm), <one or more spaces>
(.+?)\\(.+?)    = one or more of any character (ngm), backslash, one or more of any character (ngm)
                  (some system userids have a space in them, for example NT AUTHORITY\LOCAL SERVICE
(  |>)          = either two spaces or a greater than sign (either delimits the end of the userid)
(.+?):          = one or more of any character (ngm), followed by a colon (:) and <space>
(.+)            = one or more of any character (greedy matching), up to ...
$               = end of line
*/

%let options=%sysfunc(getoption(ls,keyword));
options ls=max;
data _processes_;
   length process $30 pid 5 type $8 domain $15 userid $20 handle $5 path $300;
   if _n_=1 then do;
      rx=prxparse("/^(.+?) pid: +(\d+) +type: +(.+?) +(.+?)\\(.+?)(  |>)(.+?): (.+)$/o");
      retain rx;
   end;
   infile "&handle &handle_opts &path" pipe lrecl=1024 firstobs=6;
   input;
   if prxmatch(rx,trim(_infile_)) then do;
      process   = strip(prxposn(rx,1,_infile_));
      pid       = input(strip(prxposn(rx,2,_infile_)),best.);
      type      = strip(prxposn(rx,3,_infile_));
      domain    = strip(prxposn(rx,4,_infile_));
      userid    = strip(prxposn(rx,5,_infile_))||strip(prxposn(rx,6,_infile_));
      handle    = strip(prxposn(rx,7,_infile_));
      path      = strip(prxposn(rx,8,_infile_));

      %* print data to SAS log ;
      retain header 0;
      if (not header) then link header;
      temp=catx("\",domain,userid);
      putlog   @1 process   @33 pid 5. @40 type   @49 temp            @85 path;
      return;

      %* print header ;
      header:
         header=1;
         putlog;
         putlog @1 "WARNING: One or more files are locked.";
         putlog;
         putlog @1 "PROCESS" @33 "PID" @40 "TYPE" @49 "DOMAIN\USERID" @85 "PATH";
         putlog @1 "=======" @33 "===" @40 "====" @49 "=============" @85 "====";
      return;
   end;
   else delete;
   drop rx temp header;
run;
options &options;

%if (%nobs(_processes_) eq 0) %then %goto quit;

%* if unlock=yes, use handle again to unlock the handles ;
%* use systask instead of system(), call system(), or X since it causes less window flashing ;
%if (&unlock) %then %do;
   *** close open file handles *** ;
   data _null_;
      set _processes_;
      length command $500;
      command=catx(
         " ",
         "&handle",
         "-accepteula",
         "-p", pid,
         "-c", handle,
         "-y"
      );
      command=catx(
         " ",
         "systask",
         "command",
         quote(strip(command)),
         "wait;"
      );
      call execute(command);
   run;
%end;

*** check that the file handles have been closed *** ;
data _null_;
   call symputx("handle_rc",0);
   infile "&handle &handle_opts &path" pipe lrecl=1024 firstobs=6;
   input;
   if (prxmatch("/No matching handles found./o",_infile_)) then do;
      putlog _infile_/"0A0D"x;
      stop;
   end;
   call symputx("handle_rc",1);
   stop;
run;

%* if email=yes, send an email to each unique userid ;
%if (&email) %then %do;
   *** send notification email *** ;
   proc sql noprint;
      select distinct
         catx("|",userid,pid) into :userids separated by "^"
      from
         _processes_
      where
         domain="INTERNAL"  /* only email "human" userids, not service accounts */
      ;
   quit;

   %macro handleSendEmail;
      %let userid    = %scan(&word,1,|);
      %let pid       = %scan(&word,2,|);

      %* initialize variables used in the email text ;
      %let firstname = &userid;  %* initialize in case %useridToEmail lookup fails ;

      %* Retrieve email address from userid ;
      %useridToEmail(userid=&userid,mvar=emailaddress)

      %if (&emailaddress ne ) %then %do;
         %let to=&emailaddress;
         %* assume email address is in the form firstname.lastname@acme.com ;
         %let firstname=%scan(&emailaddress,1,.);
         %let firstname=%sysfunc(propcase(&firstname));
      %end;

      %* put email lookup debugging information in the log ;
      %put qad_rc=&qad_rc;
      %put emailaddress=&emailaddress;

      %* create mail dataset from external file ;
      data mail;
         length parm $15 line $1000;
         retain parm "";
         retain header 0;

         do until (eof1);
            infile "&email_path" truncover lrecl=1000 end=eof1;
            input;
            line=resolve(_infile_);
            output;
         end;

         %* add appendix information to the email ;
         do until (eof2);
            set _processes_ end=eof2;
            if (not header) then link header;
            call missing(line);
            substr(line,1) =process;
            substr(line,33)=put(pid,5.);
            substr(line,40)=type;
            substr(line,49)=catx("\",domain,userid);
            substr(line,85)=path;
            output;
         end;

         stop;

         header:
            header=1;
            call missing(line);
            line="Appendix: List of locked files";
            output;
            call missing(line);
            output;
            substr(line,1) ="PROCESS";
            substr(line,33)="PID";
            substr(line,40)="TYPE";
            substr(line,49)="DOMAIN\USERID";
            substr(line,85)="PATH";
            output;
            call missing(line);
            substr(line,1) ="=======";
            substr(line,33)="===";
            substr(line,40)="====";
            substr(line,49)="=============";
            substr(line,85)="====";
            output;
         return;

         keep parm line;
      run;

      %sendmail(
         to=&to
         ,cc=&cc
         ,subject=&subject
         ,content_type=text/plain
         ,metadata=mail
      )
   %mend;
   %loop(&userids,mname=handleSendEmail,dlm=^)
%end;

%quit:

%mend;

/******* END OF FILE *******/
