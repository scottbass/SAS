/*=====================================================================
Program Name            : get_data_attr.sas
Purpose                 : Function style macro to return a dataset
                          attribute.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 09MAY2011
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

* create test dataset ;
data class (label="My Dataset Label");
   set sashelp.class;
run;

* introduce a time delay between creation and modification date ;
data _null_;
   rc=sleep(10);
run;

* now modify the dataset ;
data class;
   modify class;
   replace;
run;

%put %get_data_attr(class,label);
%put %sysfunc(putn(%get_data_attr(class,crdte),datetime.));
%put %sysfunc(putn(%get_data_attr(class,modte),datetime.));

%let crdte=%get_data_attr(class,crdte);
%put &crdte;
%put %sysfunc(datepart(&crdte),date.);
%put %sysfunc(timepart(&crdte),time.);

-----------------------------------------------------------------------
Notes:

I have used positional rather than keyword parameters since positional
parameters are much more natural and easier to remember for this
function-style macro.

---------------------------------------------------------------------*/

%macro get_data_attr
/*---------------------------------------------------------------------
Function style macro to return a dataset attribute.
---------------------------------------------------------------------*/
(DATA          /* Input dataset or view (REQ).                       */
,ATTR          /* Desired dataset attribute (REQ).                   */
               /* Either numeric or character attributes can be      */
               /* specified.  See code for valid attributes.         */
);

%local macro parmerr dsname attr_type return;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)
%parmv(ATTR,         _req=1,_words=0,_case=U,_val=

/* Numeric Attributes */
ALTERPW
ANOBS
ANY
VAROBS
ARAND
RANDOM
ARWU
AUDIT
AUDIT_DATA
AUDIT_BEFORE
AUDIT_ERROR
CRDTE
ICONST
INDEX
ISINDEX
ISSUBSET
LRECL
LRID
MAXGEN
MAXRC
MODTE
NDEL
NEXTGEN
NLOBS
NLOBSF
NOBS
NVARS
PW
RADIX
READPW
TAPE
WHSTMT
WRITEPW

/* Character Attributes */
CHARSET
ENCRYPT
ENGINE
LABEL
LIB
MEM
MODE
MTYPE
SORTEDBY
SORTLVL
SORTSEQ
TYPE
)

%if (&parmerr) %then %goto quit;

%* parse off any dataset options ;
%let dsname=%scan(%superq(data),1,%str(%());

%* additional error checking ;
%* does the dataset exist? ;
%if (^%sysfunc(exist(&dsname,data)) and ^%sysfunc(exist(&dsname,view))) %then %do;
   %parmv(_msg=&dsname does not exist)
   %goto quit;
%end;

%if (&parmerr) %then %goto quit;

%* but open the dataset with all specified options (esp. where clause) ;
%let dsid=%sysfunc(open(%superq(data)));

%* was the open successful? ;
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open %superq(data) dataset or view)
   %goto quit;
%end;

%* retrieve the desired attribute ;
%if (%sysfunc(indexw(
ALTERPW
ANOBS
ANY
VAROBS
ARAND
RANDOM
ARWU
AUDIT
AUDIT_DATA
AUDIT_BEFORE
AUDIT_ERROR
CRDTE
ICONST
INDEX
ISINDEX
ISSUBSET
LRECL
LRID
MAXGEN
MAXRC
MODTE
NDEL
NEXTGEN
NLOBS
NLOBSF
NOBS
NVARS
PW
RADIX
READPW
TAPE
WHSTMT
WRITEPW
,&attr
))) %then %let attr_type=N;
%else
%if (%sysfunc(indexw(
CHARSET
ENCRYPT
ENGINE
LABEL
LIB
MEM
MODE
MTYPE
SORTEDBY
SORTLVL
SORTSEQ
TYPE
,&attr
))) %then %let attr_type=C;

%let return=%sysfunc(attr&attr_type(&dsid,&attr));
%let dsid=%sysfunc(close(&dsid));

%unquote(&return)

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
