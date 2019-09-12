/*=====================================================================
Program Name            : get_parameters.sas
Purpose                 : Get global and optional job-specific
                          parameters (macro variables) from a
                          specially structured metadata dataset
SAS Version             : SAS 9.1.3
Input Data              : METADATA= macro parameter
Output Data             : Various metadata parameters (macro variables)

Macros Called           : parmv, seplist, dump_mvars

Originally Written by   : Scott Bass
Date                    : 01FEB2007
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
Date                    : 11DEC2009
Change/reason           : Added support for multiple filters via
                          pipe(|) character plus metadata dataset
                          options (eg. where clause)
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 15FEB2010
Change/reason           : Added clear= parameter
Program Version #       : 1.2

Programmer              : Scott Bass
Date                    : 17MAY2011
Change/reason           : Added resolve= and symboltable= parameters
Program Version #       : 1.4

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* CREATE SAMPLE METADATA ;

* delete all global macro variables ;
proc sql noprint;
   select name into :_mvars_ separated by " "
   from dictionary.macros
   where scope="GLOBAL" and name not like 'SYS%';
quit;
%symdel &_mvars_ _mvars_ / nowarn;
%put _global_;

* create sample metadata dataset ;
data
   work.parameters
   work.mymetadata
   ;
   length Filter $50 Required $1 Name $32 Value $200;
   infile datalines dlm="|";
   input Filter Required Name Value;
   datalines4;
GLOBAL   | Y   |  PARM1       | This is parm 1
GLOBAL   | N   |  PARM2       | Parm 2 references Parm 3 which does not exist yet --> &parm3
GLOBAL   | Y   |  PARM3       | Parm 3 contains embedded runtime Parm 1 --> &parm1
GLOBAL   | N   |  BASE        | /proj/001/b123456
GLOBAL   | Y   |  RUNTIME     | Embedded function style macro:  %sysfunc(datetime(),datetime.)
GLOBAL   | N   |  PROT        | 1234
GLOBAL   | Y   |  DOMAIN      | AE
GLOBAL   | N   |  MISSING1    | .
GLOBAL   | N   |  MISSING2    | .
SDTM     | Y   |  SDTM1       | This is SDTM parm 1
SDTM     | N   |  PARM2       | SDTM parm 2 overrides GLOBAL parm 2
LISTINGS | Y   |  LISTINGS1   | This is LISTINGS parm 1
AE       | Y   |  PARM1       | This is the AE domain and overrides GLOBAL Parm 1
LB       | Y   |  PARM1       | This is the LB domain and overrides GLOBAL Parm 1
JOB XXX  | N   |  JOB1        | This is JOB XXX parm 1
JOB XXX  | N   |  PARM1       | This is JOB XXX parm 1 and overrides GLOBAL and DOMAIN Parm 1
;;;;
run;

* NOTE:  For all these use cases, I have to explictly specify ;
* the _metadata parameter.  The default location for metadata ;
* is meta.parameters ;

-----------------------------------------------------------------------

* return global parameters ;
%get_parameters(_metadata=work.parameters)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return only non-missing global parameters ;
%get_parameters(_metadata=work.parameters,_missing=N)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return global and SDTM parameters ;
%get_parameters(SDTM,_metadata=work.parameters)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return global, LISTINGS, and DOMAIN-specific parameters ;
%get_parameters(LISTINGS^AE,_metadata=work.parameters)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

%get_parameters(LISTINGS^LB,_metadata=work.parameters)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return global, LISTINGS, DOMAIN, and job-specific parameters ;
%let jobname=JoB xXx;  * spaces are allowed in filters, filter is case-insensitive ;
%get_parameters(LISTINGS^AE^&jobname,_metadata=work.parameters)
%symdel jobname;
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

%get_parameters(LISTINGS^LB^&jobname,_metadata=work.parameters)
%symdel jobname;
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return GLOBAL, LISTINGS, and job-specific parameters ;
* where additional Filters Required="Y" and 1=1 and 2=2 ;
* from the work.mymetadata parameters dataset ;

* both macro invocations return the same results ;
%get_parameters(LISTINGS^Job XXX | Required="Y" | 1=1 | 2=2, _metadata=work.mymetadata)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

%get_parameters(LISTINGS^Job XXX | Required="Y" and 1=1 and 2=2, _metadata=work.mymetadata)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return global parameters where NAME in (BASE, PROT, DOMAIN) ;
* either spaces or carets (^) can be used to delimit name= parameters ;
%get_parameters(_name=base prot^domain,_metadata=work.parameters)
%put _global_;  * previous macro variables are cleared out ;
%dump_mvars(&_parameters_)

=======================================================================

* return global parameters where NAME=BASE, but do not clear previous variables ;
%get_parameters(SDTM^LISTINGS^JOB XXX,_metadata=work.parameters); * sets all metadata macro variables ;
%let base=BLAH;  * pretend &base was set on a previous invocation ;
%put _global_;
%get_parameters(_name=base,clear=no,_metadata=work.parameters)  * &base is correct, but all other macro variables are untouched ;
%put _global_;
%dump_mvars(&_parameters_)

=======================================================================

* do not resolve embedded macro variables (GLOBAL --> PARM3 contains embedded macro variable reference);
%get_parameters(_resolve=N,_metadata=work.parameters)

* these were all set from the parameters dataset ;
* now that %get_parameters has completed, they all resolve correctly ;
%put parm1=&parm1;
%put parm2=&parm2;
%put parm3=&parm3;

=======================================================================

* but the embedded macro variable references still remain unresolved ;
%let parm1=foo;  * say this is set at runtime by a calling program ;
%put parm3=&parm3;  * now parm 3 has a new value, since &parm1 is still embedded in parm 3 ;

%symdel parm3 / nowarn;
%put parm2=&parm2;  * and so does parm 2 - this should give an unresolved macro variable warning ;

=======================================================================

* create macro variables in the most local symbol table ;
* valid values are G, L, and F ;
* Note:  L is allowed, but rather useless, since the macro variables created will be local ;
* to %get_parameters.  The macro variables will be out of scope (i.e. deleted) when %get_parameters ends ;
* see documentation for CALL SYMPUTX for details ;
%macro test;
   %local parm1 parm2 parm3;  %* try running this without declaring the macro variables first ;
   %get_parameters(_symboltable=F,_metadata=work.parameters)
   proc sql;
      select * from dictionary.macros where scope="&sysmacroname";
   quit;
   %dump_mvars(parm1 parm2 parm3)
%mend;
%test;
%dump_mvars(parm1 parm2 parm3);  * but not in the global symbol table ;

-----------------------------------------------------------------------
Notes:

I would prefer not to have to prefix all the macro parameters with an
underscore.  However, I cannot globalize any local macro variables,
which includes the parameters.  Prefixing the macro parameters with an
underscore reduces the likelihood of a local/global macro variable name
collision.

You must use a caret (^) as the delimiter between filter and name
tokens, since the filter can contain spaces.

You can specify multiple "levels" of filters by separating them with
the pipe (|) symbol.  The second and subsequent filters are added to
the initial filter using the AND operator.

The filter can be any string, but typically would be:
GLOBAL (optional), a grouping parameter encompassing several programs
(i.e. STDM, INTERVENTION, EXCEPTIONS, TABLES, LISTINGS, etc), and
job name (&jobname).  The filter must be synchronised with the filter
column in metadata.parameters.

The data in meta.parameters should be sorted from most general
(GLOBAL) to most specific (jobname).  If any variables are repeated,
the last one occurring has precedence.  So, you want a job-specific
parameter to override a global parameter.

meta.parameters can be a datastep view which reads from an external
file.  This is useful when reading a CSV external file, where Excel is
used to maintain the metadata (and saved as a CSV).

The filter is case-insensitive, but otherwise must be identical to the
filter string in metadata.parameters, eg. spaces between words are
significant.  Be especially aware that renaming the job will break
the linkage between the filter value in metadata.parameters and
&jobname.

If the Name column in the metadata dataset contains any macro variable
references (i.e. dynamically derived macro variable names), the calling
code needs to declare those variables via %global macrovariable before
calling this macro.

If you want embedded macro variables to remain unresolved in the
returned macro variables, set RESOLVE=N.  This allows you to embedded
macro variables in the metadata, which are set later during runtime.

---------------------------------------------------------------------*/

