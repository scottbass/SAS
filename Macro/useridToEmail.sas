/*=====================================================================
Program Name            : useridToEmail.sas
Purpose                 : Maps a userid to the corresponding email address
SAS Version             : SAS 9.2
Input Data              : LAN Userid
                          Data step view created by %QueryActiveDirectory
Output Data             : Email address (default is &email macro variable)

Macros Called           : parmv, queryActiveDirectory

Originally Written by   : Scott Bass
Date                    : 06JUL2012
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

* return email address of logged in LAN user (&sysuserid) ;
%useridToEmail;
%put &email;

=======================================================================

* return email address of a specific user, into a named macro variable ;
%useridToEmail(
  userid=sbass
  ,mvar=emailaddress
);
%put &emailaddress;

-----------------------------------------------------------------------
Notes:

This is really just a "wrapper" macro around the %QueryActiveDirectory
macro, passing in the proper parameters to return the email address.
All the "heavy lifting" is done by %QueryActiveDirectory.

---------------------------------------------------------------------*/

%macro useridToEmail
/*---------------------------------------------------------------------
Maps a userid to the corresponding email address
---------------------------------------------------------------------*/
(USERID=&sysuserid
               /* Userid to lookup in Active Directory (REQ).        */
,MVAR=email    /* Macro variable in which to return the email        */
               /* address (REQ).                                     */
,DEBUG=        /* Echo debugging information in the SAS log? (Opt).  */
               /* Valid values are:                                  */
               /*    Blank = no debugging                            */
               /*    I     = connection information only             */
               /*    F     = full debugging (on a large query this   */
               /*          =    can fill the SAS DMS log)            */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(USERID,       _req=1,_words=0,_case=N)
%parmv(MVAR,         _req=1,_words=0,_case=U)
%parmv(DEBUG,        _req=0,_words=0,_case=U,_val=I F)

%if (&parmerr) %then %goto quit;

%* clear macro variable from any previous invocations ;
%symdel &mvar / nowarn;
%global &mvar;

%* call the QueryActiveDirectory macro ;
%QueryActiveDirectory(
  filter=(&(sAMAccountname=&userid)(objectclass=user))
  ,attrs=mail
  ,debug=&debug
)

%* set the macro variable ;
data _null_;
  set &syslast;
  call symputx("&mvar",value);
  stop;
run;

%if (&qad_rc ne 0) %then %do;
  %parmv(_msg=Error calling the QueryActiveDirectory macro)
  %goto quit;
%end;

%quit:
%mend;

/******* END OF FILE *******/
