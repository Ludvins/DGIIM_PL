#include "error.h"

// Imprime un error léxico
void lerror(const char * msg) {
  error++;
  fprintf(stderr, "(Línea %d) Error léxico: token '%s' no reconocido.\n", yylineno, msg);
  fflush(stderr);
}

// Imprime un error sintáctico
void yyerror(const char * msg) {
  error++;
  fprintf(stderr, "(Línea %d) Error sintáctico: %s.\n", yylineno, msg);
  fflush(stderr);
}
