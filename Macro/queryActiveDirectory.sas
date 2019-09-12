/*=====================================================================
Program Name            : queryActiveDirectory.sas
Purpose                 : Execute an LDAP query against Active Directory
SAS Version             : SAS 9.2
Input Data              : Active Directory
Output Data             : WORK.LDAP data step view of Active Directory

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 06JUL2012
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

Modification History    : 

Programmer              : Scott Bass
Date                    : 30JUN2013
Change/reason           : Changed the base DN to the default base DN
                          configured in Active Directory.
                          This change is due to changes by IT to the
                          OU structure for user objects.
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 06JUL2016
Change/reason           : Changed the base DN to the default base DN
                          configured in Active Directory for Medibank.
Program Version #       : 1.2

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

* return all user information for the current user (&sysuserid) ;
* specify debug= parameter for informational or full debugging ;
* Note:  Because it creates a data step view, you will not see ;
* anything in the log until you execute the proc print ;

* makes debgging info in log easier to read ;
options ls=max;

* makes proc print output easier to read ;
options ps=max nocenter;

%queryActiveDirectory;
%queryActiveDirectory(debug=I)
%queryActiveDirectory(debug=F)

proc print;
  where length(value) < 60;
run;

=======================================================================

* return all user information for a particular user ;
%queryActiveDirectory(
  filter=(&(samaccountname=rbowden)(objectclass=user))
  ,debug=I
);

proc print;
  var name value;
  format value $100.;
run;

=======================================================================

* return full name, first name, last name, and email address for a particular user ;
%queryActiveDirectory(
  filter=(samaccountname=rbowden)
  ,attrs=cn givenName sn mail
  ,debug=F
);

proc print;
run;

=======================================================================

* return full name of all users in the Sydney branch of the Active Directory tree ;
* whose first names begin with "S" ;
%queryActiveDirectory(
  base=%str(OU=Sydney,OU=BUPAUsers,DC=internal,DC=bupa,DC=com,DC=au)
  ,filter=(givenName=S*)
  ,attrs=cn
);

proc print;
  var value;
run;

=======================================================================

* return full name of all users in the Melbourne branch of the Active Directory tree ;
* whose first or last names contain "will" ;
* (queries are case-insensitive by default) ;
%queryActiveDirectory(
  base=%str(OU=Melbourne,OU=BUPAUsers,DC=internal,DC=bupa,DC=com,DC=au)
  ,filter=(|(givenName=*will*)(sn=*will*))
  ,attrs=cn
);

proc print;
  var value;
run;

=======================================================================

* return all user objects (may take a long time to run) ;
* in fact, it fails due ldap server sizelimit exceeded ;
%queryActiveDirectory(
  filter=(objectclass=user)
);

proc print data=&syslast (obs=50);
run;

=======================================================================

* return ALL objects (will definitely take a long time to run) ;
* in fact, it fails due ldap server sizelimit exceeded ;
%queryActiveDirectory(
  filter=(objectclass=*)
);

proc print data=&syslast (obs=50);
run;

=======================================================================

* example of post processing the data in SAS ;
* return all users with Rob Ashmore as their manager ;
%queryActiveDirectory(
  base=%str(OU=Sydney,OU=BUPAUsers,DC=internal,DC=bupa,DC=com,DC=au)
  ,filter=(manager=CN=Rob Ashmore,OU=Sydney,OU=BUPAUsers,DC=internal,DC=bupa,DC=com,DC=au)
  ,attrs=givenName sn streetAddress l st postalCode mail telephoneNumber mobile title
);

* create macro variables ;
data _null_;
  set ldap;
  by entryname notsorted;
  if first.entryname then ctr+1;
  if name="l" then name="city";
  call symputx(cats(name,ctr),strip(value),"G");
run;

%put &givenname1 &sn1 &mail1 &mobile1; * etc, etc. ;
%put &givenname2 &sn2 &mail2 &mobile2;
%put &givenname3 &sn3 &mail3 &mobile3;

* or, transpose the data instead ;
* note: this would give undesired results if the LDAP attribute name ;
* is not a valid SAS variable name ;
proc transpose data=ldap out=transposed (rename=(l=city) drop=_name_);
  by entryname notsorted;
  id name;
  var value;
run;

* if you know the attribute is a multi-valued attribute, ;
* you would probably want to return the data as a delimited list ;
%queryActiveDirectory(
  base=%str(OU=Sydney,OU=BUPAUsers,DC=internal,DC=bupa,DC=com,DC=au)
  ,filter=(cn=Scott Bass)
);
proc sql noprint;
  select
    value into :email_proxies separated by "^"
  from
    ldap
  where
    lowcase(name) = "%lowcase(proxyaddresses)"
  ;
  select
    value into :email_lists separated by "^"
  from
    ldap
  where
    lowcase(name) = "%lowcase(memberof)"
  ;
quit;
%put &email_proxies;
%put &email_lists;

-----------------------------------------------------------------------
Notes:

LDAP, and thus Active Directory, is an object-oriented database with a
tree structure.  Since this structure cannot be mimicked in SAS, the
output data step view is a "flattened" view of Active Directory.

As with SQL pass through against an RDBMS, you will get MUCH better
performance if you make Active Directory do the filtering, rather than
returning "everything" and then filtering in SAS.

You can use the LDP command ("C:\Program Files (x86)\Support Tools\ldp.exe")
to view the structure of Active Directory.  For a primer on this
command and LDAP query syntax, see
http://technet.microsoft.com/en-us/library/aa996205(v=exchg.65).aspx#DoingASearchUsingADUC

Certain LDAP searches will execute quicker than others, for example
searching on sAMAccountName (network login) vs. mail (email address).
For best results, set the Base DN as low in the directory tree as
possible to get the desired results, analogous to searching a Windows
directory structure as low as possible.  Again, the LDP command is your
friend here.

IT has created a service account with a non-expiring password for
programmatic querying of Active Directory.  The details of the service
account are below.  The password must be sent in the clear (not
encoded in any way).

The most common query would be for user information, which has an
objectclass hierarchy of objectclass=organizationalPerson at the lowest level.

The default parameters of this macro are purposely restrictive in
order to return the attributes of the currently logged on user.

I envision that this generic macro would be the "engine" for a wrapper
macro, such as returning the email address for a given user.

This code is based on
http://support.sas.com/rnd/itech/doc9/dev_guide/ldap/ldapintf/ldap_search.html.

---------------------------------------------------------------------*/

