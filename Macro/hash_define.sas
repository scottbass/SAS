/*====================================================================
Program Name            : hash_define.sas
Purpose                 : Defines a hash object for later lookup.
SAS Version             : SAS 9.1.3
Input Data              : SAS input dataset
Output Data             : None

Macros Called           : parmv, seplist

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
Date                    : 22JUL2011
Change/reason           : Added support for dataset options for hash
                          object since they are now supported in
                          SAS 9.2
Program Version #       : 1.1

Programmer              : Scott Bass
Date                    : 15AUG2011
Change/reason           : Added multidata option.
Program Version #       : 1.2

Programmer              : Scott Bass
Date                    : 04FEB2016
Change/reason           : Added hashname option.
Program Version #       : 1.3

Programmer              : Scott Bass
Date                    : 30MAY2016
Change/reason           : Added duplicate option.
Program Version #       : 1.4

====================================================================*/

/*--------------------------------------------------------------------
Usage:

data source;
   length key1 key2 svar1 svar2 $1;
   input  key1 key2 svar1 svar2;
   datalines;
E  F  1  2
A  B  3  4
C  D  5  6
;
run;

data lookup;
   length key1 key2 lvar3 lvar4 dontwant $1;
   input  key1 key2 lvar3 lvar4 dontwant;
   datalines;
C  D  7  8  X
E  F  9  0  X
;
run;

* "Standard" lookup ;
data joined;
   * set PDV order (optional) ;
   if 0 then set source;

   * initialize &_hashnum_ to zero then declare hash objects ;
   %let _hashnum_=0;
   %hash_define(data=lookup, keys=key1 key2, vars=lvar3);
   %hash_define(data=lookup, keys=key1,      vars=lvar4);  * multiple hashes can be declared ;

   set source;
   %hash_lookup;

   if _rc_h1 ne 0 then put "Lookup failed for hash #1 " key1= key2=;
   if _rc_h2 ne 0 then put "Lookup failed for hash #2 " key1= key2=;
   if sum(of _rc_h:) ne 0 then put "Some lookup failed, generic error processing";

   if (_n_ = 3) then do;
      %hash_lookup(hashnum=2);
      put key1= key2= lvar4=;
   end;

*  drop _rc_h:;  * optional ;
run;

proc print;
run;

======================================================================

* "Standard" lookup with renames ;
data joined;
   * initialize &_hashnum_ to zero then declare hash objects ;
   %let _hashnum_=0;
   %hash_define(data=lookup, keys=key1 key2, vars=lvar3 lvar4, rename=key1=foo key2=bar lvar3=blah lvar4=blech);

   set source (keep=key1 key2 rename=(key1=foo key2=bar));
   %hash_lookup;
*  drop _rc_h:;  * optional ;
run;

proc print;
run;

======================================================================

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

* Multidata lookup with single %hash_lookup macro call ;
data joined;
  * set PDV order (optional) ;
  if 0 then set lookup;

  * initialize &_hashnum_ to zero then declare hash objects ;
  %let _hashnum_=0;
  %hash_define(data=lookup, keys=name, vars=_all_, multidata=Y)

  set sashelp.class (keep=name);
  %hash_lookup(hashnum=1, lookup="01JAN60"d le date le "15JAN60"d, link=derive, return=Y)

  * some dummy derivations for illustration only ;
  derive:
    height=height*1000;
    weight=age*1000;
    new=date;
    format new yymmddd.;
  return;

*  drop _rc_h:;  * optional ;
run;

proc print;
run;

======================================================================

* Multidata lookup with multiple %hash_lookup macro calls ;
* (for code generation illustration only - normally different lookup datasets would be used) ;
data joined;
  * set PDV order (optional) ;
  if 0 then set lookup;

  * initialize &_hashnum_ to zero then declare hash objects ;
  %let _hashnum_=0;
  %hash_define(data=lookup, keys=name, vars=_all_, multidata=Y)
  %hash_define(data=lookup, keys=name, vars=_all_, multidata=Y)

  set sashelp.class (keep=name);
  %hash_lookup(hashnum=1, lookup="01JAN60"d le date le "15JAN60"d, link=derive, return=N)
  %hash_lookup(hashnum=2, lookup=age le 12,                        link=derive, return=Y)

  * some dummy derivations for illustration only ;
  derive:
    height=height*1000;
    weight=age*1000;
    new=date;
    format new yymmddd.;
  return;

*  drop _rc_h:;  * optional ;
run;

proc print;
run;

======================================================================

* Hash names used instead of hash numbers ;
data joined;
  * set PDV order (optional) ;
  if 0 then set lookup;

  %let _hashnum_=0;
  %hash_define(hashname=foo, data=lookup, keys=name, vars=_all_)

  * This next invocation does not specify an explicit name, ;
  * so its name is the default name _h2 ;
  %hash_define(              data=lookup, keys=name, vars=_all_)

  %hash_define(hashname=_bar,data=lookup, keys=name, vars=_all_)
  
  * At this point, &_hashname_=foo | _h2 | _bar ;

  set sashelp.class (keep=name);
  
  * even though a hash name was used, the default hash_lookup ;
  * will process all hash objects ;
  %hash_lookup;
  
  * or you can process by number ;
  %hash_lookup(hashnum=1)
  %hash_lookup(hashnum=2)
  %hash_lookup(hashnum=3)
  
  * or you can process by name (in any order) ;
  %hash_lookup(hashname=_bar)
  %hash_lookup(hashname=foo)

  if _rc_foo ne 0 then put "Lookup failed for hash foo " key1= key2=;
  if _rc_bar ne 0 then put "Lookup failed for hash bar " key1= key2=;

*  drop _rc_:;  * optional ;
run;

----------------------------------------------------------------------
Notes:

Set &_hashnum_ = 0 before calling this macro for the first time.
&_hashnum_ is incremented each time this macro is called.

(Technically you do not have to set _hashnum_ in the calling program,
 but it will get created on the first %hash_define invocation, 
 and incremented each time %hash_define is called.
 This would be a problem in a development environment like EG or DMS,
 but would not be an issue in batch processing.
 Do yourself a favor and just set _hashnum_=0 in the calling program.)

You do not need to explicitly set &_hashname_.
It is set to blank when &_hashnum_=1, and appended to each time
%hash_define is called.

Neither the source nor the lookup datasets need to be sorted.

Each time the find() command executes (%hash_lookup), the current
key values in the PDV are used to lookup the corresponding record in
the lookup dataset(s).  If found, the satellite variables are assigned
in the PDV.

The default hash object name is _h1, _h2, ..., _h<n>, where "n"
is the number of times %hash_define was called.

If the HASHNAME parameter is specified, that name is used for the
hash object, and for the return code set by %hash_lookup.

The default return code variable is _rc_h1, _rc_h2,..., _rc_n<n>.
If the HASHNAME parameter was specified in %hash_define, the 
return code variable is named _rc_<hashname>.  If the hashname
contains a leading underscore, it is removed from the return
code variable.

For example, if the HASHNAME parameter = _myhash, 
the generated code will be 
_rc_myhash = _myhash.find(), instead of 
_rc__myhash = _myhash.find(). 

The return code indicates whether the lookup was successful, 
and is similar to IN= dataset option on a merge.

If the VARS parameter is not specified, then no additional variables
are joined with the master dataset.  Typically this is used when the
only thing you are interested in is the existence of the key variables
in the lookup dataset.  This is similar to a data step merge with no
additional variables other than the keys, and processing the IN=
dataset option.  Check the value _rc_h# = 0 for successful key lookup.

If the VARS parameter is set to _ALL_, then the ALL parameter is
specified in the hash object declaration, and ALL variables from the
lookup dataset are joined with the master dataset.

If the RENAME parameter is specified, it must be specified as
physical_name1=virtual_name1 physical_name2 = virtual_name2, etc.
Spaces are allowed between the equals sign and the oldname/newname
variable pairs.

If the RENAME parameter is specified, the KEYS and VARS parameters must
be specified from the perspective of the virtual names, i.e. the
renamed variables.

By default, the first key in the load dataset is added to the hash
object, and all other keys are ignored.  
If REPLACE=R, then the last key in the load dataset is added to the hash object.
If REPLACE=E, then duplicate keys in the load dataset will generate an error.

If MULTIDATA=Y, then multiple values of the keys are permitted in the
lookup hash object.  Otherwise, only the first occurence of each key
value will be added to the lookup hash object.

If MULTIDATA=Y, you would usually pair this with a LOOKUP=<subsetting
criteria> %hash_lookup macro call.  See usage example above for details.

The hash lookup is a lookup/join, not a merge.  It does NOT merge the
additional observations from the lookup dataset. The resulting number
of observations will match the number of observations in the source
dataset.

--------------------------------------------------------------------*/

