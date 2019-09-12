/*=====================================================================
Program Name            : attrib.sas
Purpose                 : Generate attrib statements from a template
                          dataset
SAS Version             : SAS 9.4
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 31MAR2016
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

data _null_;
   %attrib(sashelp.class)
   
   %attrib(sashelp.cars,keep=make model enginesize horsepower doesnotexist)
   
   %attrib(sashelp.shoes,drop=product stores returns doesnotexist)
run;

Displays attrib statements for sashelp.class, sashelp.cars, and 
sashelp.shoes, honoring the keep and drop parameters.

Note that a non-existant variable is silently ignored on a drop or
keep parameter.

=======================================================================

* dummy long formats ;
proc format;
   value $ffffffffffgggggggggghhhhhhhhhhx
      other=[$200.]
   ;
   invalue $iiiiiiiiiijjjjjjjjjjkkkkkkkkkk
      other=_same_
   ;
run;

data template / view=template;
   set sashelp.shoes;
   attrib 
      longvar 
      length=$32767 
      format=$ffffffffffgggggggggghhhhhhhhhhx9.
      informat=$iiiiiiiiiijjjjjjjjjjkkkkkkkkkk9.
      label="This is the label"
   ;
   keep _character_;
   stop;
run;

data _null_;
   %attrib(template);
run;

Variable lists are not supported by this macro.  If you wish to use
variable lists, first create a template view of the desired dataset.

=======================================================================

%attrib(sashelp.shoes,show=Y)
%attrib(sashelp.cars,show=Y,keep=make model enginesize horsepower doesnotexist)
%attrib(sashelp.shoes,show=Y,drop=product stores returns doesnotexist)
%attrib(template,show=Y)

Echos the structure of the dataset, i.e. the generated attrib statements,
to the log, without actually generating attrib statements.

Similar to the data _null_ step above, but does not require MPRINT to
be turned on.

-----------------------------------------------------------------------
Notes:

In a "old style" data step, the following constructs are often used to
achieve similar end results to this macro:

data whatever;
   if 0 then set template_dataset (drop= or keep=);
   ...
run;

or

data whatever;
   set template_dataset (obs=0) source_dataset;
   ...
run;

However, there are (at least) two issues:

1) There is an implicit retain of all data set variables.  If the 
template dataset is defining the attributes of a derived variable,
this can be problematic and sometimes results in hard-to-track down
bugs.

2) In PROC DS2, the data source can be either a data set or a FedSQL
query.  Often the template data set requires the (locktable=share) 
data set option or other problems can occur.

The different syntax of PROC DS2 can make the use of a template 
dataset problematic.

This macro can also be handy if you just want to quickly display
the structure of a dataset to the log:

%attrib(sashelp.zipcode,show=Y)

If show=Y the log will display better with options ls=max;
so that the long log lines do not wrap.

It's also possible to cut-and-paste these lines to another program
to easily duplicate the structure of the template dataset.

I have chosen to design this macro so that the SHOW functionality
inserts whitespace in order to line up the 
length/format/informat/label data.  

I believe this makes the data easier to skim in the log, but it may not
be your preferred approach, say when cut-and-pasting this into another
program.

A potential workaround is to cut-and-paste the MPRINT output.  The
macro tokenizer will parse out the extra whitespace, and echo these
results to the SAS log.  These results are the actual code that the SAS
compiler receives from the macro tokenizer.

Press Alt-LMB to block copy MPRINT text within EG and the SAS editor.

---------------------------------------------------------------------*/

