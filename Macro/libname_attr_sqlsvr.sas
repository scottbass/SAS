/*=====================================================================
Program Name            : libname_attr_sqlsvr.sas
Purpose                 : Retrieve libname attributes 
                          (server name, database name, default schema)
                          from an ODBC libname allocated to a 
                          SQL Server instance.
SAS Version             : SAS 9.3
Input Data              : N/A
Output Data             : N/A

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 22Jun2018
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

* no additional options, esp. schema= ;

libname FOO ODBC 
   NOPROMPT="Driver={SQL Server Native Client 10.0};
   Server=SVDCMHPRRLSQD01;
   Database=master;
   Trusted_Connection=yes;"
;

%libname_attr_sqlsvr(FOO);

* the macro prints these, but show that they are global macro variables ;
%put &=server &=dbname &=schema &=schema2;

* &schema is the schema as specified by the libname allocation ;
* &schema2 is the default schema for this connection to SQL Server ;

=======================================================================

* specify a schema ;
libname FOO ODBC 
   NOPROMPT="Driver={SQL Server Native Client 10.0};
   Server=SVDCMHPRRLSQD01;
   Database=RLCS_dev;
   Trusted_Connection=yes;"
   bulkload=yes schema=content
;

libname BAR ODBC 
   NOPROMPT="Driver={SQL Server Native Client 10.0};
   Server=SVDCMHPRRLSQD01;
   Database=master;
   Trusted_Connection=yes;"
;

%libname_attr_sqlsvr(FOO,prefix=yes);
%libname_attr_sqlsvr(BAR,prefix=yes);

%put &=foo_server &=foo_dbname &=foo_schema &=foo_schema2;
%put &=bar_server &=bar_dbname &=bar_schema &=foo_schema2;

=======================================================================

* demonstrate use in explicit pass-through ;
libname FOO ODBC 
   NOPROMPT="Driver={SQL Server Native Client 10.0};
   Server=SVDCMHPRRLSQD01;
   Database=RLCS_dev;
   Trusted_Connection=yes;"
   bulkload=yes schema=content
;

libname BAR ODBC 
   NOPROMPT="Driver={SQL Server Native Client 10.0};
   Server=SVDCMHDVSDWSQD1;
   Database=master;
   Trusted_Connection=yes;"
   schema=sys
;

%libname_attr_sqlsvr(FOO,prefix=yes);  * prefix=yes, so FOO_dbname, etc. ;
%libname_attr_sqlsvr(BAR,prefix=no);   * prefix=no, so dbname, schema, etc. ;

proc sql;
   connect using foo;
   select * from connection to foo (
      SELECT TOP 10 facility_identifier, facility_name, facility_type 
      FROM &foo_dbname..&foo_schema..FACILITY
   );
   connect using bar;
   select * from connection to bar (
      SELECT name, database_id, collation_name 
      FROM &dbname..&schema..databases
   );
quit;

-----------------------------------------------------------------------
Notes:

The main purpose of this macro is to retrieve metadata (macro variables)
about a given ODBC libname, knowing nothing more than the libname.

This is especially useful if the library is allocated in an external
program, or via the metadata engine.

The purpose of the metadata is to make explicit pass-through code
easier to maintain.  The idea is to allocate a library for every 
server, database, and schema you need to access, even if the data could
be accessed via a single connection with two-,three-, or four-level
(i.e. linked server) names.

This approach gives you visibility of all the relevant tables in the
SAS libraries, makes it easy to write metadata-driven code (i.e.
using macro variables), and makes it easy to maintain your code if
server or database names change in the future.

This macro must be called outside data step or PROC context, i.e. in
"open code", but it generally only needs to be called once.

The the prefix=yes parameter is specified, the macro variables returned
are <libref>_server, <libref>_dbname, and <libref>_schema.
Otherwise server, dbname, and schema are returned.

Keep in mind this WOULD cause a code maintenance issue if the libnames
ever changed in the future.  If this is an issue, you can use this
approach:

%libname_attr_sqlsvr(FOO,prefix=no);
%let lib1_server=&server;%let lib1_dbname=&dbname;%let lib1_schema=&schema;

%libname_attr_sqlsvr(BAR,prefix=yes);
%let lib2_server=&server;%let lib2_dbname=&dbname;%let lib2_schema=&schema;

Since the macro variable name prefix is now static, it will not change
if the libname changes in the future.

---------------------------------------------------------------------*/

