/*====================================================================
Program Name            : hash_lookup.sas
Purpose                 : Lookup satellite variables from a hash object.
SAS Version             : SAS 9.1.3
Input Data              : SAS input dataset loaded by %hash_define
Output Data             : None

Macros Called           : parmv

Originally Written by   : Scott Bass
Date                    : 12MAY2010
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
Date                    : 20JAN2012
Change/reason           : Commented out error checking on hashnum parameter
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 04FEB2016
Change/reason           : Added hashname option.
Program Version #       : 1.3

+===================================================================*/

/*--------------------------------------------------------------------
Usage:

See Usage in %hash_define macro header.

However, a multidata lookup deserves a special example.
Note that this example illustrates the *concepts* of the macro code,
not the macro code itself.

* Multidata lookup - better source/lookup example datasets ;
data lookup;
  set
    sashelp.class
    sashelp.class
    sashelp.class
  ;
run;

proc sort;
  by name;
run;

* build dummy date ranges ;
data lookup;
  set lookup;
  date=(_n_-1)*3;
  format date date7.;
run;

* it is useful walking this through the debugger ;
* remove "/ debug" if you do not want the debugger ;
data joined / debug;
  * set PDV variable attributes ;
  if 0 then set lookup;

  * create hash object ;
  if _n_=1 then do;
    declare hash _h1 (dataset: "lookup", multidata: "Y");
    _h1.defineKey("name");
    _h1.defineData(ALL: "Y");
    _h1.defineDone();
  end;
  call missing(of _all_);

  * the lookup key is the name,
  * which has repeated values in the lookup dataset ;
  set sashelp.class (keep=name);

  * find the first instance of the key ;
  _rc_h1=_h1.find();

  * find the remaining instances of the keys, ;
  * then apply further subsetting logic via the if statement ;
  * link out of the loop to derive all downstream variables ;
  * based on the lookup results. ;
  * we need an explicit output statement to only output the records ;
  * which match the subsetting criteria. ;
  do while (_rc_h1=0);
    if ("01JAN60"d le date le "15JAN60"d) then do;
      link derive;
      output;
    end;
    _rc_h1=_h1.find_next();
  end;

  * return;

  * if doing several multidata lookups, only the last lookup should include the return statement ;
  * normally this would be done with different lookup hash objects ;

  * need to do another find since at this point _rc_h1 ne 0 ;
  _rc_h1=_h1.find();

  do while (_rc_h1=0);
    if (age le 12) then do;
      link derive;
      output;
    end;
    _rc_h1=_h1.find_next();
  end;

  return;

  derive:
    height=height*1000;
    weight=age*1000;
    new=date;
    format new yymmddd.;
  return;
run;

proc print;
run;

----------------------------------------------------------------------
Notes:

Use %hash_define to load the lookup dataset(s).  This sets the
_hashnum_ macro variable used in this macro.

The return code from the find() command is returned in data step
variables _rc_h1 - _rc_h<n>, where "n" matches the number of times
%hash_define was called.  No error checking is done on the return
code from within this macro, but error checking could be done in
the calling code.

Alternatively, if the hashname parameter was used, the return code
from the find() command is returned as _rc_<hashname>, eg.
_rc_foo, _rc_bar, _rc_myhash, etc.

If the hashname has a leading underscore, only one underscore is used
in the return code.  In other words:
   If the hashname is myhash, the hash object is myhash.find(),
      and the return code is _rc_myhash.
   If the hashname is _myhash, the hash object is _myhash.find(),
      and the return code is _rc_myhash, NOT _rc__myhash.

By default a lookup will be done across all hash objects defined by the
%hash_define macro.  Use either the hashnum= or hashname= option 
to limit the lookup to a single hash object.

If the LOOKUP parameter is specified:

  It must be syntactically correct subsetting criteria using if
  statement syntax which is used to further subset additional items
  which match the lookup key.

  You would normally also specify the HASHNUM or HASHNAME parameter, 
  unless the logic criteria for all lookups was identical 
  (highly unlikely).

  The HASHNUM associated with a LOOKUP parameter lookup must be
  associated with a MULTIDATA %hash_define statement.  Otherwise, you
  will get a runtime error when the find_next() method is executed
  against a non-multidata hash object.

  The LOOKUP= %hash_lookup macro call should be the LAST lookup
  specified, since by default it also adds the return statement to the
  generated code.

  If several multidata lookups are conducted in the same data step, only
  the final multidata %hash_lookup invocation should issue the return
  statement (RETURN=Y).

  If there are downstream derived variables that rely on the values
  returned from the lookups, then you should also specify the LINK
  parameter, which should be a data step label marking the start of your
  derived variables.

--------------------------------------------------------------------*/

