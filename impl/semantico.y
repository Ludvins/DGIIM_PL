%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ts.h"

#define YYDEBUG 0

int yylex();  // Para evitar warning al compilar
void yyerror(const char * msg);

// Macro para imprimir errores semánticos
#define semprintf(f_, ...) {printf("(Línea %d) Error semántico: ", yylineno); printf((f_), ##__VA_ARGS__);}

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
                            if ($$.tipo == desconocido) {
                                semprintf("El identificador '%s' no está declarado en este ámbito.\n", $1.lexema);
                            }
                            }
                            | IDENTIFICADOR acceso_array {
                            $$.lexema = $1.lexema;
                            $$.n_dims = nDimensiones($1.lexema) - $2.n_dims;

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == desconocido) {
                                semprintf("El identificador '%s' no está declarado en este ámbito.\n", $1.lexema);
                            }
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

                            if (indice == -1) {
                                semprintf("El identificador '%s' no está declarado en este ámbito.\n", $1.lexema);
                            }
                            else if (TS[indice].tipo_entrada != funcion) {
                                semprintf("El identificador '%s' no se corresponde con una función.\n", $1.lexema);
                            }
                            else {
                                if (TS[indice].parametros != $3.tope_listas) {
                                    semprintf("La función %s requiere exactamente %d parámetros.\n", $1.lexema, TS[indice].parametros);
                                }
                                else {
                                    for (int i = 0; i < $3.tope_listas; ++i){
                                        if (TS[indice + i + 1].tipo_dato != $3.lista_tipos[i]){
                                            semprintf("El parámetro actual número %d tiene tipo %s, mientras que el parámetro formal número %d tiene tipo %s.\n",
                                                i + 1, tipodatoToStr($3.lista_tipos[i]), i + 1, tipodatoToStr(TS[indice + i + 1].tipo_dato));
                                        }

                                        else if (nDimensiones(TS[indice + i + 1].nombre) != $3.lista_ndims[i]) {
                                            semprintf("El parámetro actual número %d tiene %d dimensiones, mientras que el parámetro formal número %d tiene %d dimensiones.\n",
                                                i + 1, $3.lista_ndims[i], i + 1, nDimensiones(TS[indice + i + 1].nombre));
                                        }
                                    }
                                }
                            }

                            $$.tipo = encuentraTipo($1.lexema);
                            $$.n_dims = nDimensiones($1.lexema);
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
                                    semprintf("El tipo %s no es booleano para aplicar el operador unario %s.\n", tipodatoToStr($2.tipo), $1.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($2.n_dims != 0) {
                                    semprintf("El tipo %s es un array y no se puede aplicar el operador unario %s.\n", tipodatoToStr($2.tipo), $1.lexema);
                                }
                            }
                            | MASMENOS expresion
                            {
                                if ($2.n_dims != 0) {
                                    semprintf("El tipo %s no es numerico para aplicar el operador unario %s.\n", tipodatoToStr($2.tipo), $1.lexema);
                                }
                                if (esNumero($2.tipo))
                                    $$.tipo = $2.tipo;
                                else {
                                    semprintf("El tipo %s no es numerico para aplicar el operador unario %s.\n", tipodatoToStr($2.tipo), $1.lexema);
                                    $$.tipo = desconocido;
                                }
                            }
                            | expresion OR expresion
                            {
                                if ($1.tipo == booleano && $3.tipo == booleano)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
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
                                    semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }
                            }
                            | expresion XOR expresion
                            {
                                 if ($1.tipo == booleano && $3.tipo == booleano)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s.\n", $2.lexema);
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
                                    semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != $3.n_dims){
                                    semprintf("Las expresiones no tienen la misma dimension para aplicar el operador binario %s.\n", $2.lexema);
                                } else {
                                    $$.n_dims = $1.n_dims;
                                }
                            }
                            | expresion OPIG expresion
                            {
                                if ($1.tipo == $3.tipo)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no son iguales para aplicar el operador %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }
                            }
                            | expresion OPREL expresion
                            {
                                if (esNumero($1.tipo) && esNumero($3.tipo))
                                    $$.tipo = booleano;
                                else {
                                    semprintf("El tipo %s o el tipo %s no es numérico para aplicar el operador binario %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es un array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }
                            }
                            | expresion OPMUL expresion
                            {
                                if (esNumero($1.tipo) && esNumero($3.tipo)) {
                                    if ($1.tipo == real || $3.tipo == real)
                                        $$.tipo = real;
                                    else
                                        $$.tipo = entero;
                                } else {
                                    semprintf("El tipo %s o el tipo %s no es numérico para aplicar el operador %s.\n", tipodatoToStr($1.tipo), tipodatoToStr($3.tipo), $2.lexema);
                                    $$.tipo = desconocido;
                                }

                                if (!strcmp("**", $2.lexema)) {
                                    if ($1.n_dims == 2 && $3.n_dims == 2)
                                        $$.n_dims = 2;
                                    else {
                                        semprintf("El operador %s solo puede actuar sobre arrays 2D.\n", $2.lexema);
                                    }
                                }
                                else if (!strcmp("*", $2.lexema)) {
                                    if ($1.n_dims != 0 && $3.n_dims != 0 && $1.n_dims != $3.n_dims) {
                                        semprintf("El operador %s solo se puede aplicar sobre array y valores ó arrays de la misma dimensión.\n", $2.lexema);
                                    }
                                    else{
                                        // MAX
                                        $$.n_dims = $1.n_dims;
                                        if ($$.n_dims < $3.n_dims)
                                            $$.n_dims = $3.n_dims;
                                    }
                                }
                                else if (!strcmp("/", $2.lexema)) {
                                    if ($1.n_dims == $2.n_dims || $2.n_dims == 0)
                                        $$.n_dims = $1.n_dims;
                                    else {
                                        semprintf("El operador %s solo puede actuar sobre elementos con la misma dimensión ó cuando el segundo elemento es una variable.\n", $2.lexema);
                                    }
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
                                $$.tipo = $1.tipo;
                                $$.n_dims = $1.n_dims;
                            }
                            | error
;

agregado1D                  : LLAVEIZQ expresiones LLAVEDCH {
                            $$.tipo = $2.lista_tipos[0];
                            for (int i = 1; i < $2.tope_listas; i++) {
                                if ($$.tipo != $2.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado1D tienen que ser del mismo tipo.\n");
                                    break;
                                }
                            }
                            }
;

agregado2D                  : LLAVEIZQ listas PYC expresiones LLAVEDCH {
                            $$.tipo = $2.tipo;
                            for (int i = 0; i < $4.tope_listas; i++) {
                                if ($$.tipo != $4.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado2D tienen que ser del mismo tipo.\n");
                                    break;
                                }
                            }
                            }
;

listas                      : listas PYC expresiones {
                            $$.tipo = $1.tipo;
                            for (int i = 0; i < $3.tope_listas; i++) {
                                if ($$.tipo != $3.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado2D tienen que ser del mismo tipo\n")
                                    break;
                                }
                            }
                            }
                            | expresiones {
                            $$.tipo = $1.lista_tipos[0];
                            for (int i = 1; i < $1.tope_listas; i++) {
                                if ($$.tipo != $1.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado2D tienen que ser del mismo tipo\n")
                                    break;
                                }
                            }
                            }
;

expresiones                 : /* empty */
                            | expresiones COMA expresion {
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
                                semprintf("El tipo o las dimensiones de la expresión no coinciden con las del identificador '%s'.\n", $1.lexema);
                            }
                            }
;

sentencia_if                : IF PARIZQ expresion PARDCH sentencia sentencia_else{
                            if($3.tipo != booleano){
                              semprintf("El tipo de la expresión es %s, y no es booleano para actuar como condición.\n", tipodatoToStr($3.tipo));
                            }
                            }
;

sentencia_else              : /* empty */
                            | ELSE sentencia
;

sentencia_while             : WHILE PARIZQ expresion PARDCH sentencia{
                            if($3.tipo != booleano){
                              semprintf("El tipo de la expresión es %s, y no es booleano para actuar como condición.\n", tipodatoToStr($3.tipo));
                            }
                            }
;

sentencia_switch            : SWITCH PARIZQ expresion{
                            if($3.tipo != entero) {
                                semprintf("El tipo de la expresión es %s, y no es entero para actuar como condición del switch.\n", tipodatoToStr($3.tipo));
                            }
                            } PARDCH bloque_switch
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
                                    semprintf("El identificador '%s' para leer de la entrada no tiene dimensión 0.\n", $4.lista_ids[i]);
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
