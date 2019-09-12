%macro format_text(left,center,right,length=80);
   %* initialize buffer with text that will not be in the data ;
   %* (technically that does not matter but it is still best practice) ;
   %let buffer=%str(~~~);

   %* left ;
   %let buffer=&buffer%left(&left);

   %* pad buffer with spaces so downstream %substr() calls will not fail ;
   %let buffer=%str(&buffer                                                                        );
   %*put @&buffer@;

   %* center ;
   %let pos=%eval((&length - %length(&center))/2);
   %*put &=pos;
   %let buffer=%qsubstr(&buffer,1,&pos+2)&center;
   %let buffer=%str(&buffer                                                                        );
   %*put #&buffer#;

   %* right ;
   %let pos=%eval(&length - %length(&right));
   %*put &=pos;
   %let buffer=%qsubstr(&buffer,1,&pos+2)&right;
   %let buffer=%str(&buffer                                                                        );
   %*put $&buffer$;

   %* trim ;
   %let buffer=%qsubstr(&buffer,4,&length);

   %* return the buffer ;
%trim(&buffer)
%mend;