%macro hash_lookup
/*--------------------------------------------------------------------
Lookup satellite variables from a hash object
--------------------------------------------------------------------*/
(HASHNUM=      /* Limit lookup to a specific hash by number (Opt).  */
,HASHNAME=     /* Limit lookup to a specific hash by name (Opt).    */
,LOOKUP=       /* Perform a multidata item lookup? (Opt).           */
               /* If specified, then this criteria is used to       */
               /* perform addtional multidata item lookups          */
               /* and filter the results.                           */
,LINK=         /* Link to additional variable derivations? (Opt).   */
               /* If specified, it must be a data step link label   */
               /* defined outside this macro that marks the start   */
               /* of the additional variable derivations.           */
,RETURN=N      /* Issue a return statement? (REQ).                  */
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
);

%local macro parmerr _num_;
%let macro = &sysmacroname;

%* check input parameters ;
%if (not %symexist(_hashnum_)) %then
%parmv(_msg=%nrstr(The _hashnum_ global macro variable does not exist.  %hash_define must be called before calling this macro))

%if (&hashname ne ) %then
%if (%sysfunc(findw(&_hashname_,&hashname,|,IRST)) eq 0) %then
%parmv(_msg=%nrstr(The &hashname is not in the &_hashname_ list.  Please review the %hash_define invocations.))

%parmv(HASHNUM,      _req=0,_words=0,_val=POSITIVE)
%parmv(HASHNAME,     _req=0,_words=0,_case=N);
%parmv(LOOKUP,       _req=0,_words=1,_case=N)
%parmv(LINK,         _req=0,_words=0,_case=N)
%parmv(RETURN,       _req=1,_words=0,_case=U,_val=0 1)

/*
%if (&hashnum ne ) %then
%if (&hashnum gt &_hashnum_) %then
%parmv(_msg=The hashnum parameter is invalid);
*/

%if (&parmerr) %then %goto quit;

%* define utility macro to perform multidata lookups ;
%* since we are ONLY outputting when we have found a record, ;
%* we do not need to set the satellite variables to missing. ;
%* we know they must have been set when the lookup was successful. ;
%macro multidata_lookup(criteria);
  %* the initial lookup was successful ;
  do while (_rc&hn=0);
    if (&criteria) then do;
      %if (&link ne ) %then %do;
      link &link;
      %end;
      output;
    end;
    _rc&hn=&hn..find_next();
  end;
%mend;

%* perform lookup for each lookup table ;
%if (&hashname ne ) %then %do;
  %let hn = &hashname;
  %let rc = _rc;
  %if (%substr(&hn,1,1) eq _) %then 
    %let rc=&rc.&hn;
  %else
    %let rc=&rc._&hn;
  &rc = &hn..find();

  %if (%superq(lookup) ne ) %then %do;
    %multidata_lookup(&lookup)
  %end;
%end;
%else
%if (&hashnum ne ) %then %do;
  %let hn = %scan(&_hashname_,&hashnum,|);
  %let rc = _rc;
  %if (%substr(&hn,1,1) eq _) %then 
    %let rc=&rc.&hn;
  %else
    %let rc=&rc._&hn;
  &rc = &hn..find();

  %if (%superq(lookup) ne ) %then %do;
    %multidata_lookup(&lookup)
  %end;
%end;
%else
%do _num_=1 %to &_hashnum_;
  %let hn = %scan(&_hashname_,&_num_,|);
  %let rc = _rc;
  %if (%substr(&hn,1,1) eq _) %then 
    %let rc=&rc.&hn;
  %else
    %let rc=&rc._&hn;
  &rc = &hn..find();

  %if (%superq(lookup) ne ) %then %do;
    %multidata_lookup(&lookup)
  %end;
%end;

%if (&return) %then %do;
  return;
%end;

%quit:

%mend;

/******* END OF FILE *******/
