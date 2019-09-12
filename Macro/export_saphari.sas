/*=====================================================================
Program Name            : export_saphari.sas
Purpose                 : Export SAS dataset or SQL Server table
                          to Saphari.
SAS Version             : SAS 9.4
Input Data              : SAS dataset or SQL Server table
Output Data             : SAS dataset(s) and view(s) required for use
                          by Saphari

Macros Called           : parmv, create_format, nobs

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

* create a dummy source dataset ;
libname sasout "%sysfunc(pathname(work))";

* RLCS Server ;
%libname_sqlsvr(libref=DMT,server=SVDCMHPRRLSQD01,port=,database=RLCS_prod,schema=dmt)

* you may have to modify the based on the current vwAP_FLAT_SAS* views available ;
data sasout.apdc_flat;
   set dmt.vwAP_FLAT_SAS_49 (obs=1000);
run;

%export_saphari(
   data=sasout.apdc_flat
   ,prefix=apdc
)

Create a hoist view for sasout_apdc_flat using flattened view
from RLCS Server.

=======================================================================

* create a dummy source dataset ;
libname sasout "%sysfunc(pathname(work))";

* Saphari Prod Server ;
%libname_sqlsvr(libref=DMT,server=SVDCMHPRSDWSQD1,port=,database=RLDXHosp,schema=dmt)

* you may have to modify the based on the current vwAP_FLAT_SAS* views available ;
data sasout.apdc_flat;
   set dmt.vwAP_FLAT_SAS (obs=1000);
run;

%export_saphari(
   data=sasout.apdc_flat
   ,prefix=apdc
)

Create a hoist view for sasout.apdc_flat using flattened view
from Saphari Prod Server.

=======================================================================

* create a dummy source dataset ;
libname sasout "%sysfunc(pathname(work))";

* Saphari Prod Server ;
%libname_sqlsvr(libref=DMT,server=SVDCMHPRSDWSQD1,port=,database=RLDXHosp,schema=dmt)

* you may have to modify the based on the current vwAP_FLAT_SAS* views available ;
data sasout.apdc_flat;
   set dmt.vwAP_FLAT_SAS (obs=1000);
run;

%export_saphari(
   data=sasout.apdc_flat (where=(age_grouping_recode=13))
   ,prefix=apdc
)

Although this usage is rare, it is possible to create a hoist view
where the source dataset has a dataset option (in this case a where clause)

=======================================================================

Error checking:

%export_saphari(
)

Fails, source dataset and hoist name prefix parameters are required.

%export_saphari(
   data=sasout.apdc_flat
)

Fails, hoist name prefix is required.

%export_saphari(
   data=sasout.DoesNotExist
   ,prefix=apdc
)

Fails, source dataset sasout.doesnotexist does not exist.

data work.apdc_flat;
   set sasout.apdc_flat;  * assumes you have run the above examples ;
run;

%export_saphari(
   data=work.apdc_flat
   ,prefix=apdc
)

Fails, work.apdc_flat exists, but must be in the sasout library.

-----------------------------------------------------------------------
Notes:

---------------------------------------------------------------------*/

%macro export_saphari
/*---------------------------------------------------------------------
Export SAS dataset or SQL Server table to Saphari.
---------------------------------------------------------------------*/
(DATA=         /* Dataset to export (REQ).                           */
               /* Data set options, such as a where clause, may be   */
               /* specified.                                         */
,PREFIX=       /* Output dataset name prefix (REQ).                  */
               /* Usual dataset name prefixes are                    */
               /* APDC, EDDC, DTH, or CODURF, but any dataset name   */
               /* prefix can be specified.                           */
);

%local macro parmerr;
%local _temp _pos _options _inlib _inds;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=1,_words=1,_case=N)  /* words=1 allows ds options */
%parmv(PREFIX,       _req=1,_words=0,_case=N)

%if (&parmerr) %then %return;

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

%* parse the source dataset name ;
%let _inlib = %scan(%superq(_temp),1,.);
%let _inds  = %scan(%superq(_temp),2,.);

