%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ts.h"

#define YYDEBUG 0

int yylex();  // Para evitar warning al compilar
void yyerror(const char * msg);

// Macro para imprimir errores semánticos
#define semprintf(f_, ...) {fprintf(stderr, "(Línea %d) Error semántico: ", yylineno); fprintf(stderr, (f_), ##__VA_ARGS__); fflush(stderr); }

// Indica si estamos en un bloque de definición de variables
int isDef = 0;

%}

%define parse.error verbose

// Nombres de los token

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
                              declar_de_variables_locales {if (DEBUG) imprimeTS();}
                              declar_de_subprogs {if (DEBUG) imprimeTS();}
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

marca_ini_declar_variables  : INILOCAL {
                            isDef = 1;
                            }
;

marca_fin_declar_variables  : FINLOCAL{
                            isDef = 0;
                            }
;

variables_locales           : variables_locales cuerpo_declar_variable
                            | cuerpo_declar_variable
;

cuerpo_declar_variable      : TIPO lista_id {
                            for (int i=0; i<$2.tope_listas; i++){
                                insertaVar($2.lista_ids[i], $1.lexema, $2.lista_dims1[i], $2.lista_dims2[i]);
                            }
                            } PYC
                            | error
;

acceso_array                : CORCHIZQ expresion CORCHDCH {
                            $$.n_dims = 1;
                            }
                            | CORCHIZQ expresion COMA expresion CORCHDCH {
                            $$.n_dims = 2;
                            }
;

identificador_comp          : IDENTIFICADOR {
                            $$.lexema = $1.lexema;
                            $$.n_dims = nDimensiones($1.lexema);

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == no_asignado)
                                // Show error msg
                                printf("1error");
                            }
                            | IDENTIFICADOR acceso_array {
                            $$.lexema = $1.lexema;
                            $$.n_dims = nDimensiones($1.lexema) - $2.n_dims;

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == no_asignado)
                                // Show error msg
                                printf("2error");
                            }
;

acceso_array_cte            : CORCHIZQ NATURAL CORCHDCH {
                            $$.dim1 = atoi($2.lexema);
                            $$.dim2 = 0;
                            $$.n_dims = 1;
                            }
                            | CORCHIZQ NATURAL COMA NATURAL CORCHDCH {
                            $$.dim1 = atoi($2.lexema);
                            $$.dim2 = atoi($4.lexema);
                            $$.n_dims = 2;
                            }
;

identificador_comp_cte      : IDENTIFICADOR {
                            $$.dim1 = 0;
                            $$.dim2 = 0;
                            $$.lexema = $1.lexema;
                            if (isDef)
                                $$.n_dims = 0;
                            else
                                $$.n_dims = nDimensiones($1.lexema);
                            }
                            | IDENTIFICADOR acceso_array_cte {
                            $$.lexema = $1.lexema;
                            $$.dim1 = $2.dim1;
                            $$.dim2 = $2.dim2;
                            if (isDef)
                                $$.n_dims = $2.n_dims;
                            else
                                $$.n_dims = nDimensiones($1.lexema) - $2.n_dims;
                            }
;

cabecera_subprog            : tipo_comp IDENTIFICADOR PARIZQ {
                            insertaFuncion($2.lexema, $1.tipo, $1.dim1, $2.dim2);
                            } lista_argumentos PARDCH
;

lista_argumentos            : /* empty */
                            | argumentos
;

argumentos                  : argumentos COMA argumento
                            | argumento
;

argumento                   : TIPO identificador_comp_cte {
                                insertaParametro($2.lexema, $1.lexema, $2.dim1, $2.dim2);
                            }
                            | error
;

tipo_comp                   : TIPO {
                            $$.tipo = strToTipodato($1.lexema);
                            $$.dim1 = 0;
                            $$.dim2 = 0;
                            }
                            | TIPO acceso_array_cte {
                            $$.tipo = strToTipodato($1.lexema);
                            $$.dim1 = $2.dim1;
                            $$.dim2 = $2.dim2;
                            }
;

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones PARDCH {
                            int indice = encuentraTS($1.lexema);

                            if (indice == -1)
                                // Show error msg
                                printf("xerror");
                            else if (TS[indice].tipo_entrada != funcion)
                                // Show error msg
                                printf("yerror");
                            else
                                // Comprobar atributos
                                printf("zerror");

                            // TODO Actualizar
                            $$.tipo = encuentraTipo($1.lexema);
                            $$.lexema = $1.lexema;
                            }
                            | IDENTIFICADOR PARIZQ PARDCH {
                            int indice = encuentraTS($1.lexema);

                            if (indice == -1)
                                // Show error msg
                                printf("aerror");
                            else if (TS[indice].tipo_entrada != funcion)
                                // Show error msg
                                printf("berror");

                            $$.tipo = encuentraTipo($1.lexema);
                            $$.lexema = $1.lexema;
                            }
;

