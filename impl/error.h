#ifndef __ERROR_H__
#define __ERROR_H__

#include <stdio.h>

extern int yylineno;
extern unsigned error;

// Macro para imprimir errores semánticos
#define semprintf(f_, ...) {error++; fprintf(stderr,"(Línea %d) Error semántico: ", yylineno); fprintf(stderr, (f_), ##__VA_ARGS__); fflush(stderr);}

void lerror(const char * msg);
void yyerror(const char * msg);

#endif
