/*=====================================================================
Program Name            : pagexofy.sas
Purpose                 : Add page numbers to output, usually in the
                          form of "Page x of Y".
SAS Version             : SAS 9.1.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 31AUG2010
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

title;
footnote;

%macro create_sample_output;
   * first generate some sample output ;
   filename old temp;  * best practice - use a temporary file for initial file ;
   filename new temp;

   * alternative files, useful for debugging by viewing in an editor ;
   filename old "c:\temp\old.lst";
   filename new "c:\temp\new.lst";

   * send your desired output to the working file ;
   proc printto print=old new;
   run;

   options pageno=1;
   proc print data=sashelp.shoes (obs=40) noobs uniform;
      var region--inventory;
   run;

   * release the output file ;
   proc printto;
   run;
%mend;

options mprint;
options ps=20 ls=80;
options nocenter nodate number;

-----------------------------------------------------------------------

title "Testing the pagexofy macro";
%create_sample_output;

* now post-process the file to generate "Page x of Y" output ;
* you can overwrite the source file ;
%pagexofy(infile=old);

=======================================================================

* or you can create a new file ;
%create_sample_output;
%pagexofy(infile=old,outfile=new);
%pagexofy(infile="c:\temp\old.lst",outfile=c:\temp\new.lst);

=======================================================================

* this is the default style ;
* you must use {PAGE} and {NUMPAGES} (case-insensitive) ;
* as tokens for <current> and <total> pages ;
%pagexofy(infile=old,outfile=new,style=Page {PAGE} of {NUMPAGES});

=======================================================================

* you can change the style ;
%pagexofy(infile=old,outfile=new,style=PAGE {PAGE} -of- {numpages});
%pagexofy(infile=old,outfile=new,style=Seite {Page} von {NumPages});
%pagexofy(infile=old,outfile=new,style=(Page {PAGE} of {NUMPAGES}));
%pagexofy(infile=old,outfile=new,style=[Page {PAGE} of {NUMPAGES}]);
%pagexofy(infile=old,outfile=new,style={Page <{PAGE}> of <{NUMPAGES}>});

=======================================================================

* or you can just embellish the current page number ;
%pagexofy(infile=old,outfile=new,style=PAGE >>>{PAGE}<<<);

=======================================================================

* specify the JUSTIFY parameter to justify the page renumbering ;
options nonumber;
title "Testing the pagexofy macro";
%create_sample_output;

* note the undesired output for left justification ;
* due to the title statement ;
%pagexofy(infile=old,outfile=new,justify=right);  * default ;
%pagexofy(infile=old,outfile=new,justify=left);
%pagexofy(infile=old,outfile=new,justify=center);

=======================================================================

* or you can use an explicit column pointer for total control ;
* this sets the beginning column position, i.e. the start of "Page..." ;
%pagexofy(infile=old,outfile=new,justify=50);

=======================================================================

* you can explicitly set the linesize ;
* useful if no titles were used or nonumber option was set ;
* so that the effective linesize cannot be reliably determined ;
options nonumber nodate;
title " ";  * you want this, print a blank title ;
%create_sample_output;
%pagexofy(infile=old,outfile=new,justify=right,ls=90);

All of the above forms of the macro call use the form feed character ("0C"x)
to count the number of pages.

=======================================================================

You can also use a specific delimiter as a token to count the number
of pages.  This delimiter would typically be in a title or footnote statement.

* Generate new sample output ;

title "Testing the pagexofy macro with a delimiter __PAGE__";
%create_sample_output;
%pagexofy(infile=old,outfile=new,delim=__PAGE__);

=======================================================================

* DELIM in conjunction with creative use of titles statements can be useful ;

options center nonumber nodate;
title1 "Acme Pharmaceutical Company";
title2 "%sysfunc(date(),date9.)";
title3 "__PAGE__";
%create_sample_output;
%pagexofy(infile=old,outfile=new,delim=__PAGE__,justify=CENTER,ls=80);

=======================================================================

* Support for user-defined delimiter allows placing the page renumbering ;
* at the bottom of the page via the footnote statement ;

options center nonumber nodate;
title1 "Acme Pharmaceutical Company";
title2 "%sysfunc(date(),date9.)";
footnote1 "Prepared by:  &sysuserid on &sysday &sysdate9 __PAGE__";
%create_sample_output;
%pagexofy(infile=old,outfile=new,delim=__PAGE__,justify=RIGHT);

=======================================================================

options nocenter nonumber nodate;
title1 "Acme Pharmaceutical Company";
title2 "%sysfunc(date(),date9.)";
footnote1 "Prepared by:  &sysuserid on &sysday &sysdate9";
footnote2 "__PAGE__";
%create_sample_output;
%pagexofy(infile=old,outfile=new,delim=__PAGE__,justify=LEFT);

-----------------------------------------------------------------------
Notes:

Either a file reference or a physical path can be used for the INFILE
and OUTFILE parameters.  If a file reference is used it must be
allocated outside this macro.  If a physical path is used, it must 1)
be quoted with single or double quotes, 2) contain a slash (forward or
backward), period, or colon, or 3) be longer than 8 characters.
Otherwise it will be treated as a file reference.

If the OUTFILE parameter is blank, the INFILE will be overwritten
with the re-paginated output.

Updating a file in place using the SAS sharebuffers infile statement
option is problematic.  Therefore, when updating a file in place, an
intermediate temporary file is used as a buffer, and this macro makes a
recursive call to itself.  This approach has a slight performance hit,
since it involves two passes over the output file, but in most cases
this should not be an issue unless the initial file is enormous.

However, best practice is to use a temporary file in the calling code
for the initial output (usually created via proc printto or ods listing
statement).  By reading and writing to separate files, the above
performance hit is avoided.

The STYLE field codes {PAGE} and {NUMPAGES} are "borrowed" from the
equivalent field codes in Microsoft Word.

The DELIM parameter should be unique to the generated output, i.e.
should occur once and only once per page.  Typically it is specified in
a title or footnote statement.

The DELIM parameter must be 20 characters or less.

Normally the longest line in the output is used to determine the
effective linesize.  This works fine if you have the number option set
when the output is generated, since the page number will be right
justified within the pagesize in effect when the output was generated,
and then overwritten when the output is re-paginated.  However, if no
titles were used, or the nonumber option was in effect, you can use the
LS parameter to explicitly set the linesize used to justify the page
renumbering.

By default the "Page x of Y" output is right justified using this
derived linesize.  Use the JUSTIFY parameter to override the default
justification.

If you specify LEFT or CENTER justification, you'll likely want to turn
off titles, or use a user-specified delimiter, or you'll probably get
unwanted results (the page renumbering overlaying other title text).

---------------------------------------------------------------------*/

