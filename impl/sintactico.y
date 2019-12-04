%{
#include <stdio.h>
#include <string.h>

#define YYDEBUG 0

int yylex();  // Para evitar warning al compilar
void yyerror(const char * msg);

%}

// Elementos de yyval
%union{
  char * lexema;
  struct atributos atrib;
}

%define parse.error verbose

// Nombres de los token

%tokenCABECERA
%token INILOCAL FINLOCAL
%token LLAVEIZQ LLAVEDCH
%token PARIZQ PARDCH
%token CORCHIZQ CORCHDCH
%token PYC COMA PYP
%token <lexema> TIPO
%token <lexema> IDENTIFICADOR
%token <lexema> NATURAL CONSTANTE CADENA
%token ASIG
%token IF ELSE WHILE
%token SWITCH CASE PREDET BREAK
%token RETURN
%token CIN COUT

%type <atrib> lista_id
%type <atrib> expresion

// Precedencias

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

inicio_de_bloque            : LLAVEIZQ {entraBloqueTS();}
;

fin_de_bloque               : LLAVEDCH {salBloqueTS();}
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

cuerpo_declar_variable      : TIPO lista_id {
                            for (int i=0; i<$2.lid.tope_id; i++){
                                insertaVar($2.lid.lista_ids[i], $1);
                            }
                            } PYC
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

identificador_comp_cte      : IDENTIFICADOR {$$.lexema = $1}
                            | IDENTIFICADOR acceso_array_cte {$$.lexema = $1}
;

cabecera_subprog            : tipo_comp IDENTIFICADOR PARIZQ {
                            // TODO Modificar insertaFuncion para añadir el tipo que devuelve y
                            // modificar tipo_comp para conseguir dicho tipo
                            insertaFuncion($2);
                            } lista_argumentos {
                            // TODO Comprobar que efectivamente la lista de args es $5
                            for (int i=0; i<$5.lid.tope_id; i++){
                                 insertaParametro($5.lid.lista_ids[i], $5.larg.lista_tipos[i])
                            }
                            } PARDCH
;

lista_argumentos            : /* empty */
                            | argumentos
;

argumentos                  : argumentos COMA argumento {
                            $$.larg.lista_tipos[$$.larg.tope_arg++] = $3.tipo
                            $$.lid.lista_ids[$$.lid.tope_id++] = $3.lexema;
                            }
                            | argumento {
                            $$.larg.lista_tipos[$$.larg.tope_arg++] = $1.tipo
                            $$.lid.lista_ids[$$.lid.tope_id++] = $1.lexema;
                            }
;

argumento                   : TIPO identificador_comp_cte {
                            // TODO Problema, como saber si es una array o no
                            // Posible solución: Añadir parámetro a Atributos
                            $$.tipo = leerTipoDato($1);
                            $$.lexema = $2.lexema;
                            }
                            | error
;

tipo_comp                   : TIPO
                            | TIPO acceso_array_cte
;

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones PARDCH {
                            $$.tipo = tipoTS($1)
                            }
                            | IDENTIFICADOR PARIZQ PARDCH
;

expresion                   : PARIZQ expresion PARDCH {$$.tipo = $2.tipo;}
                            | NOT expresion {
                            if ($2.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | MASMENOS expresion {
                            if (esNumero($2.tipo))
                                $$.tipo = $2.tipo;
                            }            %prec NOT
                            | expresion OR expresion {
                            if ($1.tipo == booleano && $3.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | expresion AND expresion {
                            if ($1.tipo == booleano && $3.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | expresion XOR expresion {
                            if ($1.tipo == booleano && $3.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | expresion MASMENOS expresion {
                            if (esNumero($1.tipo) && esNumero($3.tipo)){
                                if ($1.tipo == real || $3.tipo == real)
                                    $$.tipo = real;
                                else
                                    $$.tipo = entero;
                            }
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | expresion OPIG expresion {
                            // TODO Pensar
                            if ($1.tipo == $3.tipo)
                                $$.tipo = booleano;
                            else
                                $$.tipo = desconocido;
                            }
                            | expresion OPREL expresion {
                            if (esNumero($1.tipo) && esNumero($3.tipo))
                                $$.tipo = booleano;
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | expresion OPMUL expresion {
                            if (esNumero($1.tipo) && esNumero($3.tipo)){
                                if ($1.tipo == real || $3.tipo == real)
                                    $$.tipo = real;
                                else
                                    $$.tipo = entero;
                            }
                            else
                                // TODO Mostrar mensaje de error?
                                $$.tipo = desconocido;
                            }
                            | identificador_comp {
                            $$.tipo = $1.tipo
                            }
                            | CONSTANTE {
                            $$.tipo = getTipoConstante($1);
                            }
                            | NATURAL{
                            $$.tipo = entero;
                            }
                            | agregado1D {
                            $$.tipo = $1.tipo
                            }
                            | agregado2D {
                            $$.tipo = $1.tipo
                            }
                            | llamada_funcion {
                            $$.tipo = tipoTS()
                            }
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
