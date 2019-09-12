/*====================================================================
Program Name            : execpath.sas
Purpose                 : Returns either the full path or the file name
                          of the currently executing program, in all of
                          DMS, EG, line mode, and batch mode,
                          on both Unix and Windows.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Scott Bass
Date                    : 09SEP2010
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

Modification History    : Original version

====================================================================*/

/*--------------------------------------------------------------------
Usage:

In DMS (say from Windows):

%put %execpath;
   Returns "DMS Process" if the Program Editor is unsaved
   Returns "Full program filename" if the Program Editor is saved,
      i.e. open on a saved file.

=======================================================================

In EG:

%put %execpath;
   Returns "EG Project Name:EG Task Label", for example:
   C:\Documents and Settings\sbass\My Documents\SAS\My SAS Projects\test1.egp:temp

=======================================================================

In line mode SAS (say from Unix):

sas -nodms

1?  %put %execpath;
   Returns "Line Mode Process"

=======================================================================

In batch mode SAS (either Windows or Unix):

sas c:\temp\test.sas, or
sas ~/mysasfiles/test.sas

Where test.sas contains %put %execpath;
   Returns "Full program filename"

%put %execpath(basename=Y);
   Returns the basename of the file, i.e. the filename only, not the
   full path.

----------------------------------------------------------------------
Notes:

This macro is a function style macro, so must be called as an rvalue
(right hand side of the equal sign) or in the context of a function
call.

--------------------------------------------------------------------*/

%macro execpath
/*--------------------------------------------------------------------
Returns the full path or filename of the currently executing program.
--------------------------------------------------------------------*/
(BASENAME=N    /* Return the filename only? (Opt).                  */
               /* Default is N.  If Y, then only the filename is    */
               /* returned.                                         */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(BASENAME,     _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%let execpath=;

%* Batch mode ;
%let execpath=%sysfunc(getoption(SYSIN));

%* DMS (Windows only) ;
%* returns either Saved File ("File Name") or Untitled Editor ("DMS Process") ;
%if %length(&execpath)=0 %then
   %if (&sysscp eq WIN) %then
      %if (%index(&sysprocessname,DMS)) %then
         %let execpath=%sysget(SAS_EXECFILEPATH);

%* EG ;
%if (%symexist(_CLIENTAPP)) %then %do;
   %if (&_CLIENTAPP eq SAS Enterprise Guide) %then %do;
      %local project program;

      %* If submitting a saved program return the program path ;
      %* Else return the project path:task label ;
      %if (%symexist(_SASPROGRAMFILE)) %then %do;
         %let execpath=%scan(&_SASPROGRAMFILE,1,%str(%'%"));
      %end;

      %if (&execpath eq ) %then %do;
         %if (%symexist(_CLIENTPROJECTNAME)) %then
            %let project=&_CLIENTPROJECTNAME;
         %if (&project eq ) %then %let project=Unsaved EG Project;

         %if (%symexist(_EGTASKLABEL)) %then
            %let program=&_EGTASKLABEL;

         %let execpath=&project:&program;
      %end;
   %end;
%end;

%* All Other Scenarios ;
%if %length(&execpath)=0 %then
   %let execpath=&sysprocessname;

%if (not &basename) %then %do;
%unquote(&execpath)
%end;
%else %do;
%unquote(%scan(&execpath,-1,%str(/\:)));
%end;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
