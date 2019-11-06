%{
// Uso: flex babaa.l && gcc lex.yy.c -o lexico -lfl && ./lexico test.babaa
#include <stdio.h>
#include "tabla.h"

char attr[256];
%}

%option yylineno

tipo      "entero"|"real"|"buleano"|"caracter"
id        [a-zA-Z_][a-zA-Z0-9_]*
opbin     [<>]=?|[=!]=|"*"|"/"|"^"|"||"|"&&"
masmenos  "+"|"-"
cadena    \"[^\"]*\"

%%

"programa()"        return CABECERA;
"{"                 return LLAVEIZQ;
"}"                 return LLAVEDCH;
"var"               return INILOCAL;
"finvar"            return FINLOCAL;
"si"                return IF;
"otro"              return ELSE;
"mientras"          return WHILE;
"casos"             return SWITCH;
"caso"              return CASE;
"roto"              return BREAK;
"entrada"           return CIN;
"salida"            return COUT;
"predeterminado"    return PREDET;
"="                 return ASIG;
"["                 return CORCHIZQ;
"]"                 return CORCHDCH;
","                 return COMA;
";"                 return PYC;
":"                 return PYP;
"("                 return PARIZQ;
")"                 return PARDCH;
"devolver"          return RETURN;
"!"                 return OPUNARIOIZQ;
{masmenos}          {strcpy(attr, yytext); return MASMENOS;}
{tipo}              {strcpy(attr, yytext); return TIPO;}
{opbin}             {strcpy(attr, yytext); return OPBIN;}
{cadena}            return CADENA;
"verdadero"|"falso" {strcpy(attr, yytext); return CONSTANTE;}
[0-9]+(.[0-9]+)?    {strcpy(attr, "num"); return CONSTANTE;}
\'[^\']\'           {strcpy(attr, "cte_caracter"); return CONSTANTE;}
{id}                return IDENTIFICADOR;

[ \t]+              ;
\n                  ;
.                   {; printf("(Línea %d) Error léxico: token %s no reconocido.\n",
                              yylineno, yytext);}

%%

int main(int argc, char* argv[]) {
  char filename[256];
  attr[0] = '0'; // Carácter especial que denota que el array está vacío.

  if (argc >= 2) {
    strcpy(filename, argv[1]);
    yyin = fopen (filename, "rt");
    if (yyin == NULL) {
      printf ("El fichero %s no se puede abrir\n", filename);
      exit (-1);
    }
  }
  else {
    yyin = stdin;
  }

  int val = yylex();
  while (val != 0) {
    printf("%d <- %s", val, yytext);
    if (attr[0] != '0') {
      printf(" -> ATRIBUTO: %s", attr);
      attr[0] = '0';
    }
    printf("\n");
    val = yylex();
  }
}
