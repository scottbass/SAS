/*=====================================================================
Program Name            : getpassword.sas
Purpose                 : Gets a password from an external file
SAS Version             : SAS 9.3
Input Data              : External file containing a password on
                          line 1, optionally in column 1
Output Data             : Password as an r-value

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 02FEB2017
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

Create an external file containing a password on line 1, column 1.
Protect that file with operating system security as desired,
such that only trusted persons can read the file contents.

See http://passwordsgenerator.net, et. al. to generate a strong password.

%let mypassword=%getpassword(\\path\to\the\password\file);
%put ***&mypassword***;

Sets &mypassword to the returned password.

=======================================================================

%put ***%getpassword(\\path\to\the\password\file)***;

Directly uses the returned password as a returned R-value.

Note: this construct prints a single space before the returned password,
i.e. *** mypassword***.  I believe this is due to the way the macro
tokenizer works.  If this leading space is significant to your 
processing, either assign the value to a macro variable as above,
or see the example below.

=======================================================================

%put ***%left(%getpassword(\\path\to\the\password\file))***;

Directly uses the returned password as a returned R-value.

This approach removes the leading space before the returned password.

=======================================================================

* Error checking ;
%put ***%getpassword(\\does\not\exist)***;

* (edit the password file so the password is not on line 1) ;
%put ***%getpassword(\\path\to\the\password\file)***;

-----------------------------------------------------------------------
Notes:

Technically this macro doesn't return a password per se, it merely
returns the text on line 1 in the supplied password file.  I've left
the macro name as %getpassword to indicate its intended purpose.

Leading and trailing spaces are stripped from the returned password.
Do not include leading or trailing spaces in the password stored in the
password file or you may get unintended results.

The password is returned as an R-value, so the macro must be called
in the correct context.

---------------------------------------------------------------------*/

%macro getpassword
/*---------------------------------------------------------------------
Gets a password from an external file
---------------------------------------------------------------------*/
(FILENAME      /* External file containing the password on line 1    */
);

%local macro parmerr rc fileref password;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(FILENAME,     _req=1,_words=1,_case=N)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* does the file exist? ;
%if (not %sysfunc(fileexist(&filename))) %then %do;
   %parmv(_msg=File &filename does not exist)
   %goto quit;
%end;

%* use a system generated fileref ;
%let fileref=;

%* this will create a system generated fileref, eg. #LN00001 ;
%* the fileref will increment each time the macro is called ;
%let rc=%sysfunc(filename(fileref,&filename));   

%if (&rc eq 0) %then %do;
   %let fid = %sysfunc(fopen(&fileref));      
   %let rc  = %sysfunc(fread(&fid));          
   %let rc  = %sysfunc(fget(&fid,password));  
   %let fid = %sysfunc(fclose(&fid));         
   %let rc  = %sysfunc(filename(fileref));

   %if (%superq(password) ne ) %then %do;
&password
   %end;
   %else %do;
      %parmv(_msg=The password is blank.  The password must be on line 1 of the password file)
      %goto quit;
   %end;
%end;
%else %do;
   %parmv(_msg=Unable to open &filename)
   %goto quit;
%end;

%quit:

%mend;

/******* END OF FILE *******/
