%{
#include <stdio.h>
#include <string.h>

#define YYDEBUG 0

int yylex();  // Para evitar warning al compilar
void yyerror(const char * msg);

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
                            for (int i=0; i<$2.lid.tope_id; i++){
                                insertaVar($2.lid.lista_ids[i], $1.lexema, $2.lid.lista_dims1[i], $2.lid.lista_dims2[i]);
                            }
                            } pyc
                            | error
;

acceso_array                : CORCHIZQ expresion CORCHDCH {
                            $$.ndims = 1;
                            }
                            | CORCHIZQ expresion COMA expresion CORCHDCH {
                            $$.ndims = 2;
                            }
;

identificador_comp          : IDENTIFICADOR {
                            $$.lexema = $1.lexema;
                            $$.ndims = nDimensiones($1.lexema);

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == no_asignado)
                                // Show error msg
                            }
                            | IDENTIFICADOR acceso_array {
                            $$.lexema = $1.lexema;
                            $$.ndims = nDimensiones($1.lexema) - $2.ndims;

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == no_asignado)
                                // Show error msg
                            }
;

acceso_array_cte            : CORCHIZQ NATURAL CORCHDCH {
                            $$.dim1 = strtoi($2.lexema);
                            $$.dim2 = 0;
                            $$.ndims = 1;
                            }
                            | CORCHIZQ NATURAL COMA NATURAL CORCHDCH {
                            $$.dim1 = strtoi($2.lexema);
                            $$.dim2 = strtoi($4.lexema);
                            $$.ndims = 2;
                            }
;

identificador_comp_cte      : IDENTIFICADOR {
                            $$.dim1 = 0;
                            $$.dim2 = 0;
                            $$.lexema = $1.lexema;
                            if (isDef)
                                $$.ndims = 0;
                            else
                                $$.ndims = nDimensiones($1.lexema);
                            }
                            | IDENTIFICADOR acceso_array_cte {
                            $$.lexema = $1.lexema;
                            $$.dim1 = $2.dim1;
                            $$.dim2 = $2.dim2;
                            if (isDef)
                                $$.ndims = $2.ndims;
                            else
                                $$.ndims = nDimensiones($1.lexema) - $2.ndims;
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
                                insertaParametros($2.lexema, $1.lexema, $2.dim1, $2.dim2);
                                imprimeTS();
                            }
                            | error
;

tipo_comp                   : TIPO {
                            $$.tipo = strToTipodato($1);
                            $$.dim1 = 0
                            $$.dim2 = 0
                            }
                            | TIPO acceso_array_cte {
                            $$.tipo = strToTipodato($1);
                            $$.dim1 = $2.dim1;
                            $$.dim2 = $2.dim2;
                            }
;

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones PARDCH {
                            // TODO Comprobar que las expresiones son del tipo de los argumentos
                            // de la función?
                            $$.tipo = tipoTS($1)
                            $$.lexema = $1
                            }
                            | IDENTIFICADOR PARIZQ PARDCH {
                            $$.tipo = tipoTS($1)
                            $$.lexema = $1
                            }
;

expresion                   : PARIZQ expresion PARDCH {$$.tipo = $2.tipo;}
                            | NOT expresion {
                            if ($2.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                semprintf("El tipo %s no es booleano para aplicar el operador unario %s\n", tipoStr($2.tipo),$1);
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
                                semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s\n", tipoStr($2.tipo), tipoStr($3.tipo),$1);
                                $$.tipo = desconocido;
                            }
                            | expresion AND expresion {
                            if ($1.tipo == booleano && $3.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s\n", tipoStr($2.tipo), tipoStr($3.tipo),$1);
                                $$.tipo = desconocido;
                            }
                            | expresion XOR expresion {
                            if ($1.tipo == booleano && $3.tipo == booleano)
                                $$.tipo = booleano;
                            else
                                semprintf("El tipo %s o el tipo %s no son ambos booleanos para aplicar el operador binario %s\n", tipoStr($2.tipo), tipoStr($3.tipo),$1);
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
                                semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador %s\n", tipoStr($2.tipo), tipoStr($3.tipo),$1);
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
                                semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador binario %s\n", tipoStr($2.tipo), tipoStr($3.tipo),$1);
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
                                semprintf("El tipo %s o el tipo %s no son ambos números para aplicar el operador %s\n", tipoStr($2.tipo), tipoStr($3.tipo),$1);
                                $$.tipo = desconocido;
                            }
                            | identificador_comp {
                            $$.tipo = $1.tipo;
                            }
                            | CONSTANTE {
                            $$.tipo = getTipoConstante($1);
                            }
                            | NATURAL{
                            $$.tipo = entero;
                            }
                            | agregado1D {
                            $$.tipo = $1.tipo;
                            }
                            | agregado2D {
                            $$.tipo = $1.tipo;
                            }
                            | llamada_funcion {
                            $$.tipo = tipoTS($1.lexema);
                            }
                            | error
;

agregado1D                  : LLAVEIZQ expresiones LLAVEDCH {
                            TipoDato tipo = $2.larg.lista_tipos[0];
                            int correct = 1;
                            for (int i = 1; i < $2.larg.tope_arg; i++) {
                                if (tipo != $2.larg.lista_tipos[i])
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
                            $$.larg.lista_tipos[$$.larg.tope_arg++] = $3.tipo;
                            }
                            | expresion {
                            $$.larg.lista_tipos[$$.larg.tope_arg++] = $1.tipo;
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
                            if ($1.tipo != $3.tipo || $1.ndims != $3.ndims) {
                                // Show mensaje de error
                            }
                            }
;

sentencia_if                : IF {
  char * e_salida = etiqueta();
  char * e_else   = etiqueta();
  insertaIf(e_salida, e_else);
 } PARIZQ expresion PARDCH {
  compruebaCondicion("if", $4.tipo);
 } sentencia sentencia_else {salEstructuraControl();}
;

sentencia_else              : /* empty */
                            | ELSE sentencia
;

sentencia_while             : WHILE {
  char * e_entrada = etiqueta();
  char * e_salida  = etiqueta();
  insertaWhile(e_entrada, e_salida);
 } PARIZQ {
   compruebaCondicion("while", $4.tipo);
 } expresion PARDCH sentencia {
   salEstructuraControl();
 }
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
                            for(int i = 0; i < $4.lid.tope_id; ++i) {
                                if ($4.lid.lista_ndims[i] != 0)
                                    // Show error msg
                            }
                            }
;

lista_id                    : lista_id COMA identificador_comp_cte {
                            $$.lid.lista_ids[$$.lid.tope_id]    = $3.lexema;
                            $$.lid.lista_dims1[$$.lid.tope_id]  = $3.dim1;
                            $$.lid.lista_dims2[$$.lid.tope_id]  = $3.dim2;
                            $$.lid.lista_ndims[$$.lid.tope_id]  = $3.ndims;

                            $$.lid.tope_id+=1;
                            }
                            | identificador_comp_cte {
                            $$.lid.lista_ids[$$.lid.tope_id]    = $1.lexema;
                            $$.lid.lista_dims1[$$.lid.tope_id]  = $1.dim1;
                            $$.lid.lista_dims2[$$.lid.tope_id]  = $1.dim2;
                            $$.lid.lista_ndims[$$.lid.tope_id]  = $1.ndims;

                            $$.lid.tope_id+=1;
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
  printf("(Línea %d) %s\n", yylineno, msg);
}
