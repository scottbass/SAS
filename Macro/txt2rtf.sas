%macro txt2rtf
/*----------------------------------------------------------------------
Convert text file to RTF file
----------------------------------------------------------------------*/
(in=   /* Filename (in quotes), or fileref, of the input text file.  */
,out=  /* Filename (in quotes), or fileref, of the RTF output file.  */
,font=Courier New   /* font name to use in RTF document */
,fs=8               /* font size to use in RTF document */
,orient=L           /* page orientation  L=landscape, P=portrait */
,magnif=100         /* Magnification in percent when opened for viewing */
,margins=       /* page margins in inches - top, bottom, left, right */
  0.9 0.4 1.0 1.0
,hanging = 1.5 /*Length of hanging indent for TOC in inches*/
,tabalign = Y  /*Insert a tab character after the table numbers in the TOC to align the text*/
,startRule = %str(scan(lowcase(string),1) in ('table' 'listing' 'figure' 'appendix')) /*Rule that determines when a table title starts*/
,endRuleSameLine = %str(scan(lowcase(string),-1) in ('set' 'population')) /*Rule that determines when a table title ends*/
,endRuleNextLine = %str(lowcase(string)=:'__________' or lowcase(string)=:'treatment:') /*Rule that determines when a table ended the line before*/

 /* Document Information Fields */
,author=   /* Windows default %USERNAME%. Unix default id command.     */
,title=    /* Title.    */
,subject=  /* Subject.  */
,keywords= /* Keywords. */
,toc=Y     /* Create TOC? */
);

/*----------------------------------------------------------------------
$Purpose: Creates RTF files from ASCII files
$System archet: UNIX
$Assumptions:
$Inputs: One or more ASCII files as specified by IN parameter.
$Outputs: RTF file as specified in out parameter.
$Called by:
$Calls to: parmv.sas
-----------------------------------------------------------------------
$Usage notes:
For information on RTF syntax and commands check out this webpage
 http://www.logictran.com/RTF/RTF114.htm

IN can be an aggregate file. Each new file will start a new page.

Does not protect against {\} characters in AUTHOR, TITLE, SUBJECT or
KEYWORDS parameters.

----------------------------------------------------------------------*/
%local macro parmerr m1 m2 m3 m4 i;

%parmv(orient,       _req=0,_val=L LANDSCAPE P PORTRAIT,_def=L)
%parmv(magnif,       _req=0,_val=positive)
%parmv(in,           _req=1,_words=1,_case=N)
%parmv(out,          _req=1,_words=1,_case=N)
%parmv(toc,          _req=0,_words=0,_case=N,_val=0 1)

%if (&parmerr) %then %goto quit;
%*----------------------------------------------------------------------
Get a value of the AUTHOR info tag
-----------------------------------------------------------------------;
%if ^%length(&author) %then %do;
  %if &sysscp=WIN %then
    %let author = %sysget(USERNAME);
  %else
    %let author = %sysget(USER);
%end;

%*----------------------------------------------------------------------
Use only first character of orientation.
-----------------------------------------------------------------------;
%let orient=%substr(&orient.L,1,1);

%*----------------------------------------------------------------------
RTF actually store FS in half a font. (Example: For 7.5 use 15 )
-----------------------------------------------------------------------;
%let fs=%sysevalf(2*&fs);

%do i = 1 %to 4;
  %let m&i=%sysevalf(1440*%scan(&margins,&i,%str( )));
  %let m&i=%sysfunc(int(&&m&i+0.5));
%end;


%let _err = ;

data _null_;
  format TOCText LastTOCText $32767. string $500. fnm $256.;
  file &out lrecl=1000 noprint;
  if _n_ eq 1 then do;
    put  "{\rtf1\ansi"                                               /* Start RTF document */
         "{\deff0\fonttbl{\f0\fmodern &font;}}"                      /* Font Table */
         "{\stylesheet{\s0\f0\fs&fs\sbasedon222\snext0 Normal;}"     /* To get all text in the right font */
         "{\s1\f0\fs&fs\fi-%sysevalf(&hanging*1440)\li%sysevalf(&hanging*1440)\sbasedon0\snext0 TOC 1;}}"   /* To get the hanging indent in TOC */
         "{\info"                                                    /* Document Information */
%if (%length(&title)) %then
         "{\title &title}"
;
%if (%length(&subject)) %then
         "{\subject &subject}"
