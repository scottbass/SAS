/*=====================================================================
Program Name            : libname_sqlsvr.sas
Purpose                 : Allocate a SQL Server library via ODBC
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv
                          dump_mvars

Originally Written by   : Scott Bass
Date                    : 12AUG2016
Program Version #       : 1.0

======================================================================

Scott Bass (sas_l_739@yahoo.com.au)

This code is licensed under the Unlicense license.
For more information, please refer to http://unlicense.org/UNLICENSE.

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

=======================================================================

Modification History    :

Programmer              : Scott Bass
Date                    : 09MAR2017
Change/reason           : Changed options parameter to augment the
                          internal options rather than completely
                          override them.  This change is to more easily
                          support access=readonly libname option.
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 19SEP2018
Change/reason           : Added PRESERVE_NAMES=YES option since we
                          have now migrated to case-sensitive    
                          collation on SQL Server.
Program Version #       : 1.2

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

%libname_sqlsvr(libref=RLDXHosp)

Allocates the libref RLDXHosp,
with defaults of database=<libref>, schema=dbo, and options as coded
in the macro.

Note that this only works if the database name is a valid SAS libref,
i.e. less than 8 characters.

The macro will select the correct DEV or PROD database based on the
METAPORT option (i.e. which profile is active in EG)

=======================================================================

%libname_sqlsvr(libref=mylib, database=RLDXHosp_prod)

Allocates the libref MYLIB,
with the explicit database=RLDXHosp_prod, schema=dbo, and options as
coded in the macro.

=======================================================================

%libname_sqlsvr(libref=TMP, database=RLDXHosp_dev, schema=tmp)

Allocates the libref TMP,
with the explicit database=RLDXHosp_dev, schema=tmp, and options as
coded in the macro.

=======================================================================

%libname_sqlsvr(
   libref=RLDXHosp,
   options=
      bulkload=yes
      schema=dbo
      reread_exposure=yes
      DBINDEX=YES
      UPDATE_LOCK_TYPE=NOLOCK
      IGNORE_READ_ONLY_COLUMNS=YES
)

Allocates the libref RLDXHosp,
with defaults of database=<libref>, and additional options that
augment the internal options coded in the macro.

Note that the explicit options should augment the internal options
coded in the macro.  If any of the options match the internal options,
the invocation options should override the internal options since
"last option wins".

=======================================================================

%libname_sqlsvr(libref=RLDXHosp, server=FOO, port=12345)

Allocates the libref RLDXHosp,
with defaults of database=<libref>, schema=dbo,
and server=FOO, port=12345.

-----------------------------------------------------------------------
Notes:

The macro sets these internal macro variables:

%let lev = %sysfunc(ifc(%sysfunc(getoption(METAPORT)) eq 8561,Lev1,Lev2));
%let env = %sysfunc(ifc(%sysfunc(getoption(METAPORT)) eq 8561,prod,dev));

So, if METAPORT=8561 then lev=Lev1 and env=prod.
Otherwise, lev=Lev2 and env=dev.

If the DATABASE parameter is blank, then database parameter will
default to &libref._&env.

Otherwise, the DATABASE parameter will be used, irrespective of the
EG environment.  IOW, you can allocate a production database from
Lev2 by explicitly specifying the database.

The default SCHEMA is dbo.

Currently only Trusted Connection is supported and is hard coded.

---------------------------------------------------------------------*/

%macro libname_sqlsvr
/*---------------------------------------------------------------------
Allocate a SQL Server library via ODBC
---------------------------------------------------------------------*/
(LIBREF=       /* Libref to allocate (REQ)                           */
,DATABASE=     /* Database to use (Opt).                             */
               /* If blank then LIBREF_<env> is used.                */
,SCHEMA=dbo    /* Default database schema (REQ).  Default is dbo.    */
,OPTIONS=      /* Libref options (Opt).  If specified, the options   */
               /* completely override (as opposed to augment) the    */
               /* options embedded in this macro.                    */
,SERVER=SVDCMHPRRLSQD01
               /* SQL Server machine name (REQ).                     */
,PORT=         /* SQL Server machine port (REQ).                     */
               /* Note: the port number for DOHNSCLDBSASBI is 54491  */

);

%local macro parmerr lev env _server;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(LIBREF,       _req=1,_words=0,_case=N)
%parmv(DATABASE,     _req=0,_words=0,_case=N)
%parmv(SCHEMA,       _req=1,_words=0,_case=N)
%parmv(OPTIONS,      _req=0,_words=1,_case=N)
%parmv(SERVER,       _req=1,_words=0,_case=N)
%parmv(PORT,         _req=0,_words=0,_case=N,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

%* set the correct environment ;
%let lev = %sysfunc(ifc(%sysfunc(getoption(METAPORT)) eq 8561,Lev1,Lev2));
%let env = %sysfunc(ifc(%sysfunc(getoption(METAPORT)) eq 8561,prod,dev));

%* If the database was not specified, set it to the <libref>_<env> ;
%if (&DATABASE eq ) %then %let database=&libref._&env;

%* set the connection string ;
%let _server=&SERVER;
%if (&PORT ne ) %then %let _server=&_server,&PORT;

%let connect = NOPROMPT="Driver={SQL Server Native Client 10.0};Server=&_server;Database=&database;Trusted_Connection=yes;";
/* %let connect = NOPROMPT="Driver={ODBC Driver 11 for SQL Server};Server=&_server;Database=&database;Trusted_Connection=yes;"; */

%* set any internal hardcoded libname options ;
%*let internal_options = bulkload=yes schema=&schema insertbuff=100 readbuff=1000 direct_exe=delete connection=global autocommit=yes dbcommit=50;
%*let internal_options = bulkload=yes schema=&schema reread_exposure=yes DBINDEX=YES UPDATE_LOCK_TYPE=NOLOCK IGNORE_READ_ONLY_COLUMNS=YES;
%*let internal_options = bulkload=yes schema=&schema reread_exposure=yes DBINDEX=YES UPDATE_LOCK_TYPE=NOLOCK;
%*let internal_options = bulkload=yes schema=&schema insertbuff=100 readbuff=1000 direct_exe=delete connection=global;
%*let internal_options = bulkload=yes schema=&schema direct_exe=delete connection=global;
%*let internal_options = bulkload=yes schema=&schema connection=global;
%let internal_options = schema=&schema bulkload=yes dbcommit=100000 direct_exe=delete preserve_names=yes;
%*let internal_options = schema=&schema;

%* issue the libname statement ;
%put %sysfunc(repeat(=,80));
%put LIBREF:           %upcase(&libref);
%put CONNECT:          &connect;
%put INTERNAL OPTIONS: %sysfunc(compbl(%superq(internal_options)));
%put USER OPTIONS:     %sysfunc(compbl(%superq(options)));
%put %sysfunc(repeat(=,80));
%put;
libname &libref odbc &connect &internal_options &options;

%quit:

%mend;

/******* END OF FILE *******/
