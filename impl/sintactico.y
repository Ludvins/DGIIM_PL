%{
#include <stdio.h>
#include <string.h>

#define YYDEBUG 0

int yylex();  // Para evitar warning al compilar
void yyerror(const char * msg);

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

marca_ini_declar_variables  : INILOCAL
;

marca_fin_declar_variables  : FINLOCAL
;

variables_locales           : variables_locales cuerpo_declar_variable
                            | cuerpo_declar_variable
;

cuerpo_declar_variable      : tipo lista_id {
                            // TODO ¿permitir declararción de variables del tipo: int i[a+b];?
                            // TODO ahora mismo no estamos insertando las variables correctamente
                            // (no sabemos si son un array o no)
                            for (int i=0; i<$2.lid.tope_id; i++){
                                insertaVar($2.lid.lista_ids[i], $1, $2.ldimensiones.lista_dims[i]);
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
                            $$.ndims = 0;
                            }
                            | IDENTIFICADOR acceso_array {
                            $$.lexema = $1.lexema;
                            $$.ndims = $2.ndims;
                            }
;

acceso_array_cte            : CORCHIZQ NATURAL CORCHDCH {
                            $$.ndims = 1;
                            $$.dim1 = strtoi($2.lexema);
                            $$.dim2 = 0;
                            }
                            | CORCHIZQ NATURAL COMA NATURAL CORCHDCH {
                            $$.ndims = 2;
                            $$.dim1 = strtoi($2.lexema);
                            $$.dim2 = strtoi($4.lexema);
                            }
;

identificador_comp_cte      : IDENTIFICADOR {
                            $$.ndims = 0;
                            $$.dim1 = 0;
                            $$.dim2 = 0;
                            $$.lexema = $1.lexema;
                            }
                            | IDENTIFICADOR acceso_array_cte {
                            $$.lexema = $1.lexema;
                            $$.ndims = $2.ndims;
                            $$.dim1 = $2.dim1;
                            $$.dim2 = $2.dim2;
                            }
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

tipo_comp                   : TIPO {
                            $$.tipo = leerTipoDato($1)
                            }
                            | TIPO acceso_array_cte
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
                            // TODO Manage dimensions
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
                            // TODO comprobar que coinciden los tipos y mensaje error (?)
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
  for(int i=0; i < $4.lid.tope_id; ++i) {
    char * id = $4.lid.lista_ids[i];
    TipoDato tipo = tipoTS(id);
    char * str_tipo;
    switch(tipo) {
      case booleano: // Los booleanos se leerán como 0 o 1 // TODO: ¿hacer que se lea como True o False?
        // TODO: un valor booleano distinto puede provocar errores tras hacer operaciones lógicas con él, ¿gestionar?
      case entero:
        str_tipo = "i"; // Podrá leer enteros con signo en formato decimal (por defecto) o hexadecimal (si empieza por 0x)
        break;
      case real:
        str_tipo = "lf";
        break;
      case caracter:
        str_tipo = "c";
        break;
      default:
        str_tipo = "i"; // TODO: lista o tipo desconocido; imprimir correctamente o provocar mensaje de error de algún tipo
    }
  }
 }
;

lista_id                    : lista_id COMA identificador_comp_cte {
                            $$.lid.lista_ids[$$.lid.tope_id] = $3.lexema;
                            $$.lid.tope_id+=1;
                            }
                            | identificador_comp_cte {
                            $$.lid.lista_ids[$$.lid.tope_id] = $1.lexema;
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
