/*=====================================================================
Program Name            : export_rldx.sas
Purpose                 : Wrapper macro to call various child macros
                          to export a SAS dataset or SQL Server table
                          to various target formats.
SAS Version             : SAS 9.4
Input Data              : SAS dataset or SQL Server table
Output Data             : Exported data in various formats

Macros Called           : parmv
                          export_dlm
                          export_dbms
                          export_csv
                          export_spss
                          export_stata
                          export_saphari

Originally Written by   : Scott Bass
Date                    : 04SEP2019
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

%let path=\\sascs\linkage\RL_content_snapshots\Temp;  %* edit to suit your requirements ;

* create a dummy source dataset ;
options dlcreatedir;
libname sasout "%sysfunc(pathname(work))\temp";

* RLCS Server ;
%libname_sqlsvr(libref=DMT,server=SVDCMHPRRLSQD01,port=,database=RLCS_prod,schema=dmt)

* you may have to modify based on the current vwAP_FLAT_SAS* views available ;
data sasout.apdc_flat;
   set dmt.vwAP_FLAT_SAS_49;
   where year(episode_end_date)=2010;
   if _n_ > 1000 then stop;
run;

%export_rldx(
   data=sasout.apdc_flat
   ,prefix=apdc
   ,export_saphari=Y
)

Export sasout.apdc_flat to Saphari format,
which just creates a hoist formatted view.

=======================================================================

* the remaining examples assume you have created the test data ;
* in the first example. ;

%export_rldx(
   data=sasout.apdc_flat (where=(month(episode_end_date) in (1,2,3)))
   ,outlib=work
   ,outdata=apdc_subset
   ,export_sas=Y
)

Export sasout.apdc_flat to sasout.apdc_subset,
with episode_end_dates occurring in the first calendar quarter.

=======================================================================

%export_rldx(
   data=sasout.apdc_flat
   ,path="&path"
   ,replace=Y
   ,header=Y
   ,label=N
   ,export_csv=Y
)

Export sasout.apdc_flat to CSV file
\\sascs\linkage\RL_content_snapshots\Temp\apdc_flat.csv

=======================================================================

%export_rldx(
   data=sasout.apdc_flat
   ,path="&path"
   ,replace=Y
   ,label=N
   ,export_xlsx=Y
)

Export sasout.apdc_flat to XLSX file
\\sascs\linkage\RL_content_snapshots\Temp\apdc_flat.xlsx

=======================================================================

%export_rldx(
   data=sasout.apdc_flat (where=(month(episode_end_date) in (1,2,3)))
   ,path="&path\apdc_subset.sav"
   ,replace=Y
   ,label=N
   ,export_spss=Y
)

Export sasout.apdc_flat to SPSS file
\\sascs\linkage\RL_content_snapshots\Temp\apdc_subset.sav

=======================================================================

%export_rldx(
   data=sasout.apdc_flat (where=(month(episode_end_date) in (1,2,3)))
   ,path="&path\apdc_subset.dta"
   ,replace=Y
   ,label=N
   ,export_stata=Y
)

Export sasout.apdc_flat to STATA file
\\sascs\linkage\RL_content_snapshots\Temp\apdc_subset.dta

=======================================================================

* You may want to delete all files in the target path  ;
* and work.apdc_final before running this... ;

%export_rldx(
   data=sasout.apdc_flat
   ,path="&path"
   ,replace=Y
   ,header=Y
   ,label=N
   ,outlib=work
   ,outdata=apdc_final
   ,prefix=apdc
   ,export_saphari=Y
   ,export_sas=Y
   ,export_csv=Y
   ,export_xlsx=Y
   ,export_spss=Y
   ,export_stata=Y
)

Export sasout.apdc_flat to "the lot" (all specified formats).

In this scenario, you need to specify a directory only
for the PATH parameter, and allow the output files to 
be automatically named.

-----------------------------------------------------------------------
Notes:

---------------------------------------------------------------------*/

%macro export_rldx
/*---------------------------------------------------------------------
Wrapper macro to call various child macros to export a SAS dataset 
or SQL Server table to various target formats.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */

               /* ##### EXTERNAL FILES (DLM OR DBMS) #####           */

,PATH=         /* Output directory or file path (Opt).               */
               /* Either a properly quoted physical file             */
               /* (single or double quotes), or an already allocated */
               /* fileref may be specified.                          */
,REPLACE=N     /* Replace output file? (Opt).                        */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,LABEL=N       /* Use data set labels instead of names? (Opt).       */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
               /* If the data set variable does not have a label     */
               /* then the variable name is used.                    */

               /* ##### CSV FILE ONLY #####                          */

,HEADER=Y      /* Output a header row? (Opt).                        */
               /* Default value is YES.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
               /* If the data set variable does not have a label     */
               /* then the variable name is used.                    */
,LRECL=32767   /* Logical record length for output file (Opt).       */
               /* Default value is 32767 (32K)                       */

               /* ##### SAPHARI #####                                */