%macro libname_attr_sqlsvr
/*---------------------------------------------------------------------
Retrieve libname attributes (server name, database name, default schema) 
from an ODBC libname allocated to a SQL Server instance.
---------------------------------------------------------------------*/
(LIBREF        /* Libref for ODBC libname allocated to a SQL Server  */
               /* instance (REQ).                                    */
,PREFIX=N      /* Add the libref as a prefix to the returned macro   */
               /* variables? (Opt).                                  */
               /* Default value is NO.  Valid values are:            */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE           */
               /* OFF N NO F FALSE and ON Y YES T TRUE               */
               /* (case insensitive) are acceptable aliases for      */
               /* 0 and 1 respectively.                              */
);

%local macro parmerr dsid _engine _server _dbname _schema _schema2;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(LIBREF,       _req=1,_words=0,_case=U)
%parmv(PREFIX,       _req=0,_words=0,_case=U,_val=0 1)

%if (&parmerr) %then %goto quit;

%* additional error checking ;

%* is the libref allocated? ;
%if (%sysfunc(libref(&libref)) ne 0) %then %do;
   %parmv(_msg=The libref &libref is not allocated)
   %goto %quit;
%end;

%* is the libref an ODBC library? ;
%* open sashelp.vlibnam ;
%let dsid=%sysfunc(open(sashelp.vlibnam (where=(upcase(libname)="%upcase(&libref)"))));

%* was the open successful? ;
%if (&dsid le 0) %then %do;
   %parmv(_msg=Unable to open sashelp.vlibnam)
   %goto quit;
%end;

%* fetch the (only) row ;
%let rc=%sysfunc(fetchobs(&dsid,1));
%if (&rc ne 0) %then %do;
   %parmv(_msg=Unable to fetch row from sashelp.vlibnam)
   %goto %quit;
%end;

%* get the engine ;
%let _engine=%sysfunc(getvarc(&dsid,
             %sysfunc(varnum(&dsid,ENGINE))));
%if (&_engine ne ODBC) %then %do;
   %parmv(_msg=Libref &libref is not allocated with the ODBC engine)
   %goto %quit;
%end;

%* get the schema as set by the libname statement ;
%let _schema=%sysfunc(getvarc(&dsid,
             %sysfunc(varnum(&dsid,SYSVALUE))));

%* get the remaining attributes from SQL Server itself ;
proc sql noprint;
   option nolabel;
   connect using &libref;
   select server
         ,dbname
         ,schema2
   into   :_server trimmed
         ,:_dbname trimmed
         ,:_schema2 trimmed
   from   connection to &libref (
   SELECT @@servername  AS [server]
         ,DB_NAME()     AS [dbname]
         ,SCHEMA_NAME() AS [schema2]
   );
quit;

%if (&prefix eq 1) %then %do;
   %global &libref._server &libref._dbname &libref._schema &libref._schema2;
   %let &libref._server=&_server;
   %let &libref._dbname=&_dbname;
   %let &libref._schema=&_schema;
   %let &libref._schema2=&_schema2;

   %* cannot use the &=mvarname syntax ;
   %*put %upcase(&libref._server)=&&&libref._server %upcase(&libref._dbname)=&&&libref._dbname %upcase(&libref._schema)=&&&libref._schema %upcase(&libref._schema2)=&&&libref._schema2;
%end;
%else %do;
   %global server dbname schema schema2;
   %let server=&_server;
   %let dbname=&_dbname;
   %let schema=&_schema;
   %let schema2=&_schema2;

   %*put &=server &=dbname &=schema &=schema2;
%end;

%quit:
%if (&dsid gt 0) %then %let dsid=%sysfunc(close(&dsid));

%mend;

/******* END OF FILE *******/
