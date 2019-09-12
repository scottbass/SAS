/*=====================================================================
Program Name            : symget.sas
Purpose                 : Get value for global macro variable that is
                          hidden by local macro variable.
SAS Version             : SAS 9.1.3
Input Data              : None
Output Data             : None

Macros Called           : parmv, seplist

Originally Written by   : Tom Abernathy (via SAS-L posting)
Date                    : 08APR2011
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

Based on original work by by Tom Abernathy of Pfizer Pharmaceuticals 
in reply to a posting I made to the SAS-L listserver.
Used with permission.

=======================================================================

Modification History    :

Programmer              : Scott Bass
Date                    : 08APR2011
Change/reason           : This macro was supplied by Tom Abernathy of
                          Pfizer Pharmaceuticals in reply to a posting I
                          made to the SAS-L listserver.  I've edited it
                          slightly.  Macro used with permission from Tom
                          Abernathy.
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%* Allow Global Macro Variable (GMV) to serve as default value ;
%local mvar;
%if %bquote(&MVAR)= %then %let mvar=%symget(mvar);

%* Allow both GMV and parameter style macro calls ;
%macro aesumm(dsin=,dsut=,sev=);
   %local macro;
   %let macro=&sysmacroname;
   %if %bquote(&dsin=) %then %let dsnin=%symget(dsnin,exclude=&macro);
   %if %bquote(&dsut=) %then %let dsnut=%symget(dsnut,exclude=&macro);
   %if %bquote(&sev=)  %then %let sev  =%symget(sev,  exclude=&macro);
   ....
%mend aesumm;

-----------------------------------------------------------------------
Notes:

- Default to finding GLOBAL macro variable.
- Set SYSRC=1 when macro variable not found.
- Macro will call itself recursively to eliminate extra trailing blanks
  pulled from SASHELP.VMACRO.

---------------------------------------------------------------------*/

%macro symget
/*---------------------------------------------------------------------
Get value for macro variable that is hidden by local macro variable
---------------------------------------------------------------------*/
(MVAR          /* Macro variable name                                */
,INCLUDE=      /* Space delimited list of macro scopes to search     */
,EXCLUDE=      /* Space delimited list of macro scopes to ignore     */
,RECURSE=N     /* Used internally by the macro                       */
);

%local macro parmerr did rc where scope name value offset;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(MVAR,         _req=1,_words=0,_case=N)
%parmv(INCLUDE,      _req=0,_words=1,_case=U)
%parmv(EXCLUDE,      _req=0,_words=1,_case=U)
%parmv(RECURSE,      _req=1,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%if (&recurse) %then %do;
%*----------------------------------------------------------------------
Open SASHELP.VMACRO and link dataset variables to macro variables.
If a match is found then expand VALUE as the result of the macro call.
Loop until all observations are read or OFFSET=0 indicates that the
start of another instance of the same variable has begun.
Close SASHELP.VMACRO.
-----------------------------------------------------------------------;
   %let where=%upcase(name="&mvar" and scope="&include");
   %let did=%sysfunc(open(sashelp.vmacro(where=(&where))));
   %syscall set(did);
   %if 0=%sysfunc(fetch(&did)) %then %do;
      %do %until(%sysfunc(fetch(&did)) or 0=&offset);&value.%end;
   %end;
   %let rc=%sysfunc(close(&did));
%end;
%else
%if %bquote(&mvar)^= %then %do;
%*----------------------------------------------------------------------
Set scope to GLOBAL when no criteria specified. Exclude this macro.
Open the SASHELP.VMACRO and link dataset variables to macro variables.
Fetch first observation to get SCOPE and NAME. Close SASHELP.VMACRO.
-----------------------------------------------------------------------;
   %if %length(&include) %then
      %let where=scope in (%seplist(%upcase(&include),nest=QQ));
   %else
   %if 0=%length(&exclude) %then
      %let where=scope='GLOBAL';
   %else
      %let where=scope not in (%seplist(%upcase(&macro &exclude),nest=QQ));
   %let where=name="%upcase(&mvar)" and &where;
   %let did=%sysfunc(open(sashelp.vmacro(where=(&where))));
   %syscall set(did);
   %let rc=%sysfunc(fetch(&did));
   %let did=%sysfunc(close(&did));
   %if (0=&rc) %then %do;
%*----------------------------------------------------------------------
Found a variable so get value from recursive call to the macro.
Expand value as result of macro call.
-----------------------------------------------------------------------;
    %let value=%&macro(&name,include=&scope,recurse=Y);
&value.
  %end;
%end;

%*----------------------------------------------------------------------
Set SYSRC=1 to indicate macro variable not found.
-----------------------------------------------------------------------;
%let sysrc=%eval(%bquote(&name)=);

%quit:

%mend;