%macro get_parameters
/*---------------------------------------------------------------------
Get the global and optional metadata parameters
---------------------------------------------------------------------*/
(_FLTR         /* Filter used to limit the data returned (Opt).      */
               /* If not set, only GLOBAL parameters will be         */
               /* returned.                                          */
,_NAME=        /* Additional filter on name(s) (Opt).                */
               /* If not set, all named items matching the filter    */
               /* criteria will be returned.                         */
,_WHERE=       /* Additional free form where clause (Opt).           */
               /* If set, it must specify a valid where clause for   */
               /* the metadata dataset (without the "where" keyword) */
,_METADATA=meta.parameters
               /* Metatdata parameters dataset (REQ).                */
,_CLEAR=Y      /* Clear previous macro variables? (REQ).             */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
,_RESOLVE=Y    /* Resolve embedded macro variable references (REQ).  */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,_MISSING=Y    /* Set macro variables if value is missing? (REQ).    */
               /* If YES, macro variables are defined even if the    */
               /* value is missing.  If NO, only macro variables     */
               /* with non-missing data values are defined.          */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,_SYMBOLTABLE=G
               /* Create macro variables in the specified macro      */
               /* variable symbol table (REQ).                       */
               /* Default value is G (Global).                       */
               /* Valid values are G (Global), L (most local symbol  */
               /* table), and F (if found, create in the most local  */
               /* symbol table in which it exists, else in the most  */
               /* local symbol table).                               */
);

%global _parameters_;

