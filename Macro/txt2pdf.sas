/*******************************************************************************************

          Program:  txt2pdf.sas
      Description:  Convert text files to Adobe(TM) Acrobat (PDF) documents
           Inputs:  Macro parameters
         Calls to:  None
      Usage Notes:  The source text file is paginated based on form-feed characters (unix,
                    windows platforms), or newpage line attribute (MVS platforms).  If your
                    text file does not contain these characters, you will only get one page
                    in the resulting PDF (if not an error).

                    If you are producing output in a data _null_ step, the output mode
                    should be set to "print", as in:

                        data _null_;
                          file 'my_output_file.txt' print;
                          ...

                    Although the output file created by %m_txt2pdf is made up of printable
                    characters, PDF is technically a binary format.  Furthermore, the exact
                    offset of each page in the file is marked in the cross-reference table,
                    so any modification of the output file (by a text editor, for example)
                    that will change the number of bytes in the output file will invalidate
                    the cross-reference table and may make your PDF document unreadable.

                    For convenience of debugging, the macro produces output in the native
                    character set of host platform.  The charset and crlf parameters are
                    provided to allow tune the file output for cross-platform transfers in
                    ASCII mode.  If you are generating and viewing your PDF documents on the
                    same platform, these parameters can be left unspecified.

                    Setting the margins:

                             ^  +------- Dimensions of the page ------------------------+
                             |  |                                     ^                 |
                             |  |                                     | TM              |
                             |  |                                     v                 |
                             |  |      +----- Printing Area ---------------------+      |
                             |  |<---->|                                         |<---->|
                             |  |  LM  |                                         |  RM  |
                          PH |  |      |                                         |      |
                             |  |      |                                         |      |
                             |  |      |                                         |      |
                             |  |      |                                         |      |
                             |  |      |                                         |      |
                             |  |      +-----------------------------------------+      |
                             |  |         ^                                             |
                             |  |         | BM                                          |
                             |  |         v                                             |
                             v  +-------------------------------------------------------+
                                 <-------------------- PL ----------------------------->
                                             Landscape  Portrait
                         PH = Page Height -    8.5        11       612  792
                         PL = Page Length -   11           8.5     792  612
                         BM = Bottom Margin
                         TM = Top Margin
                         LM = Left Margin
                         RM = Right Margin

        Revisions:  (date/by/reason)
          $Author:  $
        $Revision:  $
            $Date:  $
          $Source:  $
        $Comments:  $

*******************************************************************************************/