%macro hash_define
/*--------------------------------------------------------------------
Defines a hash object for later lookup
--------------------------------------------------------------------*/
(DATA=         /* Lookup dataset (Opt).                             */
               /* If specified, the lookup dataset loads the hash   */
               /* object.  If not specified, an empty hash object   */
               /* is created.                                       */
,KEYS=         /* Lookup keys (REQ).                                */
,VARS=         /* Lookup satellite variables (Opt).                 */
               /* Default is no additional variables from the lookup*/
               /* dataset.  Specify _ALL_ to return all variables   */
               /* from the lookup dataset.                          */
,RENAME=       /* Rename lookup keys or satellite variables (Opt).  */
               /* If specified, then specify as oldname1=newname1   */
               /* oldname2=newname2 etc.                            */
,WHERE=        /* Where clause to apply to the lookup dataset(Opt). */
,KEEP=         /* Additional keep variables (Opt).                  */
               /* KEYS= and VARS= variables are automatically kept, */
               /* specify KEEP= if you have variables needed for a  */
               /* WHERE= clause that are neither key nor satellite  */
               /* variables.                                        */
,ORDERED=N     /* Store lookup table in sorted order? (REQ).        */
               /* Valid values are N=none, A=ascending, D=descending*/
               /* (case insensitive).                               */
               /* Default=none.                                     */
,MULTIDATA=N   /* Multiple key values allowed in the lookup hash    */
               /* object? (REQ).                                    */
               /* Default value is NO.  Valid values are:           */
               /* 0 1 OFF N NO F FALSE and ON Y YES T TRUE          */
               /* OFF N NO F FALSE and ON Y YES T TRUE              */
               /* (case insensitive) are acceptable aliases for     */
               /* 0 and 1 respectively.                             */
,REPLACE=      /* Replace keys that have already been loaded into   */
               /* the hash object? (Opt).                           */
               /* Default value is <blank>, the first key is loaded */
               /* and all other keys are ignored.                   */
               /* If REPLACE=R | REPLACE, duplicate keys overwrite  */
               /* previous keys, i.e. the last key is loaded.       */
               /* If REPLACE=E | ERROR, duplicate keys will         */
               /* generate an error.                                */               
,HASHNAME=     /* Explicit hash object name (Opt.)                  */
               /* If not specified, the default name                */
               /* _h<hashnum> is used.                              */
);

