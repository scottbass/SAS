/*=====================================================================
Program Name            : fmtlist.sas
Purpose                 : Prints contents of one or more format or
                          informat entries.

SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : None

Macros Called           : parmv, seplist

Originally Written by   : Scott Bass
Date                    : 04JUL2005
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

Modification History    :

Programmer              : Scott Bass
Date                    : 18SEP2013
Change/reason           : Complete rewrite of macro based on features
                          available in SAS 9.3
Program Version #       : 1.1


=====================================================================*/

/*---------------------------------------------------------------------
Usage:

proc format lib=work.formats;
  value $chrfmt       "A"="A";
  value numfmt         2 ="B";
  invalue $chrinfmt   "C"="C";
  invalue numinfmt    "D"=4;
run;

%fmtlist()
   Lists all formats in the fmtsearch path.

%fmtlist(doesnotexist)
   Prints a message to the log since no formats match the filter.

%fmtlist(.*fmt doesnotexist)
   Lists all formats in the fmtsearch path
   with name ending in "fmt".
   Note that non-existent format names are silently ignored.

%fmtlist(age.* .*desc .*current.* assid branch)
   Lists all formats in the fmtsearch path
   with name beginning with "age",
   or ending with "desc",
   or containing the word "current",
   or exactly named "assid" or "branch"

%fmtlist(catalog=doesnot.exist)
   Prints a message to the log since no formats match the filter.

%fmtlist(catalog=apfmtlib.formats work.formats doesnot.exist)
   Lists all formats in the apfmtlib.formats or work.formats catalogs,
   if those catalogs are in the fmtsearch path.
   Note that non-existent format catalogs are silently ignored.

%fmtlist(catalog=work.formats)
   Lists all formats in the work.formats catalog,
   if that catalog is in the fmtsearch path.

%fmtlist(catalog=work.formats, type=CF NF)
  Lists all >>>character formats<<< and >>>numeric formats<<<
  from the work.formats catalog.

%fmtlist(type=NF NI)
  Lists all >>>numeric formats<<< and >>>numeric informats<<<
  in the fmtsearch path.

%fmtlist(catalog=work.formats,details=Y)
  Prints the DETAILS of all formats in the work.formats catalog,
  rather than just listing their names,
  if that catalog is in the fmtsearch path.

%fmtlist(age.*des chr.*,catalog=meta.formats work.formats,details=Y)
  Prints the DETAILS of formats with names beginning with "age*des" or "chr",
  in the meta.formats and work.formats catalogs,
  if those catalogs are in the fmtsearch path.

-----------------------------------------------------------------------
Notes:

This macro uses the metadata from the dictionary.formats view.
This dictionary view only lists (built-in and) user-defined formats that
are in the current fmtsearch path.  Therefore, only user-defined formats
in the current fmtsearch path are listed or printed.  This is acceptable,
since these are the only formats available.

By default, this macro lists format names in the output destination.
Specify DETAILS=Y to print the format details in the output destination.

The format list uses Perl Regular Expression (PRX) format to filter
the output (vs. say SQL LIKE syntax).  Each token is bound by the
word break metacharacter (\b) to prevent "false hits" on the filter.

In particular, the wildcard for "all characters" is "dot-asterisk" (.*),
not just asterisk.

See this link (or Google "Perl Regular Expressions") for more details:
http://support.sas.com/documentation/cdl/en/lefunctionsref/64814/HTML/default/viewer.htm#p0s9ilagexmjl8n1u7e1t1jfnzlk.htm

Specify multiple format names and/or wildcards as a space separated list.
The PRX "or" operator (|) will be added by the macro.

Specify the CAT= parameter to limit the search to a single catalog in
the fmtsearch path.  Otherwise, all format catalogs are searched.

Specify the TYPE= parameter to limit the search to one or more format
types:

   CF=Character Format      (Accepts character input, returns character output)
   NF=Numeric Format        (Accepts numeric input, returns character output)
   CI=Character Informat    (Accepts character input, returns character output)
   NI=Numeric Informat      (Accepts character input, returns numeric output)

----------------------------------------------------------------------*/

