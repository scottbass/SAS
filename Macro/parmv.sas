/*=====================================================================
Program Name            : parmv.sas
Purpose                 : Macro parameter validation utility.
                          Returns parmerr=1 and writes ERROR message
                          to log for parameters with invalid values.
SAS Version             : SAS 8.2
Input Data              : N/A
Output Data             : N/A

Macros Called           : None

Originally Written by   : Tom Hoffman
Date                    : 09SEP1996
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

This is original work created by Tom Hoffman.
Placed into the public domain with permission.

=======================================================================

Modification History    :

Programmer              : Tom Hoffman
Date                    : 16MAR1998
Change/reason           : Replaced QTRIM autocall macro with QSYSFUNC
                          and TRIM in order to avoid conflict with the
                          i command line macro.
Program Version #       : 1.1

Programmer              : Tom Hoffman
Date                    : 04OCT1999
Change/reason           : Added _val=NONNEGATIVE. Converted _val=0 1 to
                          map N NO F FALSE OFF --> 0 and Y YES T TRUE
                          ON --> 1. Added _varchk parameter to support
                          variables assumed to be defined before macro
                          invocation.
Program Version #       : 1.2

Programmer              : Tom Hoffman
Date                    : 12APR00
Change/reason           : Changed the word 'parameter' in the message
                          text to 'macro variable' when _varchk=1.
                          Fixed NONNEGATIVE option.
Program Version #       : 1.3

Programmer              : Tom Hoffman
Date                    : 10JUN01
Change/reason           : Added _DEF parameter. Returned S_MSG global
                          macro variable.
Program Version #       : 1.4

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%macro test;

%local macro parmerr;
%let macro = TEST;

%parmv(INTERVAL,   _req=1,_words=1)
%parmv(IVAR,       _req=1)

%if (%length(&visit) > 7) %then
   %parmv(IVAR,    _msg=SAS name containing 7 or less characters)
;
%parmv(LZERO,      _req=1)
%parmv(UZERO,      _req=1)
%parmv(HIGH,       _req=1,_val=0 1)
%parmv(DAY,        _req=1)
%parmv(PRINT,      _req=1,_val=0 1)

%if (&parmerr) %then %goto quit;
....
%quit:

%mend test;

-----------------------------------------------------------------------
Notes:

=======================================================================
This code was developed by HOFFMAN CONSULTING as part of a FREEWARE
macro tool set. Its use is restricted to current and former clients of
HOFFMAN CONSULTING as well as other professional colleagues. Questions
and suggestions may be sent to TRHoffman@sprynet.com.

Note:  I have received permission from Tom Hoffman to use this macro.
Scott Bass
=======================================================================

The calling macro requires two local variables, PARMERR and MACRO,
where MACRO's value equals the name of the calling macro.

Invoke macro %parmv once for each macro parameter. After the last
invocation branch to the macro's end whenever PARMERR equals 1 (e.g.,
%if (&parmerr) %then %goto quit;).

Macro %parmv can be disabled (except for changing case) by setting the
global macro variable S_PARMV to 0.

Macros using the %parmv tool may not have any parameters in common
with parmv parameters.

Use the _MSG parameter to set parmerr to 1 and issue a message based on
validation criteria within the calling program.

Note that for efficiency reasons, parmv does not validate its own
parameters. Only code valid values for the _REQ, _WORDS, _CASE, and
_VARCHK parameters.

For macros that require 'many' non-parameter macro variables that may
not be defined by the programming environment, consider using the
CHKMVARS macro rather than setting _varchk=1. Both methods will work,
but note that DICTIONARY.MACROS is opened each time that parmv is
invoked with _varchk=1.
--------------------------------------------------------------------*/