%local macro parmerr _num_levels _temp _serror;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(_FLTR,        _req=0,_words=1)
%parmv(_NAME,        _req=0,_words=1,_case=U)
%parmv(_METADATA,    _req=1,_words=0)
%parmv(_CLEAR,       _req=1,_words=0,_case=U,_val=0 1)
%parmv(_RESOLVE,     _req=1,_words=0,_case=U,_val=0 1)
%parmv(_MISSING,     _req=1,_words=0,_case=U,_val=0 1)
%parmv(_SYMBOLTABLE, _req=1,_words=0,_case=U,_val=G L F)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* Does metadata parameters dataset exist? ;
%if ( (%sysfunc(exist(&_metadata,data)) ne 1) and
      (%sysfunc(exist(&_metadata,view)) ne 1) ) %then %do;
   %parmv(_msg=&_metadata dataset or view does not exist)
   %if (&parmerr) %then %goto quit;
%end;

%* parse the filter parameter ;
%* add end of string marker to properly process an empty filter string ;
%let _fltr=%str(&_fltr | ###);
%let _num_levels=1;
%let _temp=%scan(&_fltr,&_num_levels,%str(|));
%do %while (%quote(&_temp) ne %quote(###));
   %local _fltr&_num_levels;
   %let _fltr&_num_levels=&_temp;
   %let _num_levels=%eval(&_num_levels+1);
   %let _temp=%scan(&_fltr,&_num_levels,%str(|));
%end;
%let _num_levels=%eval(&_num_levels-1);

%* process the name parameter ;
%let _name = %upcase(%seplist(&_name,indlm=%str(^ ),nest=QQ));

%* if clear=yes, delete all possible macro variables ;
%if (&_clear) %then %do;
   * delete all previous macro variables ;
   %local _mvars_;
   %let _mvars_=1;
   proc sql noprint;
      select distinct name into :_mvars_ separated by " "
      from &_metadata
      where (^missing(name)) and (^notname(strip(name))) and (anydigit(strip(name)) ne 1)

      %do _i=1 %to &_num_levels;
         %if (&_i eq 1) %then
            and upcase(Filter) in (%seplist(%upcase(GLOBAL^&&_fltr&_i),indlm=%str(^),nest=QQ));
         %else
            and &&_fltr&_i;
      %end;

      %if (&_name ne ) %then
         and upcase(Name) in (&_name);

      %if (%superq(_where) ne ) %then
         and &_where;
     ;
   quit;
   %if (&_mvars_ ne ) %then %symdel &_mvars_ / nowarn;
%end;

%* now set the macro variables ;
%let _parameters_=;
%let _serror = %sysfunc(getoption(serror,keyword));
options noserror;
data _null_;
   set &_metadata end=eof;
   where

   %do _i=1 %to &_num_levels;
      %if (&_i eq 1) %then
         upcase(Filter) in (%seplist(%upcase(GLOBAL^&&_fltr&_i),indlm=%str(^),nest=QQ));
      %else
         and &&_fltr&_i;
   %end;

   %if (&_name ne ) %then
      and upcase(Name) in (&_name);

   %if (%superq(_where) ne ) %then
      and &_where;
   ;

   if (&_missing eq 0) then do;
      if missing(value) then do;
         link eof;
         return;
      end;
   end;

   %* Convert special characters from the Excel data ;
   %* Alt-Enter ("0A"x) and Paragraph Marks ("0D"x) become straight split characters ;
   %* Form Feed ("0B"x) become split characters + hanging indents ;
   %* Convert them to unresolved macro variable references, which get specified during later processing ;
   %* Convert "Smart quotes" to "normal" single and double quotes ;
%* rx1=prxparse('s/\x0A|x0D/&split./o');
%* rx2=prxparse('s/\x0B/&split.&hanging_indent/o');
   rx3=prxparse('s/\x{201C}|\x{201D}|\x{201E}/"/o');  %* "smart" double quotes ;
   rx4=prxparse("s/\x{2018}|\x{2019}/'/o");           %* "smart" single quotes ;

%* if prxmatch(rx1,value) then value=prxchange(rx1,-1,trim(value));
%* if prxmatch(rx2,value) then value=prxchange(rx2,-1,trim(value));
   if prxmatch(rx3,value) then value=prxchange(rx3,-1,trim(value));
   if prxmatch(rx4,value) then value=prxchange(rx4,-1,trim(value));

   drop rx1 rx2 rx3 rx4;

   if (&_resolve eq 1) then do;
      name  = resolve(name);
      value = resolve(value);
   end;

   length _parameters_ $32767;
   retain _parameters_;

   if (^missing(name)) and (^notname(strip(name))) and (anydigit(strip(name)) ne 1) then do;
      _parameters_=catx(" ",_parameters_,name);
      call symputx(name,trim(value),"&_symboltable");
   end;
   else do;
      putlog "USER NO" "TE: " name "is an invalid macro variable name and will not be created.";
   end;

   EOF:
   if (eof) then call symputx("_parameters_",_parameters_,"G");
run;
options &_serror;

%quit:

%mend;

/******* END OF FILE *******/
