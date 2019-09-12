/*=====================================================================
Program Name            : delete_file.sas
Purpose                 : Deletes an external file, either by physical
                          filename or by pre-allocated fileref.
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 30NOV2016
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

First create a dummy external file accessible to your SAS server
session.  This means if you are using EG the file path must be from the
perspective of the server, not your local machine.  If in doubt, try
using a full UNC path, i.e. \\machine\folder\@@@.txt.

%let file=\\machine\folder\@@@.txt;  %* change to suit your environment ;

%delete_file(&file)

Deletes the file \\machine\folder\@@@.txt by its physical name.

=======================================================================

filename foo "&file";
%delete_file(foo)
filename foo;

Deletes the file \\machine\folder\@@@.txt by its fileref.
Note that the fileref must be allocated and deallocated outside the
macro.  The macro does not deallocate the fileref, even though the 
underlying file has been deleted.

=======================================================================

%put %delete_file(&file,rc=Y); 

* or ;
%let myrc=%delete_file(&file,rc=Y);
%put &=myrc;

Returns an optional return code to the macro processor code stream.
0=file was successfully deleted, not 0=file was not deleted.

=======================================================================

%delete_file(C:\doesnotexist.txt)
%delete_file(C:\Does\Not\Exist\doesnotexist.txt)
%put %delete_file(C:\Does\Not\Exist\doesnotexist.txt,rc=Y);
%let myrc=%delete_file(C:\Does\Not\Exist\doesnotexist.txt,rc=Y);
%put &=myrc;

%delete_file(XXX)
%delete_file(XXX,rc=Y);
%let myrc=%delete_file(XXX,rc=Y);
%put &=myrc;

Error checking:  
Should not generate any messages:
   Even if the directory path and filename does not exist.
   Even if the fileref has not been allocated.

-----------------------------------------------------------------------
Notes:

By default, this macro is "pure macro" code so does not submit any code 
to the SAS compiler.  If you then needed to confirm the deletion of the
file, you would have to manually code this outside the macro.

By default this macro (purposely) does not return a return code.
If you want a return code set, specify rc=Y, and call the macro in the
context of an rvalue, i.e. on the right side of an assignment
statement or boolean condition.

The return code is the return code from the FEXIST function, rather 
than the return code from the call to FDELETE.  This is a "safer" 
approach to checking that the file has actually been deleted.

I've purposely made this macro rather "quiet" by not printing messages
if the file does not exist, if the fileref is not allocated, etc.,
unlike the del or rm commands in Windows or Unix.

The logic trigger to determine whether the FILE parameter is a physical
path or a fileref is the presence of a slash (/ or \) in the parameter.

---------------------------------------------------------------------*/

%macro delete_file
/*---------------------------------------------------------------------
Deletes an external file, either by physical filename or by 
pre-allocated fileref.
---------------------------------------------------------------------*/
(FILE          /* Physical file path or pre-allocated fileref (REQ). */
,RC=NO         /* Confirm the deletion of the file by passing a      */
               /* return code value? (Opt).                          */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr dummy _rc_ _return_code_;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(FILE,         _req=1,_words=1,_case=N)  /* words=1 allows spaces in file path */
%parmv(RC,           _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* is it a physical file? assume yes if it contains a slash ;
%if (%sysfunc(indexc(&file,\/))) %then %do;
   %* allocate a fileref ;
   %* (what genius in SAS R&D dreamed up this syntax???) ;
   %let dummy=________;  %* use a fileref unlikely to be used by the end user ;
   %let _rc_=%sysfunc(filename(dummy,&file));

   %* any errors? ;
   %if (&_rc_ ne 0) %then %put %sysfunc(sysmsg());

   %* if the file exists, delete it ;
   %if (%sysfunc(fexist(&dummy))) %then %do;
      %let _rc_=%sysfunc(fdelete(&dummy));

      %* any errors? ;
      %if (&_rc_ ne 0) %then %put %sysfunc(sysmsg());
   %end;

   %* was a return code requested? ;
   %if (&rc) %then %do;
      %let _return_code_=%sysfunc(fexist(&dummy));
   %end;

   %* deallocate the fileref ;
   %let _rc_=%sysfunc(filename(dummy));

   %* any errors? ;
   %if (&_rc_ ne 0) %then %put %sysfunc(sysmsg());
%end;
%else %do;
   %* already a fileref so no need to allocate it ;

   %* if the file exists, delete it ;
   %if (%sysfunc(fexist(&file))) %then %do;
      %let _rc_=%sysfunc(fdelete(&file));

      %* any errors? ;
      %if (&_rc_ ne 0) %then %put %sysfunc(sysmsg());
   %end;

   %* was a return code requested? ;
   %if (&rc) %then %do;
      %let _return_code_=%sysfunc(fexist(&file));
   %end;
   %* since the end user pre-allocated the fileref, ;
   %* leave it to him/her to deallocate the fileref ;
%end;

%* was a return code requested? ;
%if (&rc) %then %do;
&_return_code_
%end;

%quit:

%mend;

/******* END OF FILE *******/
