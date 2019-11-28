%{
#include <stdio.h>
#include <string.h>

#define YYDEBUG 0

int yylex();  // Para evitar warning al compilar
void yyerror(const char * msg);

%}

/* // Elementos de yyval (ej yyval.lexema)
%union{
  char * lexema;
  struct atributos atrib;
}*/

%define parse.error verbose

%token CABECERA
%token INILOCAL FINLOCAL
%token LLAVEIZQ LLAVEDCH
%token PARIZQ PARDCH
%token CORCHIZQ CORCHDCH
%token PYC COMA PYP
%token TIPO
%token IDENTIFICADOR
%token NATURAL CONSTANTE CADENA
%token ASIG
%token IF ELSE WHILE
%token SWITCH CASE PREDET BREAK
%token RETURN
%token CIN COUT

%left OR
%left AND
%left XOR
%left OPIG
%left OPREL
%left MASMENOS
%left OPMUL
%right NOT

%start programa

%%

programa                    : cabecera_programa bloque
;

bloque                      : inicio_de_bloque
                              declar_de_variables_locales
                              declar_de_subprogs
                              sentencias
                              fin_de_bloque
;

cabecera_programa           : CABECERA
;

inicio_de_bloque            : LLAVEIZQ
;

fin_de_bloque               : LLAVEDCH
;

declar_de_subprogs          : /* empty */
                            | declar_de_subprogs declar_subprog
;

declar_subprog              : cabecera_subprog bloque
;

declar_de_variables_locales : /* empty */
                            | marca_ini_declar_variables
                              variables_locales
                              marca_fin_declar_variables
;

marca_ini_declar_variables  : INILOCAL
;

marca_fin_declar_variables  : FINLOCAL
;

variables_locales           : variables_locales cuerpo_declar_variable
                            | cuerpo_declar_variable
;

cuerpo_declar_variable      : TIPO lista_id PYC
                            | error
;

acceso_array                : CORCHIZQ expresion CORCHDCH
                            | CORCHIZQ expresion COMA expresion CORCHDCH
;

identificador_comp          : IDENTIFICADOR
                            | IDENTIFICADOR acceso_array
;

acceso_array_cte            : CORCHIZQ NATURAL CORCHDCH
                            | CORCHIZQ NATURAL COMA NATURAL CORCHDCH
;

identificador_comp_cte      : IDENTIFICADOR
                            | IDENTIFICADOR acceso_array_cte
;

cabecera_subprog            : tipo_comp IDENTIFICADOR PARIZQ lista_argumentos PARDCH
;

lista_argumentos            : /* empty */
                            | argumentos
;

argumentos                  : argumentos COMA argumento
                            | argumento
;

argumento                   : TIPO identificador_comp_cte
                            | error
;

tipo_comp                   : TIPO
                            | TIPO acceso_array_cte
;

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones PARDCH
                            | IDENTIFICADOR PARIZQ PARDCH
;

expresion                   : PARIZQ expresion PARDCH
                            | NOT expresion
                            | MASMENOS expresion             %prec NOT
                            | expresion OR expresion
                            | expresion AND expresion
                            | expresion XOR expresion
                            | expresion MASMENOS expresion
                            | expresion OPIG expresion
                            | expresion OPREL expresion
                            | expresion OPMUL expresion
                            | identificador_comp
                            | CONSTANTE
                            | NATURAL
                            | agregado1D
                            | agregado2D
                            | llamada_funcion
                            | error
;

agregado1D                  : LLAVEIZQ expresiones LLAVEDCH
;

agregado2D                  : LLAVEIZQ listas PYC expresiones LLAVEDCH
;

listas                      : listas PYC expresiones
                            | expresiones
;

expresiones                 : expresiones COMA expresion
                            | expresion
;

sentencias                  : /* empty */
                            | sentencias sentencia
;

sentencia                   : bloque
                            | sentencia_asignacion
                            | sentencia_if
                            | sentencia_while
                            | sentencia_switch
                            | sentencia_break
                            | sentencia_return
                            | sentencia_llamada_funcion
                            | sentencia_entrada
                            | sentencia_salida
                            | error
;

sentencia_llamada_funcion   : llamada_funcion PYC
;

sentencia_asignacion        : identificador_comp ASIG expresion PYC
;

sentencia_if                : IF PARIZQ expresion PARDCH
                              sentencia sentencia_else
;

sentencia_else              : /* empty */
                            | ELSE sentencia
;

sentencia_while             : WHILE PARIZQ expresion PARDCH sentencia
;

sentencia_switch            : SWITCH PARIZQ expresion PARDCH bloque_switch
;

bloque_switch               : LLAVEIZQ opciones_y_pred LLAVEDCH
;

opciones_y_pred             : opciones opcion_pred
                            | opciones
;

opciones                    : opciones opcion
                            | opcion
;

opcion                      : CASE NATURAL PYP sentencias
;

opcion_pred                 : PREDET PYP sentencias
;

sentencia_break             : BREAK PYC
;

sentencia_return            : RETURN expresion PYC
;

sentencia_entrada           : CIN CADENA COMA lista_id PYC
;

lista_id                    : lista_id COMA identificador_comp
                            | identificador_comp
;

lista_exp_cad               : lista_exp_cad COMA exp_cad
                            | exp_cad
;

exp_cad                     : expresion
                            | CADENA
;

sentencia_salida            : COUT lista_exp_cad PYC
;


%%

#include "lex.yy.c"

void yyerror(const char * msg) {
  printf("(Línea %d) %s\n", yylineno, msg);
}
