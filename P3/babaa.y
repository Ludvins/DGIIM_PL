
%{
   /* Definition section */
  #include<stdio.h>
  #include<stdlib.h>
 %}

/* Rule Section */
%%

%%

#include "../P2/lex.yy.c"

int yyerror(char *msg)
 {
  printf("invalid string\n");
  exit(0);
 }


//driver code
main()
 {
  printf("enter the string\n");
  yyparse();
 }