expresion                   : PARIZQ expresion PARDCH
                            {
                                $$.tipo = $2.tipo;
                                $$.n_dims = $2.n_dims;
                            }
                            | NOT expresion
                            {
                                $$.tipo = $2.tipo;
                                $$.n_dims = $2.n_dims;

                                if ($2.tipo != booleano) {
                                    semprintf("El tipo %s no es booleano para aplicar el operador unario %s\n", tipodatoToStr($2.tipo), $1.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($2.n_dims != 0) {
                                    semprintf("El tipo %s es un array y no se puede aplicar el operador unario %s\n", tipodatoToStr($2.tipo), $1.lexema);
                                }
                            }
                            | MASMENOS expresion
                            {
                                if ($2.n_dims != 0) {
                                    semprintf("El tipo %s no es numerico para aplicar el operador unario %s\n", tipodatoToStr($2.tipo), $1.lexema);
                                }
                                if (esNumero($2.tipo))
                                    $$.tipo = $2.tipo;
                                else {
                                    semprintf("El tipo %s no es numerico para aplicar el operador unario %s\n", tipodatoToStr($2.tipo), $1.lexema);
                                    $$.tipo = desconocido;
                                }
                            }
                            | expresion OR expresion
                            {
                                if ($1.tipo == booleano && $3.tipo == booleano)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s\n", $2.lexema);
                                }
                            }
                            | expresion AND expresion
                            {
                                if ($1.tipo == booleano && $3.tipo == booleano)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s\n", $2.lexema);
                                }
                            }
                            | expresion XOR expresion
                            {
                                 if ($1.tipo == booleano && $3.tipo == booleano)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s\n", $2.lexema);
                                }
                            }
                            | expresion MASMENOS expresion
                            {

                                if (esNumero($1.tipo) && esNumero($3.tipo)){
                                    if ($1.tipo == real || $3.tipo == real)
                                        $$.tipo = real;
                                    else
                                        $$.tipo = entero;
                                } else {
                                    semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != $3.n_dims){
                                    semprintf("Las expresiones no tienen la misma dimension para aplicar el operador binario %s\n", $2.lexema);
                                } else {
                                    $$.n_dims = $1.n_dims;
                                }
                            }
                            | expresion OPIG expresion
                            {
                                if ($1.tipo == $3.tipo)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son iguales para aplicar el operador %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s\n", $2.lexema);
                                }
                            }
                            | expresion OPREL expresion
                            {
                                if (esNumero($1.tipo) && esNumero($3.tipo))
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador binario %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s\n", $2.lexema);
                                }
                            }
                            | expresion OPMUL expresion
                            {
                                if (esNumero($1.tipo) && esNumero($3.tipo)){
                                    if ($1.tipo == real || $3.tipo == real)
                                        $$.tipo = real;
                                    else
                                        $$.tipo = entero;
                                } else {
                                    semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador %s\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != $3.n_dims){
                                    semprintf("Las expresiones no tienen la misma dimension para aplicar el operador binario %s\n", $2.lexema);
                                } else {
                                    $$.n_dims = $1.n_dims;
                                }
                            }
                            | identificador_comp
                            {
                                $$.tipo = $1.tipo;
                                $$.n_dims = $1.n_dims;
                            }
                            | CONSTANTE
                            {
                                $$.tipo = getTipoConstante($1.lexema);
                                $$.n_dims = 0;
                            }
                            | NATURAL
                            {
                                $$.tipo = entero;
                                $$.n_dims = 0;

                            }
                            | agregado1D
                            {
                                $$.tipo = $1.tipo;
                                $$.n_dims = 1;

                            }
                            | agregado2D
                            {
                                $$.tipo = $1.tipo;
                                $$.n_dims = 2;

                            }
                            | llamada_funcion
                            {
                                $$.tipo = encuentraTipo($1.lexema);
                                $$.n_dims = $1.n_dims;
                            }
                            | error
;

agregado1D                  : LLAVEIZQ expresiones LLAVEDCH {
                            TipoDato tipo = $2.lista_tipos[0];
                            int correct = 1;
                            for (int i = 1; i < $2.tope_listas; i++) {
                                if (tipo != $2.lista_tipos[i])
                                    correct = 0;
                                    break;
                            }
                            // TODO Está mal, debería ser array of tipo
                            if (correct)
                                $$.tipo = tipo;
                            }
;

agregado2D                  : LLAVEIZQ listas PYC expresiones LLAVEDCH {
                            // TODO Muy parecido a agregado1D aunque hay problemas
                            }
;

listas                      : listas PYC expresiones
                            | expresiones
;

expresiones                 : expresiones COMA expresion {
                            $$.lista_tipos[$$.tope_listas] = $3.tipo;
                            $$.lista_ndims[$$.tope_listas] = $3.n_dims;
                            $$.tope_listas += 1;
                            }
                            | expresion {
                            $$.lista_tipos[$$.tope_listas] = $1.tipo;
                            $$.lista_ndims[$$.tope_listas] = $1.n_dims;
                            $$.tope_listas += 1;
                            }
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

sentencia_asignacion        : identificador_comp ASIG expresion PYC {
                            if ($1.tipo != $3.tipo || $1.n_dims != $3.n_dims) {
                                // Show mensaje de error
                                printf("3error");
                            }
                            }
;

sentencia_if                : IF PARIZQ expresion PARDCH sentencia sentencia_else
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

sentencia_entrada           : CIN CADENA COMA lista_id PYC {
                            for(int i = 0; i < $4.tope_listas; ++i) {
                                if ($4.lista_ndims[i] != 0)
                                    // Show error msg
                                    printf("eerror");
                            }
                            }
;

lista_id                    : lista_id COMA identificador_comp_cte {
                            $$.lista_ids[$$.tope_listas]    = $3.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $3.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $3.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $3.n_dims;

                            $$.tope_listas+=1;
                            }
                            | identificador_comp_cte {
                            $$.lista_ids[$$.tope_listas]    = $1.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $1.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $1.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $1.n_dims;

                            $$.tope_listas+=1;
                            }
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
  printf("(Línea %d) Error sintáctico: %s\n", yylineno, msg);
}