%local macro parmerr keep rx hn;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(DATA,         _req=0,_words=0,_case=N)
%parmv(KEYS,         _req=1,_words=1,_case=N)
%parmv(VARS,         _req=0,_words=1,_case=N)
%parmv(RENAME,       _req=0,_words=1,_case=N)
%parmv(WHERE,        _req=0,_words=1,_case=N)
%parmv(KEEP,         _req=0,_words=1,_case=N)
%parmv(ORDERED,      _req=0,_words=0,_val=A D N)
%parmv(MULTIDATA,    _req=1,_words=0,_case=U,_val=0 1)
%parmv(REPLACE,      _req=0,_words=0,_case=U,_val=R REPLACE E ERROR)
%parmv(HASHNAME,     _req=0,_words=0,_case=N)

%if (&parmerr) %then %goto quit;

%* we need to transform the keys and vars variables expressed as ;
%* the physical variable names into the renamed variables ;
%* keys and vars must match the actual variable names ;
%if (%upcase(&vars) ne _ALL_) %then %let keep=&keys &vars &keep;

%* remove spaces around equals sign ;
%let rx=%sysfunc(prxparse(s/\s*=\s*/=/));
%let rename=%sysfunc(prxchange(&rx,-1,&rename));
%syscall prxfree(rx);

