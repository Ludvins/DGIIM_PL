#ifndef __ERROR_H__
#define __ERROR_H__

extern int yylineno;
extern char *yytext;
extern FILE* yyout;
// Macro para imprimir errores semánticos
#define semprintf(f_, ...) {linea_error(); fprintf(stderr, "Error semántico: "); fprintf(stderr, (f_), ##__VA_ARGS__); fflush(stderr); }


void linea_error();
void lerror(const char * msg);
void yyerror(const char * msg);

#endif
