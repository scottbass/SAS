/*=====================================================================
Program Name            : create_format.sas
Purpose                 : Create a format from an input dataset.
SAS Version             : SAS 9.1.3
Input Data              : Input Dataset
Output Data             : Formats

Macros Called           : parmv, kill, nobs

Originally Written by   : Scott Bass
Date                    : 23MAR2007
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

Programmer              : Scott Bass
Date                    : 30NOV2012
Change/reason           : Changed to use SPDEWORK library for better
                          performance
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 13JUL2016
Change/reason           : Added KEEP parameter 
Program Version #       : 1.2

=====================================================================*/

/*----------------------------------------------------------------------
Usage:

%create_format(
    DATA=WORK.FOO
   ,NAME=ABC_FMT
);

Create $ABC_FMT format in WORK.FORMATS catalog using WORK.FOO as input.
WORK.FOO should contain the variables START and LABEL.

=======================================================================

%create_format(
    DATA=WORK.FOO
   ,NAME=DEF_FMT
   ,TYPE=NUM_FORMAT
   ,START=START_VALUE
   ,END=END_VALUE
   ,LABEL=DESCR
   ,LIB=LIBRARY
   ,CAT=FORMATS
)

Create DEF_NUM format in LIBRARY.FORMATS catalog using WORK.FOO as input.
WORK.FOO should contain the variables START_VALUE, END_VALUE, and DESCR.

=======================================================================

%create_format(
    DATA=PERM.DATASET
   ,NAME=GHI_CHR
   ,TYPE=CHR_INFORMAT
   ,START=NAME
   ,LABEL=DESCR
   ,LIB=LIBRARY
   ,CAT=MYFORMAT
   ,OTHER=**UNKNOWN**
   ,WHERE=DATE gt "01JAN2007"d
)

Create GHI_CHR informat in LIBRARY.MYFORMAT catalog using PERM.DATASET as input.
Input data not matching any of the ranges should be coded to "**UNKNOWN**".
PERM.DATASET should contain the variables NAME and DESCR.
Only include records after 01JAN2007 in the format.

=======================================================================

%create_format(
    DATA=WORK.FOO
   ,NAME=cats("MY_",FMT)
   ,TYPE=CHR_FORMAT
)

Create multiple formats from input dataset WORK.FOO.
Create the formats in the default catalog (WORK.FORMATS).
The name of the format is contained in the variable FMT.
We want the format names to begin with MY_.
WORK.FOO should contain the variables START and LABEL.

------------------------------------------------------------------------
Notes:

If the input dataset contains data for multiple formats
(i.e. it contains data for the name of the format), then the format
name string should contain a left-parentheses.

For example:

(VAR):
   Would just use VAR as is from the input dataset.
   The parentheses are just a trigger to the macro to treat this
   as a code fragment.

cats("FOO_",VAR):
   Would append "FOO_" to the VAR variable in the input dataset.

Otherwise &NAME will be used as a hard-coded format name for the entire
input dataset.

Combining a code fragment for the format name with Other processing
will result in only the last format containing Other processing.

No error checking is done on the input parameters (other than checking
if required parameters are set).

The variables for VALUE and LABEL should be character or automatic type
conversion will result.

Except for START and LABEL, your input dataset should avoid using
variable names listed in the attrib statement below.  For example, if
your input dataset contained the variable PREFIX, and you used it for
the VALUE or LABEL parameters, your data would likely be truncated
giving undesired results.

The macro issues a warning if your input dataset contains overlapping
ranges.  You should pre-process your input dataset to circumvent this
warning.
----------------------------------------------------------------------*/