%macro parmv
/*---------------------------------------------------------------------
Macro parameter validation utility. Returns parmerr=1 and writes
ERROR message to log for parameters with invalid values.
---------------------------------------------------------------------*/
(_PARM     /* Macro parameter name (REQ)                             */
,_VAL=     /* List of valid values or POSITIVE for any positive      */
           /* integer or NONNEGATIVE for any non-negative integer.   */
           /* When _val=0 1, OFF N NO F FALSE and ON Y YES T TRUE    */
           /* (case insensitive) are acceptable aliases for 0 and 1  */
           /* respectively.                                          */
,_REQ=0    /* Value required? 0=No, 1=Yes.                           */
,_WORDS=0  /* Multiple values allowed? 0=No ,1=Yes                   */
,_CASE=U   /* Convert case of parameter value & _val? U=upper,       */
           /* L=lower,N=no conversion.                               */
,_MSG=     /* When specified, set parmerr to 1 and writes _msg as the*/
           /* last error message.                                    */
,_VARCHK=0 /* 0=Assume that variable defined by _parm exists.        */
           /* 1=Check for existence - issue global statement if not  */
           /* defined (and _req=0).                                  */
,_DEF=     /* Default parameter value when not assigned by calling   */
           /* macro.                                                 */
);

%local _word _n _vl _pl _ml _error _parm_mv;
%global s_parmv s_msg;  /* in case not in global environment */

%*---------------------------------------------------------------------
Initialize error flags, and valid (vl) flag.
----------------------------------------------------------------------;
%if (&parmerr = ) %then %do;
   %let parmerr = 0;
   %let s_msg = ;
%end;
%let _error = 0;

%*---------------------------------------------------------------------
Support undefined values of the _PARM macro variable.
----------------------------------------------------------------------;
%if (&_varchk) %then %do;
   %let _parm_mv = macro variable;
   %if ^%symexist(&_parm) %then %do;
      %if (&_req) %then
         %local &_parm
      ;
      %else
         %global &_parm
      ; ;
   %end;
%end;
%else %let _parm_mv = parameter;

%*---------------------------------------------------------------------
Get lengths of _val, _msg, and _parm to use as numeric switches.
----------------------------------------------------------------------;
%let _vl = %length(&_val);
%let _ml = %length(&_msg);
%if %length(&&&_parm) %then
   %let _pl = %length(%qsysfunc(trim(&&&_parm)));
%else %if %length(&_def) %then %do;
   %let _pl = %length(&_def);
   %let &&_parm = &_def;
%end;
%else %let _pl = 0;

%*---------------------------------------------------------------------
When _MSG is not specified, change case of the parameter and valid
values conditional on the value of the _CASE parameter.
----------------------------------------------------------------------;
%if ^(&_ml) %then %do;
   %let _parm = %upcase(&_parm);
   %let _case = %upcase(&_case);

   %if (&_case = U) %then %do;
      %let &_parm = %qupcase(&&&_parm);
      %let _val = %qupcase(&_val);
   %end;
   %else %if (&_case = L) %then %do;
      %if (&_pl) %then %let &_parm = %qsysfunc(lowcase(&&&_parm));
      %if (&_vl) %then %let _val = %qsysfunc(lowcase(&_val));
   %end;
   %else %let _val = %quote(&_val);

%*---------------------------------------------------------------------
When _val=0 1, map supported aliases into 0 or 1.
----------------------------------------------------------------------;
   %if (&_val = 0 1) %then %do;
      %let _val=%quote(0 (or OFF NO N FALSE F) 1 (or ON YES Y TRUE T));
      %if %index(%str( OFF NO N FALSE F ),%str( &&&_parm )) %then
         %let &_parm = 0;
      %else %if %index(%str( ON YES Y TRUE T ),%str( &&&_parm )) %then
         %let &_parm = 1;
   %end;
%end;

%*---------------------------------------------------------------------
Bail out when no parameter validation is requested
----------------------------------------------------------------------;
%if (&s_parmv = 0) %then %goto quit;

%*---------------------------------------------------------------------
Error processing - parameter value not null

Error 1: Invalid value - not a positive integer
Error 2: Invalid value - not in valid list
Error 3: Single value only
Error 4: Value required.
Error 5: _MSG specified
----------------------------------------------------------------------;
%if (&_ml) %then %let _error = 5;