%macro attrib
/*---------------------------------------------------------------------
Generate attrib statements from a template dataset.
---------------------------------------------------------------------*/
(DATA          /* Template dataset or view (REQ).                    */
               /* Data set options are not supported.                */
,KEEP=         /* Space separated list of variables to keep (Opt.)   */
               /* Case-insensitive.  Non-existent variables are      */
               /* silently ignored.  Variable lists not supported.   */
,DROP=         /* Space separated list of variables to drop (Opt.)   */
               /* Case-insensitive.  Non-existent variables are      */
               /* silently ignored.  Variable lists not supported.   */
,SHOW=N        /* Display the dataset attributes without actually    */
               /* generating executable attrib statements? (Opt.)    */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr;
%local attrib name type length format informat label varlist;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0,_case=N)
%parmv(KEEP,         _req=0,_words=1,_case=U)
%parmv(DROP,         _req=0,_words=1,_case=U)
%parmv(SHOW,         _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* parse off any dataset options ;
%let pos=%index(&data,%str(%());
%if (&pos) %then %let data=%substr(&data,1,&pos-1);

%* does the dataset or view exist? ;
%if not (%sysfunc(exist(&data,data)) or %sysfunc(exist(&data,view))) %then %do;
   %parmv(_msg=&data does not exist.);
   %goto quit;
%end;

%* initialize varlist ;
%let varlist=;

%let dsid=%sysfunc(open(&data,i));
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open &data);
   %goto quit;
%end;
%let numvars=%sysfunc(attrn(&dsid,nvars));
%do i=1 %to &numvars;
   %let name      =%sysfunc(varname(&dsid,&i));
   %let type      =%sysfunc(vartype(&dsid,&i));
   %let length    =%sysfunc(varlen(&dsid,&i));
   %let format    =%sysfunc(varfmt(&dsid,&i));
   %let informat  =%sysfunc(varinfmt(&dsid,&i));
   %let label     =%sysfunc(varlabel(&dsid,&i));

   %* use a marker token (~) to preserve spacing by the macro tokenizer ;
   %let name=~%sysfunc(putc(&name,$32.))~;

   %let length=length=$%sysfunc(putn(&length,6.-R));
   %if (&type eq N) %then
   %let length=%sysfunc(translate(&length,%str( ),%str($)));
   %let length=~&length~;

   %if (&format ne ) %then
   %let format=~format=%sysfunc(putc(&format,$35.))~;
   %else
   %let format=~       %sysfunc(repeat(%str( ),34))~;

   %if (&informat ne ) %then
   %let informat=~informat=%sysfunc(putc(&informat,$35.))~;
   %else
   %let informat=~         %sysfunc(repeat(%str( ),34))~;

   %if (%superq(label) ne ) %then
   %let label=label="&label";

   %* use a diffent marker token for the label, ;
   %* since a valid label can contain ~ ;
   %let attrib=attrib;
   %let attrib=&attrib&name&length&format&informat#####;
   %let attrib=%sysfunc(translate(&attrib,%str( ),%str(~)));
   %let attrib=%sysfunc(strip(&attrib))&label;
   %let attrib=%sysfunc(transtrn(&attrib,%str(#####),));

   %* remove ~ from name for varlist processing ;
   %let name=%sysfunc(translate(&name,%str( ),%str(~)));
   %let name=%left(&name);
   
   %if (&keep ne ) %then %do;
      %if (%index(&keep,%upcase(&name))) %then %do;
         %if (&show) %then %do;
            %put %str(&attrib;);
         %end;
         %else %do;
            &attrib;
            %let varlist=&varlist &name;
         %end;
      %end;
   %end;
   %else
   %if (&drop ne ) %then %do;
      %if ^(%index(&drop,%upcase(&name))) %then %do;
         %if (&show) %then %do;
            %put %str(&attrib;);
         %end;
         %else %do;
            &attrib;
            %let varlist=&varlist &name;
         %end;
      %end;
   %end;
   %else %do;
      %if (&show) %then %do;
         %put %str(&attrib;);
      %end;
      %else %do;
         &attrib;
         %let varlist=&varlist &name;
      %end;
   %end;
%end;
%if ^(&show) %then %do;
call missing(of &varlist);  %* prevents uninitialized variable messages ;
%end;

%quit:
%let dsid=%sysfunc(close(&dsid));

%mend;

/******* END OF FILE *******/