%* convert the keep variables to the physical names ;
%macro _convert_;
  %let rx=%sysfunc(prxparse(s/%scan(&word,2,=)/%scan(&word,1,=)/i));
  %let keep=%sysfunc(prxchange(&rx,-1,&keep));
  %syscall prxfree(rx);
%mend;
%loop(%superq(rename),mname=_convert_)

%* declare _hashnum_ as a global variable for use in %hash_lookup macro ;
%if (^%symexist(_hashnum_)) %then %do;
  %global _hashnum_;
  %let _hashnum_=0;
%end;

%* declare _hashname_ as a global variable for use in %hash_lookup macro ;
%if (^%symexist(_hashname_)) %then %do;
  %global _hashname_;
  %let _hashname_= ;
%end;

%* increment _hashnum_ ;
%let _hashnum_ = %eval(&_hashnum_+1);

%* if this is the first iteration set _hashname_ to blank ;
%if (&_hashnum_ eq 1) %then %let _hashname_ = ;

%* if an explicit hash name was specified use it, ;
%* otherwise set the default hash name of _h<hashnum> ;
%if (&hashname eq ) %then 
   %let hn=_h&_hashnum_;
%else
   %let hn=&hashname;
   
%* append the hashname to &_hashname_ with a pipe (|) delimiter ;
%if (&_hashnum_ gt 1) %then %let _hashname_ = &_hashname_ |;
%let _hashname_ = &_hashname_ &hn;

%* build dataset options ;
%local options;

%if (%superq(keep)%superq(rename)%superq(where) ne ) %then
  %let options=%str(%();
%if (%superq(keep)    ne ) %then
  %let options=%superq(options) keep=%superq(keep);
%if (%superq(rename)  ne ) %then
  %let options=%superq(options) rename=(%superq(rename));
%if (%superq(where)   ne ) %then
  %let options=%superq(options) where=(%superq(where));
%if (%superq(options) ne ) %then
  %let options=%superq(options) %str(%));
%let options=%unquote(&options);

%* declare hash object(s) on first iteration of the datastep ;
if (_n_ = 1) then do;
  %if (&data ne ) %then %do;
  %* set the variable attributes, but do not read any records ;
  if 0 then set &data &options;
  %end;

  %* declare the hash object ;
  declare hash &hn (
    %if (&data ne ) %then %do;
    dataset: "&data &options" ,
    %end;
    hashexp: 16
    , ordered: "&ordered"
    %if (&replace eq R or &replace eq REPLACE) %then %do;
    , duplicate: "R"
    %end;
    %else
    %if (&replace eq E or &replace eq ERROR) %then %do;
    , duplicate: "E"
    %end;
    %if (&multidata) %then %do;
    , multidata: "Y"
    %end;
  );

  %* define keys and satellite variables ;
  &hn..defineKey(%seplist(&keys,nest=QQ));

  %if (%upcase(&vars) eq _ALL_) %then %do;
    &hn..defineData(ALL: "YES");
  %end;
  %else
  %if (&vars ne ) %then %do;
    &hn..defineData(%seplist(&vars,nest=QQ));
  %end;

  %* end hash declaration ;
  &hn..defineDone();
end;

%* explicitly set hash variables to missing so they are not ;
%* retained across lookups if a lookup fails ;
%if (&vars ne ) %then %do;
   call missing(of &vars);
%end;

%quit:

%mend;

/******* END OF FILE *******/