;
         "{\author &author}"
         "{\keywords TEXT2RTF &keywords}"
         "}"
%if &orient ne L %then                                               /* Paper Size */
        "\paperh15840\paperw12240"
;
%else
         "\paperw15840\paperh12240\lndscpsxn"
;
         "\margt&m1\margb&m2\margl&m3\margr&m4 "                     /* Margins */
         "\dntblnsbdb"                                               /* Do not balance double byte characters */
         "\viewkind4\viewscale&magnif"                               /* View magnification */
         "\pard\plain \fs&fs\s1"                                     /* Set font and size for TOC*/
%if &toc %then
         "\field\fldedit{\*\fldinst {TOC \\f t \\h\\z \\* MERGEFORMAT}}{\fldrslt Press F9 for Table of Contents}" /* Insert a table of contents */
         "\par \pard\page\s0\fs&fs"                                  /* Set font and size for rest of document */
;
    ;
  end;
  else put "\par " @;
  if eof then put "\pard }";
  infile &in lrecl=200 truncover eov=eov end=eof filename=fnm;
  input string $char200. ;
*----------------------------------------------------------------------;
* If new file does not start with FORMFEED then insert page break ;
*----------------------------------------------------------------------;
  if eov and _n_ > 1 and string ^=: '0C'x then put '\page ' @;
*----------------------------------------------------------------------;
* Delete lines that start with ESC codes ;
*----------------------------------------------------------------------;
  if string =: '1B'x then return;
*----------------------------------------------------------------------;
* Protect special characters ;
*----------------------------------------------------------------------;
  string=tranwrd(string,'\','\\');
  string=tranwrd(string,'{','\{');
  string=tranwrd(string,'}','\}');
*----------------------------------------------------------------------;
* If a new page has started then start looking for a new title;
*----------------------------------------------------------------------;
  if index(string,'0C'x)>0 or _n_=1 or eov then do;
   if TOCEntry and (symget('_err')='') then do;
      call symputx('_err',"E"||"RROR: At least one table title did not encounter an end rule before a page break."
         ||'0D'x||"First occurrence in file "||strip(fnm)|| " in " || substr(TOCText,1,100));
   end;
   newpage = 1; retain newpage;
   TOCEntry=0; retain TOCEntry;
   TOCText=""; retain TOCText;
  end;

*----------------------------------------------------------------------;
*Mark the first table on any page as a new TOC entry if it is different
  from the TOC entry on the previous page;
*----------------------------------------------------------------------;
  if (&startRule) and newpage then do;
   TOCText = strip(string);
   TOCEntry=1;
   newpage = 0;
  end;
  else if TOCEntry then do;
   if (not (&endRuleNextLine)) and (notspace(string,1)>0) then TOCText = strip(TOCText)||" "||strip(string);
   if (&endRuleNextLine) or (&endRuleSameLine) then do;
*----------------------------------------------------------------------;
*Insert a tab character after the table number to align the titles in the hanging indent;
*----------------------------------------------------------------------;
      %if %sysfunc(indexw(1 TRUE Y YES,%upcase(&tabalign)))>0 %then %do;
         nLeft = anyspace(TOCText,1);
         if nLeft>0 then do;
            nLeft = notspace(TOCText,nLeft);
            if nLeft>0 then do;
               nLeft = anyspace(TOCText,nLeft);
               if nLeft>0 then do;
                  nRight = notspace(TOCText,nLeft);
                  if nRight>0 then
                     TOCText = strip(substr(TOCText,1,nLeft))||'09'x||strip(substr(TOCText,nRight));
               end;
            end;
         end;
      %end;
      if lastTOCText ne TOCText then string = "{\tc {\v {"||strip(TOCText)||"} \tcf116 }}"||trim(string);
      TOCEntry = 0;
      LastTOCText = TOCText;  retain LastTOCText;
   end;
  end;
*----------------------------------------------------------------------;
* Reset the EOV flag so it will be set to 1 at start of next file ;
*----------------------------------------------------------------------;
  eov=0;
*----------------------------------------------------------------------;
* Convert FORMFEED to \page command ;
*----------------------------------------------------------------------;
  string=tranwrd(string,'0C'x,'\page ');
*----------------------------------------------------------------------;
* Write the line to the output file ;
*----------------------------------------------------------------------;
  len=length(string);
  put string $varying. len;
run;
%put &_err;
%quit:
%mend;

