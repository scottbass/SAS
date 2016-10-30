options ls=max;  * so the SAS log lines do not wrap ;
options mprint;  * print macro generated code ;

* create source data ;
data source (index=(acct));
  length acct parent $3 amount 8;
  input acct parent amount;
  datalines;
A1  .   10
A2  A1  20
A3  A2  30
A4  A2  20
A5  A1  10
A6  A5  10
A7  .   10
A8  A7  20
A9  A7  30
A10 A9  20
;
run;

%macro code;
* option 1: index key lookup to derive top-level parent ;

* use recursion to get the top level parent ;
/* Note: This is my first version...I prefer the second approach
data option1;
  set source;
  temp=acct;
  do while (1);
    if missing(parent) then do;
      parent=acct;
      acct=temp;
      leave;
    end;
    acct=parent;
    set source (drop=amount) key=acct / unique;
  end;
  _error_=0;
  drop temp;
run;
*/

data option1;
  set source;
  _acct=acct;
  _parent=parent;
  do while (not missing(parent));
    acct=parent;
    set source (drop=amount) key=acct / unique;
  end;
  toplevel=acct;
  acct=_acct;
  parent=_parent;
  _error_=0;
  drop _:;
run;

proc summary data=option1 nway noprint;
  class toplevel;
  var amount;
  output out=sum1 sum=;
run;

* option 2: but, even better is to derive the hierarchy ;
* there are many ways to do this, this is just one example ;
data option2;
  set source;
  length hier $200;  * buffer variable, could be 32K long max ;
  _acct=acct;
  _parent=parent;
  do while (not missing(parent));
    hier=catx("|",acct,hier);
    acct=parent;
    set source (drop=amount) key=acct / unique;
  end;
  hier=catx("|",acct,hier);
  acct=_acct;
  parent=_parent;
  _error_=0;
  drop _:;
run;

* I could "overallocate" an array below (create say 20 levels) and "clean up" (delete columns) later. ;
* Instead, process the dataset to get the max levels ;
%global max_hier;
%let max_hier=;
proc sql noprint;
  select max(countw(hier,"|")) into :max_hier separated by " " from option2;
quit;
%put &=max_hier;

* create a dimension dataset for the accounts ;
* Note: Lev3 (the lowest level) is the same as the accts ;
data dim_acct;
  length Lev1-Lev&max_hier $3;
  set option2;
  array lev{*} Lev:;
  do i=1 to dim(lev);
    lev{i}=scan(hier,i,"|");
    if missing(lev{i}) then lev{i}=lev{i-1}; * mimic coalesce function here instead of the view ;
  end;
  keep Lev: acct;
run;

* create a view joining the dimension and fact table ;
* use proc contents for dynamic code generation ;
proc contents data=dim_acct out=contents (keep=name varnum where=(name like 'Lev%')) noprint;
run;

* the %seplist utility macro generates a separated list suitable for SQL ;
* for this join, we are using acct as the key ;
proc sql noprint;
  select name into :levs separated by " " from contents order by varnum;
  create view joined as
    select
      %seplist(&levs,prefix=d.),
      f.acct,  /* this is redundant, I could drop this and just use the lowest level */
      f.amount
    from
      dim_acct d
    inner join
      option2 f
    on
      d.acct=f.acct
  ;
quit;

* now generate a summary for each level in the hierarchy ;
proc summary data=joined noprint;
  class lev:;
  var amount;
  types (lev:) ();
  output out=sum2 sum=;
run;
%mend;
%code;

* now, say new hierarchies are added ;
* these hierarchies do not have to be contiguous, ;
* they only need to be unique, and unambigously map ;
* to a parent acct ;
data source (index=(acct));
  length acct parent $3 amount 8;
  input acct parent amount;
  datalines;
A1  .   10
A2  A1  20
A3  A2  30
A4  A2  20
A5  A1  10
A6  A5  10
A7  .   10
A8  A7  20
A9  A7  30
A10 A9  20
A11 A4  5
A12 A9  5
A13 A11 5
A14 A12 5
;
run;

* just run the above code again, using this new source ;
* no code changes are required ;
%code;

* finally, create a dimensional model ;

* create a dimension for the account locations ;
* apologies to India...I don't know suburb names, but love their food! ;
data dim_acct_names (index=(acct name_id));
  length Name_Id 8 Acct $3 Acct_Name $100;
  infile datalines dsd dlm="|";
  input Acct Acct_Name;
  Name_Id+1;
  datalines;
A1  | IBM Australia
A2  | New South Wales
A3  | Newcastle
A4  | Sydney
A5  | Victoria
A6  | Melbourne
A7  | HP India
A8  | Chennai
A9  | New Delhi
A10 | Roganjosh
A11 | CBD
A12 | Vindaloo
A13 | Pitt St. Branch
A14 | Korma
;
run;

* create a dimension dataset for the account hierarchy ;
* for the hierarchy, we are really interested in the name, not the acct id ;
* I have decided to use a snowflake schema instead of star schema ;
* and a data step view instead of sql view ;
data dim_acct (index=(lev_id));
  length Lev_Id 8 Lev1-Lev&max_hier 8;
  set option2;
  Lev_Id+1;
  _acct=acct;
  array lev{*} Lev1-Lev&max_hier;
  do i=1 to dim(lev);
    acct=scan(hier,i,"|");
    set dim_acct_names (keep=acct name_id) key=acct / unique;
    lev{i}=name_id;
    if missing(lev{i}) then lev{i}=lev{i-1}; * mimic coalesce function here instead of the view ;
  end;
  acct=_acct;
  keep Lev: Acct;
  _error_=0;
run;

* view joining account hierarchy and account names ;
data v_dim_acct/view=v_dim_acct;
  length Lev_Id 8 Name1-Name&max_hier $100;
  set dim_acct;
  array lev{*} Lev1-Lev&max_hier;
  array nam{*} Name1-Name&max_hier;
  do i=1 to dim(lev);
    name_id=lev{i};
    set dim_acct_names (keep=name_id acct_name) key=name_id / unique;
    nam{i}=acct_name;
    if missing(nam{i}) then nam{i}=nam{i-1}; * mimic coalesce function here instead of the view ;
  end;
  keep Lev_Id Name:;
  drop Name_Id;
  _error_=0;
run;

* create the fact table and join in the keys ;
* I will show a hash object join approach and an SQL approach ;
data fact_stores;
  length Lev_Id amount 8;
  set option2 (keep=acct amount);
  %let _hashnum_=0;
  %hash_define(data=dim_acct,       keys=acct, vars=Lev_Id);
  %hash_lookup;
  drop _h: acct;
run;

* via SQL ;
proc sql;
  create table fact_stores as
  select
    t2.Lev_Id
    ,t1.Amount
  from
    option2 t1
  left join
    dim_acct t2
  on
    t1.acct=t2.acct
  ;
quit;

* create a view for reporting (proc summary) ;
* use proc contents for dynamic code generation ;
proc contents data=v_dim_acct out=contents (keep=name varnum where=(name like 'Name%')) noprint;
run;

* the %seplist utility macro generates a separated list suitable for SQL ;
* for this join, we are using acct as the key ;
proc sql noprint;
  select name into :levs separated by " " from contents order by varnum;
  create view v_fact_stores as
    select
      %seplist(&levs,prefix=l.)
      ,f.amount
    from
      fact_stores f
    left join
      v_dim_acct l
    on
      f.lev_id=l.lev_id
  ;
quit;

proc summary data=v_fact_stores noprint;
  class Name:;
  var amount;
  types (Name:) ();
  output out=sum3 sum=;
run;
