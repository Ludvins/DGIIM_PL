%{
// Descomentar la siguiente línea si queremos hacer únicamente análisis léxico
//#define LEXICO

#include <stdio.h>
#include<string.h>
#include "y.tab.h"  // Códigos de tokens generados por YACC

#ifdef LEXICO
  char attr[64];
  int is_attr = 0;
  #define SET_ATTR(atrib) {strcpy(attr, atrib); is_attr = 1;}
#else
  #define SET_ATTR(atrib)
  //#define SET_LEXEMA {yylval.lexema = strdup(yytext);}
#endif
%}

%option yylineno
%option noyywrap

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
{masmenos}          {SET_ATTR(yytext); return MASMENOS;}
{tipo}              {SET_ATTR(yytext); return TIPO;}
{opbin}             {SET_ATTR(yytext); return OPBIN;}
{cadena}            return CADENA;
"verdadero"|"falso" {SET_ATTR(yytext); return CONSTANTE;}
[0-9]+              return NATURAL;
[0-9]+\.[0-9]+      {SET_ATTR("real_num"); return CONSTANTE;}
\'[^\']\'           {SET_ATTR("cte_caracter"); return CONSTANTE;}
{id}                return IDENTIFICADOR;

[ \t]+              ;
\n                  ;
.                   {; printf("(Línea %d) Error léxico: token %s no reconocido.\n",
                              yylineno, yytext);}

%%

// Solo se ejecuta el main cuando estamos haciendo únicamente análisis léxico
#ifdef LEXICO
  int main(int argc, char* argv[]) {
    char filename[256];

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
      if (is_attr) {
        printf(" -> ATRIBUTO: %s", attr);
        is_attr = 0;
      }
      printf("\n");
      val = yylex();
    }
  }
#endif
