#ifndef __ERROR_H__
#define __ERROR_H__

#include <stdio.h>

extern int yylineno;
extern unsigned error;

// Macro para imprimir errores semánticos
#define semprintf(f_, ...) {error++; printf("(Línea %d) Error semántico: ", yylineno); printf((f_), ##__VA_ARGS__);}

void lerror(const char * msg);
void yyerror(const char * msg);

#endif