%macro txt2pdf(
     in        =    ,    /* Filename (in quotes), or fileref, of the input text file      */
     out       =    ,    /* Filename (in quotes), or fileref, of the PDF output file      */
     infile    =    ,    /* Alias for IN=                                                 */
     file      =    ,    /* Alias for OUT=                                                */
     ls        =    ,    /* Number of characters per line. If not specified then use      */
                         /* maximum non-blank linesize from the input text file.          */
     ps        =    ,    /* Number of lines per page. If not specified then use from      */
                         /* the input text file.                                          */
     fs        =    ,    /* Fontsize to use in PDF file. When not specified then an       */
                         /* appropriate value is calculated from LS and PS.               */
     minfs     = 6  ,    /* MINFS and MAXFS set the limits when calculating Fontsize      */
     maxfs     = 12 ,    /* from PS and LS.                                               */
     filenfs   =    ,    /* Fontsize to use in filename footer (0 means no filename)      */
                         /* Default to 0 for single input physical file, 6 otherwise.     */
     wm        =    ,    /* Text to appear as watermark on every page.                    */
     wmfs      = 128,    /* Fontsize to use for watermark. Default works well when        */
                         /* WM=DRAFT is used.                                             */
     charset   =    ,    /* Specifies the character set to use for output. Used to        */
                         /* set characters for the left and right square brackets []      */
                         /* This parameter can usually be left unspecified, unless        */
                         /* the output file is intended to be transferred between         */
                         /* platforms.  The following characters sets are defined:        */
                         /*    EBCDIC - (Default on MVS platforms)                        */
                         /*    ASCII - (Default for everything else)                      */
     crlf      =    ,    /* Specifies the number of characters in a "newline" on          */
                         /* this platform.  The default is 2 for Windows ('0D0A'x),       */
                         /* 2 for MVS (anticipating transfer to windows platform),        */
                         /* and 1 for everything else ('0A'x, i.e. unix systems)          */
     cc        =    ,    /* Interpret first column as FORTRAN Carriage Control codes?     */
                         /* (0/1).  Control characters support are: 1=Formfeed,           */
                         /* 0=Double space, -=Triple space. First column is stripped      */
                         /* from the output. When CHARSET=EBCDIC then default for CC      */
                         /* is 1 (yes) otherwise the default is 0 (no) .                  */

     /* Page dimensions and orientation.                                                  */
     orient    = L  ,    /* Orientation Landscape or Portrait                             */
     tm        = 1  ,    /* Top Margin in Inches                                          */
     bm        = 1  ,    /* Bottom Margin in Inches                                       */
     lm        = 1  ,    /* Left Margin in Inches                                         */
     rm        = 1  ,    /* Right Margin in Inches                                        */
     fontstep  = 4  ,    /* Font size ganularity. Calculate fontsize to the best          */
                         /* 1/fontstep unit. For example 4 means quarter of a font        */
                         /* size (12 11.75 11.50 11.25 11 ...)                            */

     /* PDF Document information fields                                                   */
     author    =    ,    /* Windows default %USERNAME%. Unix default id command.          */
     title     = 5  ,    /* Title. Text or Number. Number means nth nonblank line         */
     subject   =    ,    /* Subject.                                                      */

     /* Where to get Bookmark information.                                                */
     bookmk    = 4  ,    /* Bookmark text to insert pointing to first page.               */
                         /* BOOKMK=nnn  Use non-blank line number nnn. Generate a new mark*/
                         /*             everytime the value changes in the input file(s). */
                         /* BOOKMK=name When &BOOKMK is the name of a dataset with fields */
                         /*             PAGE and BKMARK then use that dataset as source   */
                         /*             of marks.                                         */
                         /* Otherwise make a single book mark of value &BOOKMK to page 1. */
     );
%*=========================================================================

 SAS2PDF v0.03

   A SAS macro for converting text files to PDF documents

 Copyright (C) 2000-2003  Information Softworks

 This program is free software, you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation, either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY, without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

 For information, contact:
   Information Softworks
   2181 Stonebridge Drive
   Ann Arbor, MI 48108

   or email:  sas2pdf@informationsoftworks.com

 You should have received a copy of the GNU General Public License
 along with this program if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

---------------------------------------------------------------------------
v0.03 - P Wehr
   Add missing keyword to Remove annoying "this file has been damaged, but
is being repaired" message from Acrobat reader.  Thanks to Duncan Hon
for his keen eye.
---------------------------------------------------------------------------
v0.02 - P Wehr
   Brown Paper Bag bug fix--removed substring that trimmed off the first
character for all OSs except MVS, and it doesnt even print the first page
on most platforms...

===========================================================================;

%local macro parmerr i
 validds            /* Used to test if &BOOKMK is a dataset name           */
 dsname             /* Dataset Name to use in bookmark generation          */
 lb rb              /* Left and right square brackets                      */
 pages files marks  /* Input Counters                                      */
 objects            /* Used to dimension XREF table offset storage array   */
 maxchar            /* Adjust for version 6 limitations                    */
 pagechar           /* New page character                                  */

 /* Variables used in setting font                                         */
 maxps minps maxls vfs hfs long short
 pl                 /* Text length in inches                               */
 ph                 /* Text height in inches                               */
 tl                 /* Text length in pica (1/120 in)                      */
 th                 /* Text height in page units (1/72 in)                 */
 titlen
 pad                /* Adjust length of XREF table lines                   */

 /* Variables used in generating PDF motion commands                       */
 origin             /* Rotation matrix and where to put first line         */
 vm                 /* How far to move to start next line                  */
 fnorig             /* Where to put filename footer                        */
;

%let macro=&sysmacroname;

%if (%sysevalf(&sysver >= 7)) %then %let maxchar=1000;
%else %let maxchar=200;

