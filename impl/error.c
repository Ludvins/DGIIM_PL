#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "error.h"

// // // // // // // // // // // // // // // // // // // //
//
// Error message printing
//
// Must make messages look nice.  For example:
// msg = "syntax error, unexpected ',', expecting BOOL or CHAR or INT or ID."
// becomes (xx marks important data):
//  0 syntax
//  1 error,
//  2 unexpected
//  3 ',',    xx
//  4 expecting
//  5 BOOL    xx
//  6 or
//  7 CHAR    xx
//  8 or
//  9 INT     xx
// 10 or
// 11 ID.     xx

// assumes a string with breakchar separating each element.
// breakchars will be replaced by null chars: '\0'
// array of pointers to strings is then returned in
// the array strs which must be allocated by the user!
// the number of strings found is returned as a value of
// the function.  This number is always at least 1.
// The array is terminated by a NULL so there must be
// enough room for all the string pointers plus one for the
// sentinal marker.
int split(char *s, char *strs[], char breakchar){
  int num;

  strs[0] = s;
  num = 1;
  for (char *p = s; *p; p++) {
    if (*p==breakchar) {
      strs[num++] = p+1;
      *p = '\0';
    }
  }
  strs[num] = NULL;

  return num;
}


// trim off the last character
void trim(char *s){
  s[strlen(s)-1] = '\0';
}

#define NUM_TOKENS 40

static char * const MAP_TOKENS[2*NUM_TOKENS] = {
  "INCR",      "'++'",
  "DECR",      "'--'",
  "ASIGN",     "'='",
  "IF",        "'if'",
  "ELSE",      "'else'",
  "WHILE",     "'while'",
  "REPEAT",    "'repeat'",
  "UNTIL",     "'until'",
  "READ",      "'read'",
  "WRITE",     "'write'",
  "VARBEGIN",  "'begin'",
  "VAREND",    "'end'",
  "CADENA",    "una cadena",
  "LITERAL",   "un literal",
  "LISTOF",    "'list of'",
  "TIPOBASE",  "un tipo",
  "MAIN",      "'main()'",
  "PROCED",    "'void'",
  "ID",        "un identificador",
  "PARIZQ",    "'('",
  "PARDER",    "')'",
  "SIGNO",     "'+' o '-'",
  "UNARIODER", "'<<' o '>>'",
  "UNARIOIZQ", "'!' o '#' o '?' o '$'",
  "OR",        "'||'",
  "AND",       "'&&'",
  "XOR",       "'^'",
  "COMP_IG",   "'==' o '!='",
  "COMP_MM",   "'<=' o '>=' o '<' o '>'",
  "PROD_DIV_MOD", "'*' o '/' o '%'",
  "EXP",       "'**'",
  "ARROBA",    "'@'",
  "ARROBARROBA", "'@@'",
  "LLAIZQ",    "'{'",
  "LLADER",    "'}'",
  "CORIZQ",    "'['",
  "CORDER",    "']'",
  "PYC",       "';'",
  "COMA",      "','",
  "$end",      "fin de fichero"
};


// looks of pretty printed words for tokens that are
// not already in single quotes.  It uses the niceTokenNameMap table.
char *niceTokenStr(char *tokenName) {
  if (tokenName[0] == '\'') return tokenName;

  for (int i = 0; i < NUM_TOKENS; i++)
    if (strcmp(tokenName, MAP_TOKENS[2*i]) == 0)
      return MAP_TOKENS[2*i + 1];

  fprintf(stderr, "Error en la definición de yyerror: '%s' no está entre los tokens definidos\n", tokenName);
  fflush(stderr);
  exit(1);
}


// Is this a message that we need to elaborate with the current parsed token.
// This elaboration is some what of a crap shoot since the token could
// be already overwritten with a look ahead token.   But probably not.
int elaborate(char *s){
  return strncmp(s, "un", 2) == 0;
}


// Devuelve 1 si el token es una lista de varios operadores
// De esta forma el programa puede tratar de devolver la palabra exacta
int operador_especifico(char *s) {
  return strncmp(s + 2, "' o '", 5) == 0 || strncmp(s + 3, "' o '", 5) == 0;
}


// Imprime la línea donde se ha producido un error
void linea_error() {
  fprintf(stderr, "[%d] ", yylineno);
}


// Imprime un error léxico
void lerror(const char * msg) {
  linea_error();
  fprintf(stderr, "Error léxico: %s", msg);
  fflush(stderr);
}


// This is the yyerror called by the bison parser for errors.
// It only does errors and not warnings.
void yyerror(const char *msg)
{
  char *space;
  char *strs[100];
  int numstrs;

  // make a copy of msg string
  space = strdup(msg);

  // split out components
  numstrs = split(space, strs, ' ');
  if (numstrs>4) trim(strs[3]);

  // translate components
  for (int i=3; i<numstrs; i+=2) {
    strs[i] = niceTokenStr(strs[i]);
  }

  // print components
  linea_error();
  fprintf(stderr, "Error sintáctico: se encontró");
  int especifico = operador_especifico(strs[3]);
  if (!especifico) {
    fprintf(stderr, " %s", strs[3]);
  }
  if (especifico || elaborate(strs[3])) {
    if (yytext[0]=='\'' || yytext[0]=='"') fprintf(stderr, " %s", yytext);
    else fprintf(stderr, " \'%s\'", yytext);
  }

  if (numstrs>4) fprintf(stderr, ", se esperaba");

  // print list of expected
  for (int i=5; i<numstrs; i++) {
    if(strcmp(strs[i], "or") == 0)
      fprintf(stderr, " o");
    else
      fprintf(stderr, " %s", strs[i]);
  }
  fprintf(stderr, "\n");
  fflush(stderr);   // force a dump of the error

  free(space);
}
