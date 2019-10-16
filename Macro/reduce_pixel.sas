/*=====================================================================
Program Name            : reduce_pixel.sas
Purpose                 : Macro to reduce a map based on the pixel size
                          of the output.  Creates a map dataset that has
                          reduced size and also removes single- and
                          dual-point polygons.
SAS Version             : SAS V9
Input Data              : Map Dataset
Output Data             : Reduced Map Dataset

Macros Called           : parmv

Originally Written by   : SAS Institute
Date                    : JAN 2008
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
Date                    : 24SEP2013
Change/reason           : Modified macro originally written by
                          SAS Institute.
Program Version #       : 1.1

=====================================================================*/

/*---------------------------------------------------------------------
Usage:

libname mapsspde spde "%sysfunc(pathname(work))" temp=yes;

proc copy in=mapssas out=mapsspde;
   select world china us;
run;

%macro map(data=, id=, x=, y=, title=);
   %reduce_pixel(inmap=&data, outmap=mapsspde.mymap, id=&id, xpix=&x, ypix=&y);
   title  "&title Map with &x x &y reduction";
   title2 "%trim(%left(%nobs(&syslast))) obs";
   proc gmap data=mapsspde.mymap map=mapsspde.mymap;
      id &id;
      choro %scan(&id,1,%str( )) / nolegend statistic=first;
   run;
   quit;
%mend;

%map(data=mapsspde.world, id=cont id, x=1920, y=1080, title=World);
%map(data=mapsspde.world, id=cont id, x=1600, y=1200, title=World);
%map(data=mapsspde.world, id=cont id, x= 800, y= 600, title=World);
%map(data=mapsspde.world, id=cont id, x= 400, y= 300, title=World);

%map(data=mapsspde.china, id=id,      x=1920, y=1080, title=China);
%map(data=mapsspde.china, id=id,      x=1600, y=1200, title=China);
%map(data=mapsspde.china, id=id,      x= 800, y= 600, title=China);
%map(data=mapsspde.china, id=id,      x= 400, y= 300, title=China);

%map(data=mapsspde.us,    id=state,   x=1920, y=1080, title=US);
%map(data=mapsspde.us,    id=state,   x=1600, y=1200, title=US);
%map(data=mapsspde.us,    id=state,   x= 800, y= 600, title=US);
%map(data=mapsspde.us,    id=state,   x= 400, y= 300, title=US);

proc copy in=mapsgfk out=mapsspde;
   select world china us;
run;

* <repeat above code > ;

-----------------------------------------------------------------------
Notes:

This is a modified copy of the reduce_pixels macro available for download
from http://support.sas.com/rnd/datavisualization/mapsonline/html/tools.html.
The macro has been renamed from %reduce to %reduce_pixel.

---------------------------------------------------------------------*/

%macro reduce_pixel
/*--------------------------------------------------------------------
Macro to reduce a map based on the pixel size of the output.
--------------------------------------------------------------------*/
(INMAP=        /* Input map dataset name (REQ).                     */
,OUTMAP=       /* Output map dataset name (REQ).                    */
,ID=           /* Space separated list of ID values for the map     */
               /* regions (REQ).                                    */
,XPIX=         /* Number of horizonal pixels (REQ).                 */
,YPIX=         /* Number of vertical pixels (REQ).                  */
,MULT=1        /* Multiplier (REQ).  Increases the number of data   */
               /* points in the output dataset.  For example,       */
               /* MULT=2 to double to data points, MULT=3 to triple */
               /* the data points, etc.  ("Double" and "Triple" are */
               /* illustrative only, and not an exact amount.)      */
);

%local macro parmerr;
%let macro = &sysmacroname;

%* check input parameters ;
%parmv(INMAP,         _req=1,_words=0,_case=U)
%parmv(OUTMAP,        _req=1,_words=0,_case=U)
%parmv(ID,            _req=1,_words=1,_case=U)
%parmv(XPIX,          _req=1,_words=0,_val=POSITIVE)
%parmv(YPIX,          _req=1,_words=0,_val=POSITIVE)
%parmv(MULT,          _req=1,_words=0,_val=POSITIVE)

%if (&parmerr) %then %goto quit;

/* Get the X/Y extents of the map data */
proc summary data=&inmap;
   var x y;
   output out=t min(x)=xmin max(x)=xmax min(y)=ymin max(y)=ymax;
run;

/*
Calculate the ratio for the output pixels "pixscale" and the map data
"mapscale".  This is simply Y/X, but it will determine which ordinate
(X or Y) will constrain the map data.  For instance, a map like the
United Kingdom will be constrained in the Y before the X, whereas a map
of Russia will be constrained in the X before the Y.
*/
data _null_;
   set t;
   xpix=&xpix;
   ypix=&ypix;
   mult=&mult;

   pixscale=ypix/xpix;
   mapscale=(ymax-ymin)/(xmax-xmin);

/*
Set a macro variable to the range that is going to be the constraint
for the map (X or Y).  The formula is maprange/pixelrange for the
particular ordinate values.
*/

   if (pixscale > mapscale) then
      range=(xmax-xmin)/xpix;
   else
      range=(ymax-ymin)/ypix;
   range=range/mult;
   call symputx("range",put(range,f12.7-L));
   stop;
run;

/*
Call GREDUCE and use the range calculated above as the E1 value, which
is the necessary distance between points for a DENSITY value of 1. All
points which are either 0 DENSITY (defined by intersection of polygons)
or 1 DENSITY (defined as being farther apart than the E1 value) will be
acceptable for our output.
*/
proc greduce data=&inmap out=&outmap e1=&range;
   id &id;
run;

/*
Make sure the data is sorted so that we can use BY-group processing to
remove extraneous points and no-area polygons (1- and 2-point polygons)
*/
proc sort data=&outmap;
   by &id segment;
run;

/*
Remove extra data from the map:
   1.  Any DENSITY value greater than 1.
   2.  Any polygons that contain only 1 or 2 points.
*/
data &outmap;
   retain first;
   set &outmap;
   by &id segment;
   where density le 1;
   if first.segment then first=_n_;
   if last.segment and _n_-first < 2 then delete;
   drop first;
run;

/*
A second pass is necessary to remove the second point of the 2-point
polygons.
*/
data &outmap;
   * GREDUCE does not preserve PDV order, which is annoying.  ;
   * Use the input dataset to re-order the PDV. ;
   if 0 then set &inmap;
   set &outmap;
   by &id segment;
   if first.segment and last.segment then delete;
run;

%quit:

%mend;

/******* END OF FILE *******/