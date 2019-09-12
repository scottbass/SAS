/*=====================================================================
Program Name            : dirlist.sas
Purpose                 : Creates a SAS dataset containing a directory
                          list of external files.
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 28SEP2016
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

Modification History    : Original Version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%dirlist(dir=C:\Windows\System32)

List files and directories in C:\Windows\System32, 
creating the default dataset work.dirlist.

=======================================================================

%dirlist(dir=C:\Windows\System32, data=sasuser.directory)

List files and directories in C:\Windows\System32, 
creating the sasuser.directory dataset.

=======================================================================

%dirlist(dir=C:\Windows\System32, type=f)

List files (only) in C:\Windows\System32, 
creating the default dataset.

=======================================================================

%dirlist(dir=C:\Windows\System32, type=d)

List directories (only) in C:\Windows\System32, 
creating the default dataset.

=======================================================================

%dirlist(dir=C:\Windows\System32, filter=basename=:'a' and ext='exe')

Filter output, saving only .exe files beginning with 'a'.

=======================================================================

%dirlist(dir=C:\Windows\System32, filter=prxmatch("/^.*S$/i",strip(basename)))

Filter output, saving only directories and files whose basename ends in 'S'
(case-insensitive).

=======================================================================

%dirlist(dir=C:\Windows\System32, type=f, filter=prxmatch("/^.*S$/i",strip(basename)))

Filter output, saving only files whose basename ends in 's'
(case-insensitive).

=======================================================================

%dirlist(dir=C:\Does\Not\Exist)

Error checking: path does not exist.

=======================================================================

%dirlist(dir=C:\Windows\explorer.exe)

Error checking: path exists but is not a directory.

-----------------------------------------------------------------------
Notes:

This macro is most useful when ALLOWXCMD=N and o/s system commands are
disabled.

This macro does not currently support directory recursion.

The FILTER parameter must be a syntactically correct SAS if statement.

The TYPE parameter is just a specialized implementation of a FILTER.

Note that SAS does not return datetime information for a directory,
even though Windows explorer and the dir command do.

This macro was developed under Windows.  
To see the file options SAS returns for your o/s, run this code,
then modify this macro as required:

   data _null_;
      length optname optvalue $200;
      fname="C:\Windows\explorer.exe"; * replace as required ;
      rc=filename('myfile',fname);
      fid=fopen('myfile');
      do i=1 to foptnum(fid);
         optname=foptname(fid,i);
         optvalue=finfo(fid,optname);
         put optname= optvalue=;
      end;
      rc=fclose(fid);
      rc=filename('myfile','');
   run;

---------------------------------------------------------------------*/

%macro dirlist
/*---------------------------------------------------------------------
Creates a SAS dataset containing a directory list of external files.
---------------------------------------------------------------------*/
(DIR=          /* Directory path to list (REQ).                      */
,DATA=work.dirlist
               /* Name of output dataset (REQ).                      */
               /* Default value is work.dirlist.                     */
,TYPE=         /* Type of files to list (Opt).                       */
               /* Valid values are F or D (case-insensitive)         */
,FILTER=       /* Filter to apply to the directory list (Opt).       */
               /* If not specified, all files and directories are    */
               /* returned.                                          */
);

%local macro parmerr temp;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DIR,          _req=1,_words=1,_case=N) 
%parmv(DATA,         _req=1,_words=0,_case=N)
%parmv(TYPE,         _req=0,_words=0,_case=U,_val=F D)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* does the directory exist? ;
%if not (%sysfunc(fileexist(&dir))) %then %do;
   %parmv(_msg=%str(ERR)OR: &dir does not exist)
   %goto quit;
%end;

%* no further error checking is done ;
%* the check for whether the path is a directory is done in the main code block ;
%* no checking is done on the syntax of the filter parameter ;

%* build the filter ;
%let temp=1;
%if (%superq(type) ne )   %then %let temp=%str(&temp and type="&type");
%if (%superq(filter) ne ) %then %let temp=%str(&temp and &filter);
  
data &data;
   length fullname $260 pathname $200 filename $100 basename $100 ext $10;
   length type $1 recfm $3 lrecl filesize createtime lastmodified 8;
   format filesize comma32. createtime lastmodified datetime21.;

   rc=filename('_dir_',"&dir",'','encoding="utf-8"');
   did=dopen('_dir_');
   if (did lt 1) then do;
      put "ERR" "OR: Unable to open &dir as a directory.";
      stop;
   end;
   
   do i=1 to dnum(did);
      call missing(of fullname pathname filename basename ext type recfm lrecl filesize createtime lastmodified);

      * name attributes ;
      fullname = catx('\',"&dir",dread(did,i));
      pos      = findc(fullname,'\',-999);
      pathname = substr(fullname,1,pos-1);
      filename = substr(fullname,pos+1);

      * extended file attributes ;
      fid=mopen(did,filename);
      type=ifc(fid > 0,'F','D');
      if (type='F') then do;
         basename       = scan(filename,-2,'.');
         ext            = scan(filename,-1,'.');
         %* processing if the file had no extension ;
         if (missing(basename)) then do;
            basename    = ext;
            call missing(ext);
         end;
         recfm          = finfo(fid,'RECFM');
         lrecl          = input(finfo(fid,'LRECL'),32.);
         filesize       = input(finfo(fid,'File Size (bytes)'),32.);
         createtime     = input(finfo(fid,'Create Time'),anydtdtm.);  %* anydtdtm to cope with regional settings ;
         lastmodified   = input(finfo(fid,'Last Modified'),anydtdtm.);
      end;
      else do;
         basename       = filename;
      end;                  
      fid=fclose(fid);
      if &temp then output;
   end;
   did=dclose(did);
   rc=filename('_dir_','');
   keep fullname pathname filename basename ext type recfm lrecl filesize createtime lastmodified;
run;

%quit:

%mend;

/******* END OF FILE *******/