%macro create_format
/*---------------------------------------------------------------------
Create a format from an input table
---------------------------------------------------------------------*/
(DATA=
               /* Input dataset/view (REQ).                          */
               /* Should be a two-level name.                        */
,LIB=WORK
               /* Format library (REQ).                              */
               /* Library to which the format is written.            */
,CAT=FORMATS
               /* Format catalog (REQ).                              */
               /* Catalog to which the format is written.            */
,NAME=
               /* Format name (REQ).                                 */
               /* Either a hard coded name, or a code fragment       */
               /* (that could reference a variable in the            */
               /* input dataset/view.                                */
,TYPE=CHR_FORMAT
               /* Format type (REQ).                                 */
               /* Valid values are CHR_FORMAT, NUM_FORMAT,           */
               /* CHR_INFORMAT, NUM_INFORMAT.                        */
,START=START
               /* Starting value for the format (REQ).               */
               /* Variable containing the start value for the format */
,END=
               /* Ending value for the format (Opt).                 */
               /* Variable containing the end value for the format   */
,LABEL=LABEL
               /* Format label (REQ).                                */
               /* Variable containing the label for the format.      */
,DEFAULT=
               /* Specify the default length of the (in)format.      */
               /* If blank, PROC FORMAT determines the default       */
               /* length based on the maximum label length.          */
,MIN=
               /* Specify a minimum length for the (in)format (Opt). */
,MAX=
               /* Specify a maximum length for the (in)format (Opt). */
,FUZZ=
               /* Specify a fuzz factor for matching values to a     */
               /* range (Opt).                                       */
,OTHER=
               /* "Other" processing? (Opt).                         */
               /* If non-blank, input data not matching any defined  */
               /* ranges will be mapped to the "other" label.        */
               /* If value = _MISSING_, value is translated to the   */
               /* appropriate label for the format type.             */
,KEEP= 
               /* Additional variables to keep? (Opt)                */
               /* Used with where processing to keep additional      */
               /* variables used in the where claus.                 */
,WHERE=
               /* Where processing? (Opt).                           */
               /* If non-blank, only data matching the where clause  */
               /* will be included in the format.                    */
               /* Do not include the "where" keyword.                */
,DEDUP=Y
               /* Dedup the source dataset? (REQ).                   */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr keep;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(LIB,          _req=1,_words=0,_case=U)
%parmv(CAT,          _req=1,_words=0,_case=U)
%parmv(NAME,         _req=1,_words=0,_case=U)
%parmv(TYPE,         _req=1,_words=0,_case=U,_val=CHR_FORMAT NUM_FORMAT CHR_INFORMAT NUM_INFORMAT)
%parmv(START,        _req=1,_words=0,_case=U)
%parmv(END,          _req=0,_words=0,_case=U)
%parmv(LABEL,        _req=1,_words=0,_case=U)
%parmv(DEFAULT,      _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(MIN,          _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(MAX,          _req=0,_words=0,_case=U,_val=POSITIVE)
%parmv(FUZZ,         _req=0,_words=0,_case=U)
%parmv(DEDUP,        _req=1,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%let WHERE = %unquote(&WHERE);

libname _crtfmt_ spde "%sysfunc(pathname(work))" temp=yes;

%* I know I do not need all these attributes now, but I have left them in here ;
%* in case additional options are added to the macro in the future ;

%let cntlin=_crtfmt_._cntlin_;
data &cntlin;
   format FMTNAME TYPE START END LABEL;
   attrib
      FMTNAME     length=$32     label="Format name"
      START       length=$200    label="Starting value for format"
      END         length=$200    label="Ending value for format"
      LABEL       length=$5000   label="Format value label"
      TYPE        length=$1      label="Type of format"
/*
      MIN         length=3       label="Minimum length"
      MAX         length=3       label="Maximum length"
      DEFAULT     length=3       label="Default length"
      LENGTH      length=3       label="Format length"
      FUZZ        length=8       label="Fuzz value"
      PREFIX      length=$2      label="Prefix characters"
      MULT        length=8       label="Multiplier"
      FILL        length=$1      label="Fill character"
      NOEDIT      length=3       label="Is picture string noedit?"
      SEXCL       length=$1      label="Start exclusion"
      EEXCL       length=$1      label="End exclusion"
      HLO         length=$11     label="Additional information"
      DECSEP      length=$1      label="Decimal separator"
      DIGSEP      length=$1      label="Three-digit separator"
      DATATYPE    length=$8      label="Date/time/datetime?"
      LANGUAGE    length=$8      label="Language for date strings"
*/
   ;
   if _n_=1 then call missing(of _all_);

   %* if the format name or label contains a left parentheses, assume it is a code fragment ;
   %* otherwise it is a hard coded format name or label ;
   %if (%index(%superq(NAME),%str(%())) %then %do;
      %let NAME = &NAME;
      %let keep=&keep %sysfunc(compress(&NAME,%str(%(%))));
   %end;
   %else %do;
      %let NAME = "&NAME";
   %end;

   %if (&TYPE = CHR_FORMAT) %then
      %let type = C;
   %else
   %if (&TYPE = NUM_FORMAT) %then
      %let type = N;
   %else
   %if (&TYPE = CHR_INFORMAT) %then
      %let type = J;
   %else
   %if (&TYPE = NUM_INFORMAT) %then
      %let type = I;

   %let keep=&keep &START;
   %if (%superq(END) eq ) %then 
      %let END = &START;
   %else
      %let keep=&keep &END;

   %let keep=&keep &LABEL;

   set &DATA (keep=&keep) end=_last_;

   %if (%superq(WHERE) ne %str() ) %then %do;
      where &WHERE;
   %end;

   FMTNAME  = &NAME;
   TYPE     = "&type";
   START    = &START;
   END      = &END;
   LABEL    = &LABEL;

   %if (&default ne ) %then %do;
   DEFAULT  = &default;
   %end;

   %if (&min ne ) %then %do;
   MIN      = &min;
   %end;

   %if (&max ne ) %then %do;
   MAX      = &max;
   %end;

   %if (&fuzz ne ) %then %do;
   FUZZ     = &fuzz;
   %end;

   output;

   %if (%superq(OTHER) ne ) %then %do;
      if (_last_) then do;
         call missing(of START, END, LABEL, &START, &END, &LABEL);

         %if (%qupcase(%superq(OTHER)) eq _MISSING_) %then %do;
            %if (%sysfunc(indexc(&TYPE,CNJ))) %then %do;
               LABEL = " ";
            %end;
            %else %do;
               LABEL = .;
            %end;
         %end;
         %else %do;
            %if (%sysfunc(indexc(&TYPE,CNJ))) %then %do;
               LABEL = "&OTHER";
            %end;
            %else %do;
               LABEL = &OTHER;
            %end;
         %end;

         HLO   = "O";
         output;
      end;
   %end;

   /*
   keep
      FMTNAME
      START
      END
      LABEL
      MIN
      MAX
      DEFAULT
      LENGTH
      FUZZ
      PREFIX
      MULT
      FILL
      NOEDIT
      TYPE
      SEXCL
      EEXCL
      HLO
      DECSEP
      DIGSEP
      DATATYPE
      LANGUAGE
   ;
   */
run;

%if (&dedup) %then %do;
  %let cntlin=_crtfmt_._cntlin_nodup_;

  %* remove duplicate ranges from input dataset ;
  proc sort data=_crtfmt_._cntlin_ out=&cntlin dupout=_crtfmt_._cntlin_dupout_ nodupkey;
     by fmtname start;
  run;

  %* print message if duplicate observations were deleted ;
  %if (%nobs(_crtfmt_._cntlin_dupout_) gt 0) %then %do;
     %* put %str(WAR)NING:  Duplicate ranges were detected in the &DATA dataset.;
     %put %str(NO)TE:  Duplicate ranges were detected in the &DATA dataset.;

     %* Uncomment the below line if calling this macro from a DIS job ;
     %*rcSet(4);
  %end;
%end;

%* create format(s) ;
proc format cntlin=&cntlin lib=&LIB..&CAT;
quit;

%quit:
%* if (&parmerr) %then %abort;

%mend;

/******* END OF FILE *******/