%*---------------------------------------------------------------------
Macro variable specified by _PARM is not null.
----------------------------------------------------------------------;
%else %if (&_pl) %then %do;

%*---------------------------------------------------------------------
Loop through possible list of words in the _PARM macro variable.
-----------------------------------------------------------------------;
   %if ((&_vl) | ^(&_words)) %then %do;
      %let _n = 1;
      %let _word = %qscan(&&&_parm,1,%str( ));
%*---------------------------------------------------------------------
Check against valid list for each word in macro parameter
----------------------------------------------------------------------;
      %do %while (%length(&_word));

%*---------------------------------------------------------------------
Positive integer check.
----------------------------------------------------------------------;
         %if (&_val = POSITIVE) %then %do;
            %if %sysfunc(verify(&_word,0123456789)) %then
               %let _error = 1;
            %else %if ^(&_word) %then %let _error = 1;
         %end;

%*---------------------------------------------------------------------
Non-negative integer check.
----------------------------------------------------------------------;
         %else %if (&_val = NONNEGATIVE) %then %do;
            %if %sysfunc(verify(&_word,0123456789)) %then
               %let _error = 1;
         %end;

%*---------------------------------------------------------------------
Check against valid list. Note blank padding.
----------------------------------------------------------------------;
         %else %if (&_vl) %then %do;
            %if ^%index(%str( &_val ),%str( &_word )) %then
               %let _error = 2;
         %end;

%*---------------------------------------------------------------------
Get next word from parameter value
-----------------------------------------------------------------------;
         %let _n = %eval(&_n + 1);
         %let _word = %qscan(&&&_parm,&_n,%str( ));
      %end; %* for each word in parameter value;

%*---------------------------------------------------------------------
Check for multiple _words. Set error flag if not allowed.
----------------------------------------------------------------------;
      %if (&_n ^= 2) & ^(&_words) %then %let _error = 3;

   %end; %* valid not null ;

%end; %* parameter value not null ;

%*---------------------------------------------------------------------
Error processing - Parameter value null

Error 4: Value required.
----------------------------------------------------------------------;
%else %if (&_req) %then %let _error = 4;

%*---------------------------------------------------------------------
Write error messages
----------------------------------------------------------------------;
%if (&_error) %then %do;
   %let parmerr = 1;
   %put %str( );
   %put ERROR: Macro %upcase(&macro) user error.;

   %if (&_error = 1) %then %do;
      %put ERROR: &&&_parm is not a valid value for the &_parm &_parm_mv..;
      %put ERROR: Only positive integers are allowed.;
      %let _vl = 0;
   %end;

   %else %if (&_error = 2) %then
      %put ERROR: &&&_parm is not a valid value for the &_parm &_parm_mv..;

   %else %if (&_error = 3) %then %do;
      %put ERROR: &&&_parm is not a valid value for the &_parm &_parm_mv..;
      %put ERROR: The &_parm &_parm_mv may not have multiple values.;
   %end;

   %else %if (&_error = 4) %then
      %put ERROR: A value for the &_parm &_parm_mv is required.;

   %else %if (&_error = 5) %then %do;
      %if (&_parm ^= ) %then
      %put ERROR: &&&_parm is not a valid value for the &_parm &_parm_mv..;
      %put ERROR: &_msg..;
   %end;

   %if (&_vl) %then
      %put ERROR: Allowable values are: &_val..;

   %if %length(&_msg) %then %let s_msg = &_msg;
   %else %let s_msg = Problem with %upcase(&macro) parameter values - see LOG for details.;

%end; %* errors ;

%quit:

%*---------------------------------------------------------------------
Unquote the the parameter value, unless it contains an ampersand or
percent sign.
----------------------------------------------------------------------;
%if ^%sysfunc(indexc(&&&_parm,%str(&%%))) %then
   %let &_parm = %unquote(&&&_parm);

%mend;

/******* END OF FILE *******/