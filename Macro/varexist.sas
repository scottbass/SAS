/*=====================================================================
Program Name            : varexist.sas
Purpose                 : Check for the existence of a specified
                          variable.
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 27APR2007
Program Version #       : 1.0

=======================================================================

Modification History    : 

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

data foo;
   myvar=1;
   label myvar="This is the label for MYVAR";
run;

%put %varexist(Does_Not_Exist);
%put %varexist(Does_Not_Exist, Does_Not_Exist);
%put %varexist(foo, Does_Not_Exist);
%put %varexist(foo, myvar);
%put %varexist(foo, myvar, type);
%put %varexist(foo, myvar, label);

-----------------------------------------------------------------------
Notes:

The macro calls resolves to 0 when either the data set does not exist
or the variable is not in the specified data set. Invalid values for
the INFO parameter returns a SAS ERROR message.
---------------------------------------------------------------------*/

%macro varexist
/*---------------------------------------------------------------------
Check for the existence of a specified variable.
---------------------------------------------------------------------*/
(DATA          /* Data set name (REQ).                               */
,VAR           /* Variable name (REQ).                               */
,INFO          /* Variable attribute (REQ).                          */
               /* NUM = variable number
                  LEN = length of variable
                  FMT = format of variable
                  INFMT = informat of variable
                  LABEL = label of variable
                  TYPE  = type of variable (N for num, C for char)

                  Default is to return the variable number           */
);

%local macro parmerr dsis rc varnum;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=0)
%parmv(VAR,          _req=1,_words=0)
%parmv(INFO,         _req=0,_val=NUM LEN FMT INFMT LABEL TYPE)

%if (&parmerr) %then %goto quit;

%local dsid rc varnum;

%*---------------------------------------------------------------------
Use the SYSFUNC macro to execute the SCL OPEN, VARNUM,
other variable information and CLOSE functions.
----------------------------------------------------------------------;
%let dsid = %sysfunc(open(&data,I));

%if (&dsid) %then %do;
   %let varnum = %sysfunc(varnum(&dsid,&var));

   %if (&varnum) & %length(&info) %then
      %sysfunc(var&info(&dsid,&varnum))
   ;
   %else
      &varnum
   ;

   %let rc = %sysfunc(close(&dsid));
%end;
%else %do;
   %put %str(WAR)NING: Unable to open dataset &data.;
   0
%end;

%quit:

%mend;

/******* END OF FILE *******/