%macro pagexofy
/*---------------------------------------------------------------------
Add page numbers to output, usually in the form of "Page x of Y"
---------------------------------------------------------------------*/
(INFILE=       /* Input file (REQ).                                  */
,OUTFILE=      /* Output file (Opt).                                 */
               /* If blank, the input file is overwritten.           */
,STYLE=Page {PAGE} of {NUMPAGES}
               /* Style to use for the pagination (REQ).             */
               /* Usually of the form "Page x of Y" or "Page x"      */
               /* "{PAGE}" represents the current page number.       */
               /* "{NUMPAGES}" represents the total pages in the     */
               /* file, as determined by counting either the         */
               /* form feeds or a user-specified delimiter.          */
,DELIM=\f      /* Delimiter used to count pages (REQ).               */
               /* By default the form feed character is used.        */
,JUSTIFY=RIGHT /* Justification of page renumbering (REQ).           */
               /* Default is RIGHT.                                  */
               /* Valid values are LEFT L CENTER C RIGHT R, or a     */
               /* specific integer value to hard code the beginning  */
               /* column position.                                   */
,LS=           /* Explicit line size (Opt).  If blank the linesize   */
               /* is derived from the longest line in the source file*/
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(INFILE,       _req=1,_words=1,_case=N)
%parmv(OUTFILE,      _req=0,_words=1,_case=N)
%parmv(STYLE,        _req=1,_words=1,_case=N)
%parmv(DELIM,        _req=1,_words=0,_case=N)
%parmv(JUSTIFY,      _req=1,_words=0,_case=U)
%parmv(LS,           _req=0,_words=0,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

%* additional error checking ;
%* further checks on the JUSTIFY parameter ;
%if (&justify eq LEFT)   %then %let justify=L;
%else
%if (&justify eq CENTER) %then %let justify=C;
%else
%if (&justify eq RIGHT)  %then %let justify=R;

%let _error=1;
%do i=1 %to 3;
   %let word=%scan(L C R,&i);
   %if (&justify eq &word) %then %let _error=0;
%end;

%if (&_error) %then %do;
   %if %sysfunc(verify(&justify,0123456789)) %then %let _error = 1;
   %else
   %if ^(&justify) %then %let _error = 1;
   %else %let _error = 0;
%end;

%if (&_error) %then %do;
   %parmv(_msg=Invalid value &justify for JUSTIFY.  Valid values are LEFT L CENTER C RIGHT R, or a positive integer);
   %goto quit;
%end;

%* was a physical file or a fileref specified? ;
%if (%sysfunc(findc(%superq(infile),%str(:./\%'%")))) or
    (%length(%superq(infile)) gt 8) %then
   %let infileref=0;
%else
   %let infileref=1;

%if (%sysfunc(findc(%superq(outfile),%str(:./\%'%")))) or
    (%length(%superq(outfile)) gt 8) %then
   %let outfileref=0;
%else
   %let outfileref=1;

%* does the input file exist? ;
%if (&infileref) %then
   %let exists=%sysfunc(fexist(%superq(infile)));
%else
   %let exists=%sysfunc(fileexist(%superq(infile)));

%if (not &exists) %then %do;
   %parmv(_msg=File %superq(infile) does not exist or is not allocated);
   %goto quit;
%end;

%* need to dequote INFILE and OUTFILE for later processing ;
%let infile =%scan(&infile, 1,%str(%"%'));
%let outfile=%scan(&outfile,1,%str(%"%'));

%* If OUTFILE is blank then the INFILE is overwritten (updated "in place") ;
%let inplace=0;
%if (%superq(OUTFILE) eq ) %then %do;
   %let outfile=&infile;
   %let inplace=1;
%end;

%* Updating a file in place is problematic using the infile SHAREBUFFERS option. ;
%* If updating in place, recursively call this macro, using a temporary file as a buffer ;
%if (&inplace) %then %do;
   filename __temp__ temp;
   %pagexofy(infile=&infile,outfile=__temp__);
   data _null_;
      infile __temp__;
      file &outfile;
      input;
      put _infile_;
   run;
   filename __temp__ clear;  /* this automatically deletes the temporary file */

   %goto quit;
%end;

%* SAS does not intrinsically know "a priori" how many pages of output it has created ;
%* Therefore, the output must be post-processed, after creation, in order to determine ;
%* 1) the number of pages created, and 2) re-paginating the output. ;
%* This requires two passes over the data (i.e. the previously created output). ;

%* First pass:  Derive the total page count and effective linesize ;
data pagecnt;
   length pattern $20 infile $256;
   pattern     = "&delim";
   prx         = prxparse(cats("/",pattern,"/"));
   pagecnt     = 1;

   %if (&infileref) %then %do;
   infile      = pathname("&infile");
   %end;
   %else %do;
   infile      = "&infile";
   %end;

   infile infile filevar=infile length=l end=eof;
   do until (eof);
      input;
      found = prxmatch(prx,_infile_);
      if found then numpages+1;
      ls=max(ls,l);
   end;

   /* if the delimiter is the form feed, need to account for the first page */
   numpages=numpages+(pattern eq "\f");

   /* if LS was specified, override the derivation of linesize */
   %if (&ls ne ) %then %do;
      ls=&ls;
   %end;
   keep numpages ls;
run;

%* Second pass:  Re-paginate output ;
data _null_;
   length pattern $20 infile outfile line $256;
   pattern     = "&delim";
   prx         = prxparse(cats("/",pattern,"/"));
   justify     = "&justify";

   %if (&infileref) %then %do;
   infile      = pathname("&infile");
   %end;
   %else %do;
   infile      = "&infile";
   %end;

   %if (&outfileref) %then %do;
   outfile     = pathname("&outfile");
   %end;
   %else %do;
   outfile     = "&outfile";
   %end;

   set pagecnt;
   infile infile filevar=infile end=eof /* sharebuffers */;
   %if (%superq(outfile) eq %superq(infile)) %then %do;
   file infile;
   %end;
   %else %do;
   file outfile filevar=outfile;
   %end;

   do _n_ = 1 by 1 until (eof);
      input;
      /* need a buffer, do not substr() _infile_ directly
         or you may get argument out of range errors */
      line=_infile_;
      found = prxmatch(prx,_infile_);
      if (_n_ eq 1 and pattern eq "\f") or found then do;  /* no form feed on first page so check _n_=1 */
         page + 1;
         style = "&style";
         style = prxchange(cats("s/{PAGE}/",    page,    "/i"),-1,style);
         style = prxchange(cats("s/{NUMPAGES}/",numpages,"/i"),-1,style);
         len=length(style);

         /* if a user-defined delimiter was specified blank it out */
         if (pattern ne "\f") then
            substr(line,found,length(pattern))=repeat(" ",length(pattern)-1);

         /* derive the column pointer based on JUSTIFY parameter */

         /* need to check if first character is a form feed and, if so,
            then offset the column pointer by 1 so we do not delete (overwrite) the form feed */
         ff=prxmatch("/\f/",substr(_infile_,1,1));
         select (justify);
            when ("R")
               do;
                  col=(ls-len)+ff;
                  substr(line,col,len)=style;
               end;
            when ("L")
               do;
                  col=1+ff;
                  substr(line,col,len)=style;
               end;
            when ("C")
               do;
                  col=int((ls - len)/2)+ff;
                  substr(line,col,len)=style;
               end;
            otherwise
               do;  /* must be an explicit column number */
                  col=input(justify,8.);
                  substr(line,col,len)=style;
               end;
         end;
      end;
      varlen=lengthn(line);
      put line $varying. varlen;
   end;
   stop;
run;

%quit:

%mend;

/******* END OF FILE *******/