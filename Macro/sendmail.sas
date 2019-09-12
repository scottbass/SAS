/*=====================================================================
Program Name            : sendmail.sas
Purpose                 : Macro to send an email using a metadata dataset
SAS Version             : SAS 9.1.3
Input Data              : Dataset containing email text
Output Data             : Email sent to desired recipients

Macros Called           : parmv, seplist

Originally Written by   : Scott Bass
Date                    : 12MAR2008
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
Date                    : 22NOV2013
Change/reason           : Changed to make email dataset optional in
                          order to send "subject only" emails.
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* specify message only, other options are macro parameters ;
data mail;
   length parm $15 line $1000;
   infile datalines dsd dlm="|" truncover;
   input parm line;
   datalines;
| Dear Support
|
| Job foo failed.
| See bar for details.
| Test of &sysprocessid..
;
run;

%sendmail(
  to=&sysuserid
  ,subject=%str(This is the subject as of &sysdate and &systime)
)

=======================================================================

* specify all parameters in the metadata dataset ;
%let job=My Job;
data mail;
   length parm $15 line $1000;
   infile datalines dsd dlm="|" truncover;
   input parm line;
   datalines;
TO       | jack@sas.com^jill@sas.com
CC       | Joe User <joe@sas.com>
CC       | Jane User <jane@sas.com>
FROM     | Real Name <real.name@sas.com>
SUBJECT  | Job &job failed at %sysfunc(date(),date7.) %sysfunc(time(),time5.)
ATTACH   | "%sysfunc(pathname(fileref_to_error_log))"
         | Dear Support
         |
         | Job foo failed.
         | See bar for details.
         | Date &sysdate Time &systime..
;
run;

%sendmail;

=======================================================================

* send a "subject only" email without any email message ;
%sendmail(
  metadata=_null_
  ,to=&sysuserid
  ,subject=%str(This is the subject as of &sysdate and &systime)
)

-----------------------------------------------------------------------
Notes:

The end user is responsible for specifying correct parameters for the
macro.  Little error checking is done.

See http://support.sas.com/onlinedoc/913/getDoc/en/lrdict.hlp/a002058232.htm
for documentation on parameter syntax.

To send a "subject only" email with no email message, specify
METADATA=_null_ for the metadata dataset parameter.

Parameters can be specified as macro parameters, or included in the
metadata dataset.  If included in the metadata dataset, the names
must match the macro variables in the macro parameters.  The names are
case insensitive.  If both macro parameter and metadata parameters are
specified, the metadata parameters take precedence.

To, Cc, and Bcc parameters should be separated with a caret (^), since
they can contain spaces.  Do not add any syntax (eg. quotation marks),
the macro will take care of this.

To, Cc, Bcc, and Attach can be specified all on one line, or on separate lines.
If on separate lines, they will be concatenated into the appropriate
addressee or attachment list.

For the remaining parameters, if specified multiple times, the last
parameter specified will be used.

At a minimum, the text of the email must be included in the metadata
dataset.  The parm variable should be missing for the text of the email.
Make sure the line variable is long enough to contain *resolved* macro
variable references without data truncation.

Macro variable references in the metadata dataset are resolved at macro
run time.
---------------------------------------------------------------------*/

%macro sendmail
/*---------------------------------------------------------------------
Macro to send an email using a metadata dataset
---------------------------------------------------------------------*/
(METADATA=mail /* Metadata dataset (REQ).                            */
,TO=           /* To addressee (Opt).                                */
,CC=           /* Cc addressee (Opt).                                */
,BCC=          /* Bcc addressee (Opt).                               */
,FROM=
               /* From addressee (Opt).                              */
,REPLYTO=      /* Reply-to addressee (Opt).                          */
,SUBJECT=      /* Subject (Opt).                                     */
,ATTACH=       /* Attachment (Opt).                                  */
,CONTENT_TYPE= /* Content type (Opt).                                */
,ENCODING=     /* Encoding (Opt).                                    */
);

%local macro parmerr metadata_exists;

%* check input parameters ;
%let macro = &sysmacroname;
%parmv(METADATA,     _req=1,_words=0,_case=U)

%if (&parmerr) %then %goto quit;

%let metadata_exists=%sysfunc(exist(&metadata));

%* create macro variables from the metadata dataset, ;
%* overwriting any parameters passed in as macro parameters ;
%let options=%sysfunc(getoption(serror));
%if (&metadata_exists) %then %do;
  options noserror;
  data _null_;
     set &metadata end=eof;
     where parm is not missing;
     length to cc bcc attach $10000;  /* adjust length as desired, but make long enough for resolved values */
     retain to cc bcc attach;
     select(upcase(parm));
        when("TO")     to       = catx("^",to,       line);
        when("CC")     cc       = catx("^",cc,       line);
        when("BCC")    bcc      = catx("^",bcc,      line);
        when("ATTACH") attach   = catx("^",attach,   line);
        when("FROM","REPLYTO","SUBJECT","CONTENT_TYPE","ENCODING")
           call symputx(parm,line);
        otherwise do;
           put "ERR" "OR: " parm "is an invalid parameter.";
           call symputx("parmerr",1);
           stop;
        end;
     end;
     if eof then do;
        if length(to)     then call symputx("TO",     to);
        if length(cc)     then call symputx("CC",     cc);
        if length(bcc)    then call symputx("BCC",    bcc);
        if length(attach) then call symputx("ATTACH", attach);
     end;
  run;
%end;

%if (&parmerr) %then %goto quit;

%* error checking ;
%parmv(TO,           _req=1,_words=1,_case=N)

%if (&parmerr) %then %goto quit;

%* issue filename statement ;
filename email email
   %let temp = %seplist(&to,nest=QQ,indlm=^,dlm=%str( ));
   to=(&temp)

%if (%superq(cc) ne ) %then %do;
   %let temp = %seplist(&cc,nest=QQ,indlm=^,dlm=%str( ));
   cc=(&temp)
%end;

%if (%superq(bcc) ne ) %then %do;
   %let temp = %seplist(&bcc,nest=QQ,indlm=^,dlm=%str( ));
   bcc=(&temp)
%end;

%if (%superq(subject) ne ) %then %do;
   subject="&subject"
%end;

%if (%superq(from) ne ) %then %do;
   from="&from"
%end;

%if (%superq(replyto) ne ) %then %do;
   replyto="&replyto"
%end;

%if (%superq(attach) ne ) %then %do;
   %let temp = %seplist(&attach,nest=QQ,indlm=^,dlm=%str( ));
   attach=(&temp)
%end;

%if (%superq(content_type) ne ) %then %do;
   content_type="&content_type"
%end;

%if (%superq(encoding) ne ) %then %do;
   encoding="&encoding"
%end;
;

%* now send the email ;
data _null_;
   file email;
/*   file print; */  /* for debugging */
   %if (&metadata_exists) %then %do;
   set &metadata;
   where parm is missing;
   line = resolve(line);
   put line;
   %end;
run;

filename email clear;
options &options;

%quit:
%mend;

/******* END OF FILE *******/