%macro queryActiveDirectory
/*---------------------------------------------------------------------
Execute an LDAP query against Active Directory
---------------------------------------------------------------------*/
(SERVER=MPLINF001.medibank.local
               /* Server address of Active Directory (REQ).          */
,PORT=389
               /* Server port of Active Directory (REQ).             */
,BASE=%str(DC=medibank,DC=local)
               /* Base DN (Distinguished Name) from which to start   */
               /* the LDAP search (REQ).                             */
               /* The default Base DN used by Active Directory is    */
               /* DC=medibank,DC=local                               */
               /* which is analogous to the root directory in a      */
               /* file system or Windows drive.                      */
,BINDDN=%str(CN=&LDAPName,OU=Staff,OU=Medibank PHI,OU=MPL Staff,DC=medibank,DC=local)
               /* Bind DN used to connect to Active Directory (REQ). */
               /* Our Active Directory is not configured for         */
               /* anonymous binds, so a valid Bind DN and password   */
               /* is required.  You will not usually need to change  */
               /* this value.  However, if you want to connect as    */
               /* yourself, it would be something like:              */
               /* CN=Scott Bass,OU=BUPAUsers,DC=internal, DC=bupa,...*/
               /* and your current LAN password (clear text).        */
,PW=&LDAPPassword
               /* Bind DN password (REQ).  As above, you will not    */
               /* usually need to change this value.                 */
,FILTER=(&(samaccountname=&sysuserid)(objectclass=organizationalPerson))
               /* LDAP query filter (REQ).                           */
               /* This will retrieve the user object of the current  */
               /* user for LAN accounts ONLY (i.e. not PRODUSR)      */
,ATTRS=
               /* Requested LDAP attributes to return (Opt).         */
               /* A blank value will return all attributes for the   */
               /* retrieve object.  Specify attributes as a spaced   */
               /* delimited list, eg. cn givenName sn mail.          */
,DEBUG=
               /* Echo debugging information in the SAS log? (Opt).  */
               /* Valid values are:                                  */
               /*    Blank = no debugging                            */
               /*    I     = connection information only             */
               /*    F     = full debugging (on a large query this   */
               /*          =    can fill the SAS DMS log)            */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(SERVER,       _req=1,_words=0,_case=N)
%parmv(PORT,         _req=1,_words=0,_case=N)
%parmv(BASE,         _req=1,_words=1,_case=N)
%parmv(BINDDN,       _req=1,_words=1,_case=N)
%parmv(PW,           _req=1,_words=0,_case=N)
%parmv(FILTER,       _req=1,_words=1,_case=N)
%parmv(ATTRS,        _req=0,_words=1,_case=N)
%parmv(DEBUG,        _req=0,_words=0,_case=U,_val=I F)

%if (&parmerr) %then %goto quit;

%global qad_rc;
%let qad_rc=-1;  %* queryActiveDirectory was called, but work.ldap data step view not referenced yet ;

data work.ldap / view=work.ldap;
  length entryName msg $200 name $50 value $4096;

  %* initialize custom return code (syscc is not suitable) ;
  call symputx("qad_rc",0,"G");

  %* initialize variables ;
  rc=0;
  handle=0;
  shandle=0;
  numEntries=0;
  debug="&debug";

  %* open connection to LDAP server ;
  call ldaps_open(handle, "&server", &port, "&base", "&bindDN", "&PW", rc);

  if (rc ne 0) then do;
    msg = sysmsg();
    putlog msg;
    putlog "Server:  &server";
    putlog "Port:    &port";
    putlog "Bind DN: &bindDN";
    putlog "Bind PW: ********";

    %* display message and cleanup resources ;
    link noconnection;
  end;
  else do;
    if (debug ne "") then do;
      putlog "LDAPS_OPEN call successful.";
    end;
  end;

  %* search the LDAP directory ;
  call ldaps_search(handle, shandle, "&filter", "&attrs", numEntries, rc);
  if (rc ne 0 or numEntries eq 0) then do;
    msg = sysmsg();
    putlog msg;
    putlog "Base DN: &base";
    putlog "Filter:  &filter";
    putlog "Attrs:   &attrs";

    %* display message and cleanup resources ;
    link noentries;
  end;
  else do;
    if (debug ne "") then do;
      putlog "LDAPS_SEARCH call successful.";
      putlog "Num entries returned is " numEntries;
    end;
  end;

  do eIndex = 1 to numEntries;
    numAttrs=0;
    entryname="";

    %* retrieve each entry name and number of attributes ;
    call ldaps_entry(shandle, eIndex, entryname, numAttrs, rc);
    if (rc ne 0 or numAttrs eq 0) then do;
      msg = sysmsg();
      putlog msg;

      %* display message and cleanup resources ;
      link noattrs;
    end;
    else do;
      if (debug ne "") then do;
        putlog "LDAPS_ENTRY call successful.";
        putlog "Num attributes returned is " numAttrs;
      end;
    end;

    do aIndex = 1 to numAttrs;
      numValues=0;
      name="";

      %* for each attribute, retrieve name and number of values ;
      call ldaps_attrName(shandle, eIndex, aIndex, name, numValues, rc);
      if (rc ne 0) then do;
        msg = sysmsg();
        putlog msg;
        link novalues;
      end;

      do vIndex = 1 to numValues;
        %* for each attribute, retrieve the values (may be more than one) ;
        call ldaps_attrValue(shandle, eIndex, aIndex, vIndex, value, rc);
        if (rc ne 0) then do;
           msg = sysmsg();
           putlog msg;
           link novalues;
        end;
        else do;
          if (debug="F") then do;
            putlog name= @60 value=;
          end;
          output;
        end;
      end;
    end;
  end;

  cleanup:
    link free;
    link close;
  return;

  free:
    if (shandle=0) then return;

    %* free search resources ;
    call ldaps_free(shandle, rc);
    if (rc ne 0) then do;
      msg = sysmsg();
      putlog msg;
    end;
    else do;
      if (debug ne "") then do;
        putlog "LDAPS_FREE call successful.";
      end;
    end;
  return;

  close:
    if (handle=0) then stop;

    %* close connection to LDAP server ;
    call ldaps_close(handle, rc);
    if (rc ne 0) then do;
       msg = sysmsg();
       putlog msg;
    end;
    else do;
      if (debug ne "") then do;
        putlog "LDAPS_CLOSE call successful.";
      end;
    end;

    %* all calls to close result in a stop ;
    stop;
  return;

  noconnection:
    putlog "Unable to contact the LDAP server.  Check your connection settings.";
    call symputx("qad_rc",3891);
    link cleanup;
  return;

  noentries:
    putlog "No entries found.  Check your Base DN or search filter.";
    call symputx("qad_rc",3892);
    link cleanup;
  return;

  noattrs:
    putlog "No attributes found.  Check your attributes setting.";
    call symputx("qad_rc",3893);
    link cleanup;
  return;

  novalues:
    putlog "Error retrieving values.";
    call symputx("qad_rc",3894);
    link cleanup;
  return;

  keep entryName name value;
run;

%quit:
%mend;

/******* END OF FILE *******/