%let orient=%upcase(%substr(&orient.L,1,1));

%*----------------------------------------------------------------------
Get a value of the AUTHOR info tag
-----------------------------------------------------------------------;
%if ^%length(&author) %then %do;
  %if &sysscp=WIN %then %let author = %sysget(USERNAME);
  %else %let author = %upcase(&sysuserid);
%end;

%*----------------------------------------------------------------------
Either set TITLEN to number specified in TITLE parameter or set to 0
when TITLE parameter is not a number.
-----------------------------------------------------------------------;
%if %sysfunc(verify(&title,0123456789)) %then %do;
  %let titlen=0;
%end;
%else %do;
  %let titlen=&title;
  %let title=SAS output;
%end;

%*----------------------------------------------------------------------
Check how to get bookmarks.
-----------------------------------------------------------------------;
%if ^%sysfunc(verify(&bookmk,0123456789)) %then %do;
%*----------------------------------------------------------------------
When &BOOKMK is an integer then scan input for bookmark text.
-----------------------------------------------------------------------;
  %let dsname=_bkmark_(keep=page bkmark filename);
%end;
%else %do;
%*----------------------------------------------------------------------
Check if &BOOKMK is in format for a valid dataset name. (This will
prevent an error message from the OPEN command used by VAREXIST.) If
format is ok then test if required PAGE and BKMARK variables exist.
-----------------------------------------------------------------------;
  %let validds=%qscan(&bookmk,1,%str(%());
  %if (%length(%qscan(&validds,1,.))>32)
   or (%length(%qscan(&validds,2,.))>32)
   or (%length(%qscan(&validds,3,.))>0 )
   or (%index(&validds,..))
   %then %let validds=0;
  %else %if ((%varexist(&bookmk,PAGE,TYPE)=N) and
            (%varexist(&bookmk,BKMARK,TYPE)=C)) %then %do;
      %let validds=1;
  %end;
  %else %let validds=0;

*----------------------------------------------------------------------;
* Create BOOKMARK dataset _BKMARK_ ;
*----------------------------------------------------------------------;
    data _bkmark_ (keep=page bkmark);
      length page 8 bkmark $ &maxchar;
  %if (&validds) %then %do;
*----------------------------------------------------------------------;
* Use the dataset named by BOOKMK parameter. ;
*----------------------------------------------------------------------;
      set &bookmk end=eof;
      if eof then call symput('MARKS',compress(put(_n_,8.)));
  %end;
  %else %do;
*----------------------------------------------------------------------;
* Use the BOOKMK parameter as bookmark to page one. ;
*----------------------------------------------------------------------;
      page=1;
      bkmark="&bookmk";
      call symput('MARKS','1');
  %end;
    run;
%*----------------------------------------------------------------------
Set dataset name to _NULL_ and BOOKMK to zero to prevent bookmark
detection during first pass reading of the input.
-----------------------------------------------------------------------;
  %let dsname=_null_;
  %let bookmk=0;
%end;

%let charset=%upcase(&charset);
%if %bquote(&in)=%bquote() %then %let in=&infile;
%if %bquote(&out)=%bquote() %then %let out=&file;
%if &sysscp=WIN %then %do;
  %if &crlf= %then %let crlf=2;
  %if &charset= %then %let charset=ASCII;
  %if &cc= %then %let cc=0;
%end;
%else %if &sysscp=OS %then %do;
  %if &crlf= %then %let crlf=2;
  %if &charset= %then %let charset=EBCDIC;
  %if &cc= %then %let cc=1;
%end;
%else %do;
  %if &crlf= %then %let crlf=1;
  %if &charset= %then %let charset=ASCII;
  %if &cc= %then %let cc=0;
%end;
%if (&crlf=1) %then %let pad=%str( );

%if (&cc) %then %let pagechar='1';
%else %let pagechar='0C'x;

%*-----------------------------------------------------------------------
Generate left and right bracket characters.  Brackets do not pass
through some ASCII <-> EBCDIC conversions correctly.
  ASCII  uses 5B and 5D hex
  EBCDIC uses AD and BD hex
------------------------------------------------------------------------;
%if &charset=EBCDIC %then %do;
  %let lb=%sysfunc(byte(173));
  %let rb=%sysfunc(byte(189));
%end;
%else %do;
  %let lb=%sysfunc(byte(91));
  %let rb=%sysfunc(byte(93));
%end;

*-----------------------------------------------------------------------;
* Scan input file and determine number of pages, maximum linesize,  ;
* maximum pagesize, table number (bookmark) and title. ;
* Create dataset of bookmarks to pages. ;
*-----------------------------------------------------------------------;
data &dsname;
  length page 8 line bkmark filename fname oldbk $ &maxchar;
  retain maxls 0 page 0 ps 0 maxps 0 titlen 0 files 0 marks 0 oldbk;
  infile &in end=eof length=len eov=eov filename=fname lrecl=&maxchar;
  input line $varying&maxchar.. len;
  filename = fname;
  formfeed = (line =: &pagechar);
  linelen = length(line)-(formfeed or &cc);
  if formfeed or _n_=1 or eov then do;
    page+1;
    if ps > maxps then maxps = ps;
    ps = 0;
        titlen = 0;
    if _n_=1 or eov then do;
      files+1;
    end;
  end;
  eov=0;
  if (line ^=: '1B'x) and (line ^= &pagechar) then do;
    ps+1;
    %if (&cc) %then %do;
      if (line =: '0') then ps+1;
      if (line =: '-') then ps+2;
    %end;
    if linelen > maxls then maxls=linelen;
    if substr(line,1+(formfeed or &cc)) ne ' ' then do;
      titlen+1;
*-----------------------------------------------------------------------;
* Look for text to use for the bookmark/table number ;
*-----------------------------------------------------------------------;
      if (titlen=&bookmk) then do;
        bkmark=left(substr(line,1+(formfeed or &cc)));
        bkmark=substr(bkmark,1,index(bkmark,'  ')-1);
        if (bkmark ne oldbk) then do;
          marks+1;
          output;
          oldbk=bkmark;
        end;
      end;
*-----------------------------------------------------------------------;
* Look for text to use for the title  ;
*-----------------------------------------------------------------------;
      if (page=1) and (titlen=&titlen) then do;
        bkmark=left(substr(line,1+(formfeed or &cc)));
        if index(upcase(bkmark),'PAGE ') then do;
          bkmark=substr(bkmark,1,index(upcase(bkmark),'PAGE ')-1);
        end;
        call symput('title',trim(bkmark));
      end;
    end;
  end;
  if eof then do;
    if ps > maxps then maxps = ps;
    call symput('files',compress(put(files,8.)));
    call symput('pages',compress(put(page,8.)));
    call symput('maxls',compress(put(maxls,8.)));
    call symput('maxps',compress(put(maxps,8.)));
%if (&bookmk) %then %do;
    call symput('marks',compress(put(marks,8.)));
%end;
  end;
run;

%put NOTE: &macro Files=&files Pages=&pages Pagesize=&maxps Linesize=&maxls;

%*-----------------------------------------------------------------------
Set PS and LS based on data if not specified in macro call
------------------------------------------------------------------------;
%if (&ps = ) %then %let ps=&maxps;
%if (&ls = ) %then %let ls=&maxls;

%*-----------------------------------------------------------------------
When FILENFS not specified default to 6 for multiple files
------------------------------------------------------------------------;
%if (&filenfs = ) %then %do;
  %if (&files = 1) %then %let filenfs=0;
  %else %let filenfs=6;
%end;

*--------------------------------------------------------------------;
* Set dimensions ;
*--------------------------------------------------------------------;
%let long=11;
%let short=8.5;
%if (&orient=P) %then %do;
  %let ph=&long;
  %let pl=&short;
  %let origin=%sysevalf(&tm*72) %sysevalf((&lm)*72);
  %let fnorig=0 1 -1 0 %sysevalf((&long-&bm)*72-&filenfs) %sysevalf(&lm*72);
%end;
%else %do;
  %let pl=&long;
  %let ph=&short;
  %let origin=%sysevalf(&lm*72) %sysevalf((&short-&tm)*72);
  %let fnorig=1 0 0 1 %sysevalf(&lm*72) %sysevalf(&bm*72);
%end;
%let tl=%sysevalf((&pl-&lm-&rm)*120);
%let th=%sysevalf((&ph-&tm-&bm)*72);

%*--------------------------------------------------------------------
Center the WM on the page
*--------------------------------------------------------------------;
%if %length(&wm) %then %do;
   %let diag = %sysfunc(sqrt(&ph*&ph+&pl*&pl));
   %let wmlen=%length(&wm);
   %if (&wmfs=) %then %do;
      %let wmfs=%sysfunc(int(&diag*120/(&wmlen+1)));
   %end;
   %let wmls=%sysfunc(ceil(&diag*120/&wmfs));
   %if (&wmls > &wmlen) %then %let wm=%qsysfunc(repeat(%str( ),(&wmls-&wmlen-1)/2))&wm;
   %put NOTE: Watermark calculations: wmlen=&wmlen wmls=&wmls diag=&diag wmfs=&wmfs wm="&wm";
%end;

%*-----------------------------------------------------------------------
Determine fontsize to use based on maximum linesize
Determine fs needed for LS and PS to two decimal places.
Take the smaller of the two, but restrict to between MINFS and MAXFS.
------------------------------------------------------------------------;
%if (&fs = ) %then %do;
%* Calculate FS to fit linesize in 9 inches ;
  %let hfs=%sysfunc(int(&tl*&fontstep/&ls));
  %let hfs=%sysfunc(putn(&hfs/&fontstep,5.2));
%* Calculate FS to fit pagesize in 6.5 inches ;
  %let vfs=%sysfunc(int(&th*&fontstep/&ps));
  %let vfs=%sysfunc(putn(&vfs/&fontstep,5.2));
  %let fs=%sysfunc(min(&maxfs,&vfs,&hfs));
  %let fs=%sysfunc(max(&minfs,&fs));

%put NOTE: &macro Fontsize calculations: Linesize=&ls F=&hfs Pagesize=&ps F=&vfs Fontsize=&fs ;

%end;

%*----------------------------------------------------------------------
Make sure PS used in placing lines is at least as large as is needed
by maximum fontsize so that lines are not widely separated in short
files. Calculate the vertical motion based on PS.
-----------------------------------------------------------------------;
%let minps=%sysfunc(ceil(&th/&maxfs));
%let ps=%sysfunc(max(&ps,&minps));
%let vm=%sysfunc(putn((&th-&filenfs)/&ps,8.2));

%*----------------------------------------------------------------------
Calculate: the number of PDF "objects" to use in array definition.
-----------------------------------------------------------------------;
%let objects=%eval(2*&pages + 7 + 2*&marks);

%*---------------------------------------------------------------------
PDF files are a series of objects.  At the end of the files is a
a cross reference table that points to the beginning of each object in
the file.  To be able to generate the xref table we need to keep track
of how many characters are in each line.  So each put statement must
end with trailing @ and then subroutine is called to put end-of-line
and count number of bytes.
*----------------------------------------------------------------------;

*-----------------------------------------------------------------------;
* Read input file and generate PDF file. ;
*-----------------------------------------------------------------------;
data _null_;
  length string instring filename fname $ &maxchar;
  file &out noprint lrecl=32000 column=col;
  infile &in length=lg end=eof filename=fname eov=eov lrecl=&maxchar;
  retain bytecnt obj 0 lines 0 lineone 1 filename page1 info  ;
  array objbyte (&objects) 8 _temporary_;
  array line (%eval(&maxps+9)) $ &maxchar _temporary_;

  if _n_=1 then do;
    filename=fname;
    put '%PDF-1.3' @;        link output;
    put '25E2E3CFD3'x @;
    link object;
    put '<< /Type /Catalog /Pages 6 0 R /Outlines 2 0 R /PageMode /UseOutlines >>' @;
    link object;
    put "<< /Type /Outlines /Count " marks @;
    if (marks) then do;
      firstmk = 7+2*&pages+2;
      lastmk = 7+2*&pages+2*marks;
      put '/First ' firstmk '0 R /Last ' lastmk '0 R ' @;
    end;
    put '>>' @;
    link object;
    put '<< /Type /Font /Subtype /Type1 /Name /F1'
        ' /BaseFont /Courier /Encoding /WinAnsiEncoding >>' @;
    link object;
    put '<< /Type /Font /Subtype /Type1 /Name /F2'
        ' /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>' @;
    link object;
    put "&lb /PDF /Text &rb" @;
    link object;
    page1=obj+2;
    put "<< /Type /Pages /Count &pages /Kids &lb" @;
    link output;
    do page=page1 to (page1+2*(&pages-1)) by 2;
      put page '0 R' @;
      link output;
    end;
    put "&rb >>" @;
    link output;
*-----------------------------------------------------------------------;
* Document Info ;
*-----------------------------------------------------------------------;
    link object;
    info=obj;
    string="&title"; link protect;
    put '<< /Title (' string +(-1) ')' @; link output;
    string="&subject"; link protect;
    put '/Subject (' string +(-1) ')' @; link output;
    put "/Author (&author)" @; link output;
    put '/Keywords (SAS)' @; link output;
    put "/Creator (&macro)" @; link output;
    put "/Producer (&macro)" @; link output;
    date  =tranwrd(compress(
            put(date(),yymmdd10.) !! put(time(),time8.),':-')
           ,' ','0');
    put '/ModDate (D:' date  +(-1) ')' @; link output;
    put '/CreationDate (D:' date +(-1) ')' @; link output;
    put "/OpenAction &lb " page1 "0 R /FitVisible &rb >>" @; link output;
%if %length(&wm) %then %do;
*--------------------------------------------------------------------;
* Calculate transition matrix for when WM is specified ;
* Rotate by angle A use "cos(A) sin(A) -sin(A) cos(A) 0 0 Tm" ;
*--------------------------------------------------------------------;
   length wmts wmtm $ 200;
   retain wmts wmtm ;
%if (&orient=P) %then %do;
   r=atan((&pl-&lm-&rm)/(&ph-&tm-&bm) );
%end;
%else %do;
   r=atan(-(&ph-&tm-&bm)/(&pl-&lm-&rm) );
%end;
   wmts=compress(put(-&wmfs*.35,10.6));
   wmtm=compbl(put(cos(r),10.6)!!put(sin(r),10.6)!!put(-1*sin(r),10.6)!!put(cos(r),10.6));
%end;

  end;
  input instring $varying. lg;
  if ('1b'x ^=: instring) then do;
    formfeed = (instring =: &pagechar);
    if formfeed or lineone or eov then do;
      eov=0;
      if lineone then lineone=0;
      else link endpage;
*----------------------------------------------------------------------;
* Write the beginning of a page. First create the Page Object with     ;
* indirect pointer to the next object that will contain the Stream that;
* is the actual contents of the page. The second object will be written;
* when end of page is reached so that /Length can be calculated.       ;
*----------------------------------------------------------------------;
      link object;
      next=obj+1;
      put '<< /Type /Page /Parent 6 0 R /Resources '
          '<< /Font << /F1 3 0 R /F2 4 0 R >> /ProcSet 5 0 R >> '
%if (&orient=P) %then
          '/Rotate 90 '
;
          "/MediaBox &lb 0 0 792 612 &rb /Contents "
          next ' 0 R >>' @
      ;
      link output;
      lines=1;
%if (%length(&wm)) %then %do;
%* Rotate by angle A use "cos(A) sin(A) -sin(A) cos(A) 0 0 Tm" ;
      line(lines)= "BT /F2 &wmfs Tf " !! trim(wmtm) !! " &origin Tm "
       /* !! "-%eval(&wmfs/2) Ts " */ !! trim(wmts) !! " Ts " !! "0 Tr 0.9 g (&wm)' 0 Ts ET ";
      lines+1;
%end;
%if (&orient=P) %then %do;
      line(lines)= "BT /F1 &fs Tf &vm TL 0 1 -1 0 &origin Tm 0 Ts 0 Tr 0 g";
%end;
%else %do;
      line(lines)= "BT /F1 &fs Tf &vm TL 1 0 0 1 &origin Tm 0 Ts 0 Tr 0 g";
%end;
    end;
    if instring ne &pagechar then do;
*-----------------------------------------------------------------------;
* Count this line ;
*-----------------------------------------------------------------------;
      lines+1;
  %if (&cc) %then %do;
*-----------------------------------------------------------------------;
* Insert blank lines for double and triple space carriage control. ;
*-----------------------------------------------------------------------;
      if (instring =: '0') then do;
        line(lines)="( )'";
        lines+1;
      end;
      if (instring =: '-') then do;
        line(lines)="( )' ( )'";
        lines+1;
      end;
  %end;
*-----------------------------------------------------------------------;
* Save line into the array for printing at the end of the page. ;
*-----------------------------------------------------------------------;
      string=substr(instring,1+(formfeed or &cc));
      link protect;
      line(lines)='(' !! trim(string) !! ")'";
    end;
  end;
  if eof then do;
    link endpage;
*-----------------------------------------------------------------------;
* Bookmarks take two objects each. One for action and one for text. ;
*-----------------------------------------------------------------------;
    do i=1 to marks;
      set _bkmark_ nobs=marks;
      link object;
      action=obj;
      next=obj+3;
      prev=obj-1;
      target=page1+(page-1)*2;
      put "<< /S /GoTo /D &lb " target "0 R /XYZ &origin null &rb >>" @;
      link object;
      string=bkmark; link protect;
      put '<< /Title (' string +(-1) ')' @;
      if (1 <= i < marks) then put ' /Next ' next '0 R' @;
      if (marks >= i > 1) then put ' /Prev ' prev '0 R' @;
      put ' /Parent 2 0 R /A ' action '0 R >>' @; link output;
    end;

*-----------------------------------------------------------------------;
* Write cross reference table. ;
*-----------------------------------------------------------------------;
%*----------------------------------------------------------------------
NOTE: Can use PUT as no longer need to count bytes.
When CRLF = 1 need to add a space to end of lines to make 20 bytes.
------------------------------------------------------------------------;

    put 'endobj' @;   link output;
    obj+1;
    put 'xref'
      / '0 ' obj
      / "0000000000 65535 f&pad"
    ;
    do i=1 to obj-1;
      put objbyte(i) z10. " 00000 n&pad";
    end;
    put 'trailer'
      / '<< /Size ' obj '/Info ' info '0 R /Root 1 0 R >>'
      / 'startxref'
      / bytecnt
      / '%%EOF'
    ;
  end;
return;

protect:;
*-----------------------------------------------------------------------;
* Protect parenthesis and backslash. Note backslash must be first. ;
*-----------------------------------------------------------------------;
  string=tranwrd(string,'\','\\');
  string=tranwrd(string,'(','\(');
  string=tranwrd(string,')','\)');
return;

endpage:;
*-----------------------------------------------------------------------;
* Write page to output file. ;
*-----------------------------------------------------------------------;
  lines+1;
  line(lines)='ET';
%if (&filenfs) %then %do;
  lines+1;
  string = filename ; link protect;
  line(lines) = "BT /F2 &filenfs Tf &fnorig Tm 0 Tr 0 g";
  lines+1;
  line(lines) = '(' !! trim(string) !! ")' ET";
%end;
  pagesize=0;
  do i = 1 to lines;
    pagesize+length(line(i))+&crlf;
  end;
  link object;
  put '<< /Length ' pagesize '>>' @;  link output;
  put 'stream' @;    link output;
  do i=1 to lines;
    len=length(line(i));
    put line(i) $varying&maxchar.. len @;
    link output;
  end;
  put 'endstream' @; link output;
  filename = fname;
return;

output:;
*-----------------------------------------------------------------------;
* Write string to output file keeping track of number of bytes. ;
*-----------------------------------------------------------------------;
  bytecnt+(col-1)+&crlf;
  put ;
return;

object:;
*--------------------------------------------------------------------;
* Start a new object. Output end of last object and keep track of
* start location.;
*--------------------------------------------------------------------;
  if (col > 1) then link output;
  if obj then do;
    put 'endobj' @; link output;
  end;
  obj+1;
  objbyte(obj)=bytecnt;
  put obj '0 obj' @;
  *link output;
return;

run;

%mend;
