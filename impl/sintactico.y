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
%token CORCHIZQ CORCHDCH
%token PARIZQ PARDCH
%token PYC COMA PYP
%token TIPO
%token IDENTIFICADOR
%token NATURAL CONSTANTE CADENA
%token ASIG
%token IF ELSE WHILE
%token SWITCH CASE PREDET BREAK
%token RETURN
%token CIN COUT

%left OPBIN
%right OPUNARIOIZQ
%left MASMENOS

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

variables_locales           : variables_locales cuerpo_declar_variable pyc
                            | cuerpo_declar_variable pyc
;

cuerpo_declar_variable      : TIPO lista_id
;

acceso_array                : CORCHIZQ expresion CORCHDCH
                            | CORCHIZQ expresion coma expresion CORCHDCH
;

identificador_comp          : IDENTIFICADOR
                            | IDENTIFICADOR acceso_array
;

acceso_array_cte            : CORCHIZQ NATURAL CORCHDCH
                            | CORCHIZQ NATURAL coma NATURAL CORCHDCH
;

identificador_comp_cte      : IDENTIFICADOR
                            | IDENTIFICADOR acceso_array_cte
;

cabecera_subprog            : tipo_comp IDENTIFICADOR PARIZQ lista_argumentos PARDCH
;

lista_argumentos            : /* empty */
                            | argumentos
;

argumentos                  : argumentos coma argumento
                            | argumento
;

argumento                   : TIPO identificador_comp_cte
;

tipo_comp                   : TIPO
                            | TIPO acceso_array_cte
;

expresion                   : PARIZQ expresion PARDCH
                            | identificador_comp
                            | CONSTANTE
                            | NATURAL
                            | op_unario_izquierda expresion
                            | expresion op_binario expresion
                            | agregado1D
                            | agregado2D
                            | llamada_funcion
;

agregado1D                  : LLAVEIZQ expresiones LLAVEDCH
;

agregado2D                  : LLAVEIZQ listas pyc expresiones LLAVEDCH
;

listas                      : listas pyc expresiones
                            | expresiones
;

expresiones                 : expresiones coma expresion
                            | expresion
;

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones PARDCH
                            | IDENTIFICADOR PARIZQ PARDCH
;

op_unario_izquierda         : OPUNARIOIZQ
                            | MASMENOS
;

op_binario                  : MASMENOS
                            | OPBIN
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
;

sentencia_llamada_funcion   : llamada_funcion pyc
;

sentencia_asignacion        : identificador_comp ASIG expresion pyc
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

opcion                      : CASE NATURAL pyp sentencias
;

opcion_pred                 : PREDET pyp sentencias
;

sentencia_break             : BREAK pyc
;

sentencia_return            : RETURN expresion pyc
;

sentencia_entrada           : CIN lista_id pyc
;

lista_id                    : lista_id coma identificador_comp
                            | identificador_comp
;

lista_exp_cad               : lista_exp_cad coma exp_cad
                            | exp_cad
;

exp_cad                     : expresion
                            | CADENA
;

sentencia_salida            : COUT lista_exp_cad pyc
;

pyc                         : PYC
                            | error
;

pyp                         : PYP
                            | error
;

coma                        : COMA
                            | error
;

%%

#include "lex.yy.c"

void yyerror(const char * msg) {
  printf("(Línea %d) %s\n", yylineno, msg);
}