,PREFIX=       /* Output HOIST view name prefix (Opt).               */
               /* Usual dataset name prefixes are                    */
               /* APDC, EDDC, DTH, or CODURF, but any dataset name   */
               /* prefix can be specified.                           */

               /* ##### SAS DATASETS #####                           */

,OUTLIB=       /* Output library (Opt).                              */
,OUTDATA=      /* Output dataset name (Opt).                         */
               /* If specified, the source dataset is copied         */
               /* to the target library with the source dataset      */
               /* name, then the target dataset is renamed           */
               /* to the OUTDATA name.                               */

               /* ##### DESIRED OUTPUT FORMATS #####                 */

,EXPORT_SAPHARI=N  
               /* Export to Saphari format? (Opt).                   */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
,EXPORT_SAS=N        
               /* Export to SAS format? (Opt).                       */
               /* Same options as per EXPORT_SAPHARI                 */
,EXPORT_CSV=N        
               /* Export to CSV format? (Opt).                       */
               /* Same options as per EXPORT_SAPHARI                 */
,EXPORT_XLSX=N       
               /* Export to XLSX format? (Opt).                      */
               /* Same options as per EXPORT_SAPHARI                 */
,EXPORT_SPSS=N       
               /* Export to SPSS format? (Opt).                      */
               /* Same options as per EXPORT_SAPHARI                 */
,EXPORT_STATA=N      
               /* Export to STATA format? (Opt).                     */
               /* Same options as per EXPORT_SAPHARI                 */
);

%global syscc;
%local macro parmerr;
%local _temp _pos _options;
%let macro = &sysmacroname;


%* check input parameters ;
%parmv(DATA,            _req=1,_words=1,_case=N)  /* words=1 allows multiple datasets */
%parmv(PATH,            _req=0,_words=1,_case=N)
%parmv(REPLACE,         _req=0,_words=0,_case=U,_val=0 1)
%parmv(LABEL,           _req=0,_words=0,_case=U,_val=0 1)
%parmv(HEADER,          _req=0,_words=0,_case=U,_val=0 1)
%parmv(LRECL,           _req=0,_words=0,_case=U,_val=POSITIVE)

%parmv(OUTLIB,          _req=0,_words=0,_case=U)
%parmv(OUTDATA,         _req=0,_words=0,_case=U)

%parmv(EXPORT_SAPHARI,  _req=0,_words=0,_case=U,_val=0 1)
%parmv(EXPORT_SAS,      _req=0,_words=0,_case=U,_val=0 1)
%parmv(EXPORT_CSV,      _req=0,_words=0,_case=U,_val=0 1)
%parmv(EXPORT_XLSX,     _req=0,_words=0,_case=U,_val=0 1)
%parmv(EXPORT_SPSS,     _req=0,_words=0,_case=U,_val=0 1)
%parmv(EXPORT_STATA,    _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %return;

%* abort on upstream error (continue on upstream warning);
%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%* parse off dataset options (usually a where clause) ;
%let _temp = %superq(data);
%let _pos = %sysfunc(findc(%superq(data),%str(%()));
%if (&_pos) %then %do;
   %let _temp = %substr(%superq(data),1,&_pos-1);
   %let _options = %substr(%superq(data),&_pos);
%end;

%* does the source dataset exist? ;
%if not (%sysfunc(exist(%superq(_temp),DATA)) or %sysfunc(exist(%superq(_temp),VIEW))) %then %do;
   %let syscc=8;
   %parmv(_msg=Source dataset %superq(_temp) does not exist)
   %return;
%end;

%* process each selected option by calling the child macros ;

%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%if (&export_saphari eq 1) %then %do;
   %export_saphari(
      data=%superq(data)
      ,prefix=%superq(prefix)
   )
%end;

%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%if (&export_sas eq 1) %then %do;
   %export_sas(
      data=%superq(data)
      ,outlib=%superq(outlib)
      ,outdata=%superq(outdata)
   )
%end;

%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%if (&export_csv eq 1) %then %do;
   %export_csv(
      data=%superq(data)
      ,path=%superq(path)
      ,replace=%superq(replace)
      ,label=%superq(label)
      ,header=%superq(header)
      ,lrecl=%superq(lrecl)
   )
%end;

%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%if (&export_xlsx eq 1) %then %do;
   %export_xlsx(
      data=%superq(data)
      ,path=%superq(path)
      ,replace=%superq(replace)
      ,label=%superq(label)
   )
%end;

%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%if (&export_spss eq 1) %then %do;
   %export_spss(
      data=%superq(data)
      ,path=%superq(path)
      ,replace=%superq(replace)
      ,label=%superq(label)
   )
%end;

%if (&syscc gt 4) %then %do;
   %parmv(_msg=Export aborted due to upstream error.  Submit %nrstr(%let syscc=0;) to reset error)
   %return;
%end;

%if (&export_stata eq 1) %then %do;
   %export_stata(
      data=%superq(data)
      ,path=%superq(path)
      ,replace=%superq(replace)
      ,label=%superq(label)
   )
%end;

%mend;

/******* END OF FILE *******/
