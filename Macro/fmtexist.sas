/*=====================================================================
Program Name            : fmtexist.sas
Purpose                 : Checks the format searchpath for the
                          existence of a format or informat.
SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : None

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 30APR2007
Program Version #       : 1.0

=======================================================================

Copyright (c) 2016 Scott Bass

https://github.com/scottbass/SAS/tree/master/Macro

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=======================================================================

Modification History    : Original version

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%if (%fmtexist(gender)) %then %put EXISTS...;
%let num=%fmtexist(yesno, catalog=LIBRARY.MYFMTS);
%put %fmtexist($chr_fmt);
%put %fmtexist(#num_fmt);

-----------------------------------------------------------------------
Notes:

Returns the number of formats/informats found as an RVALUE.
For example, formats and informats can have the same name in a
single catalog, or formats with the same name can exist across
multiple format catalogs, so it's possible that more than one entry
with the same name is found.

Returns the 4-level name of the entry(s) found in the global macro
variable FMTLIST.

To restrict the search to a particular type, specify:
   $ for character formats
   # for numeric formats

Otherwise the search will be for both types with the given format name.

---------------------------------------------------------------------*/

%macro fmtexist
/*---------------------------------------------------------------------
Checks the format searchpath for the existence of a format or informat
---------------------------------------------------------------------*/
(FORMAT        /* Format or Informat to find (REQ).                  */
,CATALOG=      /* Format catalog to search (Opt).                    */
               /* If blank, uses current value of FMTSEARCH option   */
               /* to locate entry.                                   */
);

%global fmtlist;
%let fmtlist=;

%local macro parmerr found format where dsid rc;
%local libname memname objname fmtname fmttype;  %* call set macro variables ;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(FORMAT,       _req=1,_words=0)

%if (&parmerr) %then %goto quit;

%let found=0;

%if (%sysfunc(indexc(&format,$,#))) %then %do;
   %let format = %sysfunc(compress(&format,#));
   %let where=fmtname eq "%upcase(&format)";
%end;
%else
   %let where=objname eq "%upcase(&format)";

%if (&catalog ne ) %then %do;
   %let where=&where and libname eq "%upcase(%scan(&catalog,1,%str(.)))";
   %let where=&where and memname eq "%upcase(%scan(&catalog,2,%str(.)))";
%end;

%*put &where;

%let dsid=%sysfunc(open(sashelp.vformat (where=(&where)),i));
%if (&dsid) %then %do;
   %syscall set(dsid);
   %let rc=%sysfunc(fetch(&dsid));
   %do %while (&rc eq 0);
      %let found = %eval(&found+1);

      %if (%index(&fmtname,$)) %then %do;
         %if (&fmttype eq F) %then
            %let fmttype = FORMATC;
         %else
            %let fmttype = INFMTC;
      %end;
      %else %do;
         %if (&fmttype eq F) %then
            %let fmttype = FORMAT;
         %else
            %let fmttype = INFMT;
      %end;

      %let fmtlist = &fmtlist %sysfunc(catx(.,&libname,&memname,&fmtname,&fmttype));
      %let rc=%sysfunc(fetch(&dsid));

      %*put found=&found rc=&rc libname=&libname memname=&memname fmtname=&fmtname fmttype=&fmttype;
   %end;
%end;
%let dsid=%sysfunc(close(&dsid));

&found

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