%macro fmtlist
/*---------------------------------------------------------------------
Prints contents of one or more format or informat entries
---------------------------------------------------------------------*/
(LIST          /* List of one or more formats or informats (Opt).    */
               /* If not specified, all formats are printed.         */
               /* Specify wildcards using PRX format, as a           */
               /* space-separated list.                              */
,CATALOG=      /* Format catalog(s) to search (Opt).                 */
               /* If not specified, uses the current value of the    */
               /* FMTSEARCH option to locate the format entry.       */
               /* If specified, use a space-separated list of        */
               /* catalogs in the fmtsearch path to limit the search */
               /* to only those catalogs.                            */
,TYPE=         /* Filter output to specified format type(s) (Opt).   */
               /* If not specified, all format types are listed.     */
               /* Valid values are CF, NF, CI, and NF.               */
,DETAILS=N     /* Print format details instead of just listing the   */
               /* format name? (Req.)                                */
               /* If N, only the format names are printed.           */
               /* If Y, the format details are printed.              */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr where temp flag;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(LIST,         _req=0,_words=1,_CASE=U)
%parmv(CATALOG,      _req=0,_words=1,_CASE=U)
%parmv(TYPE,         _req=0,_words=1,_CASE=U,_VAL=CF NF CI NI)
%parmv(DETAILS,      _req=1,_words=0,_CASE=U,_VAL=0 1)

%if (&parmerr) %then %goto quit;

%* build where clause ;
%let where=;
%if (%superq(list) ne ) %then %do;
  %let temp=%seplist(%superq(list),dlm=|,prefix=\b,suffix=\b);
  %let temp=%unquote(&temp);
  %let where=prxmatch("/&temp/io",objname);
%end;
%if (&catalog ne ) %then %do;
  %let temp=%seplist(&catalog,nest=qq);
  %let temp=%unquote(&temp);
  %if (%superq(where) ne ) %then %let where=&where and;
  %let where=&where catx(".",libname,memname) in (&temp);
%end;
%if (&type ne) %then %do;
  %let temp=%seplist(&type,nest=qq);
  %let temp=%unquote(&temp);
  %if (%superq(where) ne ) %then %let where=&where and;
  %let where=&where fmttype in (&temp);
%end;
%let where=%unquote(&where);
%let flag=%eval(%superq(where) ne );

%* Create view of all the user-defined formats in the current fmtsearch path ;
%if (not %sysfunc(exist(work.usrfmts,view))) %then %do;
proc sql;
  create view work.usrfmts as
    select
      libname,
      memname,
      objname,
      fmtname,
      cats(ifc(substr(fmtname,1,1)="$","C","N"),fmttype) as fmttype length=2
    from
      dictionary.formats
    where
      libname is not missing
    order by
      libname, memname
  ;
quit;
%end;

%* If just listing format names, output to print location ;
%if (not &details) %then %do;
  proc sql print;
    select
      *
    from
      work.usrfmts
    %if (&flag) %then %do;
    where
      &where
    %end;
    order by
      objname
    ;
  quit;
  %if (&sqlobs eq 0) %then %do;
    %put NOTE: No formats matching the filter were found in the fmtsearch path.;
    %goto quit;
  %end;
%end;

%* Ok, we want the format details, not just the format names ;
%* We need to process each format catalog in the fmtsearch path individually ;
%else %do;
  %* get a list of the format catalogs ;
  proc sql noprint;
    select distinct
      catx(".",libname,memname) into :fmtcats separated by " "
    from
      work.usrfmts
    %if (&flag) %then %do;
    where
      &where
    %end;
    ;
  quit;
  %if (&sqlobs eq 0) %then %do;
    %put NOTE: No format catalogs matching the filter were found in the fmtsearch path.;
    %goto quit;
  %end;

  %* Now loop over each format catalog ;
  %macro code;
    %let formats=;
    %if (&flag) %then %do;
      proc sql noprint;
        select
          cats(ifc(fmttype in ("CI","NI"),"@",""),fmtname) into :formats separated by " "
        from
          work.usrfmts
        where
          catx(".",libname,memname)="&word"
        %if (&flag) %then %do;
          and
          &where
        %end;
        order by
          objname
        ;
      quit;
      %if (&sqlobs eq 0) %then %do;
        %put NOTE: No formats matching the filter were found in the fmtsearch path.;
      %end;
    %end;
    %if (not &flag or &sqlobs ne 0) %then %do;
      %* Now call PROC FORMAT to print the format details ;
      title "&word";
      proc format lib=&word fmtlib page;
        %if (&formats ne ) %then %do;
        select &formats;
        %end;
      run;
      title;
    %end;
  %mend;
  %loop(&fmtcats)
%end;

%quit:
%mend;

/******* END OF FILE *******/