%* if one-level source dataset was specified, check the USER system option, otherwise use WORK ;
%if (&_inds eq ) %then %do;
   %let _inds = &_inlib;
   %let _inlib = %sysfunc(getoption(USER));
   %let _inlib = %sysfunc(compress(&_inlib,%str(%'%")));
   %if (&_inlib eq ) %then %let _inlib=WORK;
%end;
%let _inlib=%upcase(&_inlib);

%* the source dataset must exist in the SASOUT library ;
%if (%upcase(&_inlib) ne SASOUT) %then %do;
   %let syscc=8;
   %parmv(_msg=The source dataset %superq(_temp) must exist in the SASOUT library)
   %return;
%end;

%***** NOTE: This code is no longer required, but I have commented it out rather than deleting it ***** ;
%macro comment;
%* create a format defining fiscal years from 2000 to 2030 ;
data cntlin;
   length startdate enddate 8 start end $16 label $40;
   do year=2000 to 2030;
      startdate=mdy(7,1,year);
      start    =put(startdate,best.-L);
      enddate  =mdy(6,30,year+1);
      end      =put(enddate,best.-L);
      label    =cats(&prefix,put(startdate,year2.),put(enddate,year2.));
      output;
   end;
   format startdate enddate date9.;
   keep startdate enddate start end label;
run;

%create_format(
   data=cntlin
   ,name=fiscalyear
   ,type=num_format
   ,start=start
   ,end=end
)

%* create a list of all possible output datasets ;
proc sql noprint;
   select label into :datasets separated by " " from cntlin;
quit;

%* create helper macros to build SAS syntax using the %loop macro ;
%macro dsnames;
sasout.&word
%mend;
%macro select;
when(&word) output sasout.&word;
%mend;
%macro dlt;  %* "delete" and "del" are reserved words ;
%if (%nobs(&word) eq 0) %then delete %scan(&word,2,.);;
%mend;

%* split input dataset into fiscalyear datasets ;
data %loop(&datasets,mname=dsnames);
   set &data;
   select(put(episode_end_date,fiscalyear.));
      %loop(&datasets,mname=select);
   end;
run;

%* delete any empty datasets ;
proc datasets lib=sasout nowarn nolist;
   %loop(&datasets,mname=dlt);
quit;
%mend comment;

%* an upstream requirement is that the input dataset is in the SASOUT library ;
%* create a view of that dataset with column names compatible with HOIST ;
%macro rename(source,target);
%do i=1 %to 50;
rename &source%sysfunc(putn(&i,z2.))=&target%eval(&i+1);
%end;
%mend;

data sasout.&prefix._hoist_names / view=sasout.&prefix._hoist_names;
   set &data;
   rename acute_flag                               = acuteflg;
   admdt= dhms(episode_start_date,0,0,episode_start_time);
   rename age_grouping_recode                      = Agegrp;
   rename age_recode_years                         = age_recode;
   rename ar_drg                                   = ardrg;
   rename ar_drg_version                           = ardrg_version;
   rename area_identifier                          = area_version_facility;
   rename birth_date                               = dob;
   rename block_num_p                              = procbl1;
/*   rename condition_onset_flagE1                   = coflag52;*/
/*   rename condition_onset_flagE2                   = coflag53;*/
   rename condition_onset_flag_p                   = coflag1;
   rename cost_weight_a                            = cost_wt_a;
   rename cost_weight_b                            = cost_wt_b;
   rename cost_weight_c                            = cost_wt_c;
   rename cost_weight_d                            = cost_wt_d;
   rename cost_weight_e                            = cost_wt_e;
   rename cost_weight_f                            = cost_wt_f;
   rename country_of_birth_sacc                    = COBSACC;
   rename days_in_psych_unit                       = psychday;
/*   rename diagnosis_codeE1                         = icd10d52;*/
/*   rename diagnosis_codeE2                         = icd10d53;*/
   rename diagnosis_code_p                         = icd10d1;
   rename dva_card_type                            = DVAType;
   rename emergency_status_recode                  = emergncy;
   rename episode_day_stay_los_recode              = dolos;
   rename episode_end_date                         = sepdate;
   rename episode_end_time                         = septime;
   rename episode_leave_days_total                 = leaveday;
   rename episode_length_of_stay                   = los;
   rename episode_of_care_type                     = csrvccat;
   rename episode_start_date                       = admdate;
   rename episode_start_time                       = admtime;
   rename facility_identifier_recode               = hoscode;
   rename facility_trans_from_recode               = trnsfrom;
   rename facility_trans_to_recode                 = tfrhosp;
   rename facility_type                            = hostype;
   rename financial_class                          = fin_class;
   rename financial_program                        = program;
   rename health_insurance_on_admit                = insstat;
   rename hours_in_icu                             = icuhours;
   rename hours_on_mech_ventilation                = hrsmechv;
   rename indigenous_status                        = abtsi;
   rename infant_start_weight                      = nweight;
   rename involuntary_days_in_psych                = invpsych;
   rename last_psych_admission_date                = psyyrlst;
   rename marital_status                           = marital;
   rename mdc                                      = mdcandrg;
   rename mode_of_separation_recode                = nsepmode;
   rename patient_postcode                         = pcode;
   rename payment_status_on_sep                    = payst_v4;
   rename peer_group                               = hcdbpeer;
   rename procedure_code_p                         = MBS_EP1;
   rename procedure_date_p                         = procdate1;
   rename procedure_location_p                     = procfl1;
   rename qualified_bed_days_recode                = qualday;
   rename readmitted_within_28_days                = readmit;
   rename recognised_ph_flag                       = rph_flag;
   rename referred_to_on_separation_recode         = refertoc;
   sepdt= dhms(episode_end_date,0,0,episode_end_time);
   rename source_of_referral_recode                = srcrefc;
   rename state_of_residence_recode                = state_of_residence;
   rename unit_type_on_admission                   = unittyp2;
   rename unqual_baby_bed_days                     = unqalday;

   %rename(block_num_,procbl);
   %rename(condition_onset_flag_,coflag);
   %rename(diagnosis_code_,icd10d);
   %rename(procedure_code_,MBS_EP);
   %rename(procedure_date_,procdate);
   %rename(procedure_location_,procfl);
run;

%mend;

/******* END OF FILE *******/
