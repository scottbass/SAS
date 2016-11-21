%** V0000 *****************************************************************************************;
%** Program   : log2pdf.sas                                                                      **;
%** On LAN    : No                                                                               **;
%** On Server : Yes                                                                              **;
%** Date      : 17AUG2012                                                                        **;
%** Author    : Michael Dixon                                                                    **;
%** Owner     : BCA                                                                              **;
%** Purpose   : Convert SAS Log file into a PDF file including simple Syntax Highlighting        **;
%**                                                                                              **;
%** Parms     : LOGFILE   - Required, full path and filename of SAS log file to convert          **;
%**           : PDFFILE   - Required, full path and filename of PDF file to create               **;
%** ---------------------------------------------------------------------------------------------**;
%** History                                                                                      **;
%**                                                                                              **;
%** Version   :                                                                                  **;
%** Date      :                                                                                  **;
%** Author    :                                                                                  **;
%** Reason    :                                                                                  **;
%**                                                                                              **;
%**                                                                                              **;
%**************************************************************************************************;
%macro log2pdf(LOGFILE= /* Full path and filename of log file */
              ,PDFFILE= /* Full path and filename of PDF to create */
              );

  filename inlog "&LOGFILE";
  data mylog;
    infile inlog truncover;
    length line $ 1024;
    label line="";
    input;
    line=_infile_;
    * Start of Page Special Character ;
    if _N_=1 or substr(line,1,1)="" or line=" " then delete;
  run;
  filename inlog clear;

  title "%SCAN(&LOGFILE,-1,%str(\))";
  footnote '';

  options linesize=132 nonumber nodate;

  ods pdf uniform file="&PDFFILE" style=minimal notoc;

  proc report data=MYLOG nowd style(REPORT)={rules=NONE} style(REPORT)={cellpadding=0};
    column line;
    define line / display;
    compute line;
      if substr(line,1,6)="ERROR:"   then call define(_col_,"style","style={background=red}");
      else
      if substr(line,1,8)="WARNING:" then call define(_col_,"style","style={foreground=green}");
      else
      if substr(line,1,5)="NOTE:"    then call define(_col_,"style","style={foreground=blue}");
    endcomp;
  run;


  ods pdf close;
%mend;