%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ts.h"
#include "error.h"

#define YYDEBUG 0
#define TAM_BUFFER 16

int yylex();  // Para evitar warning al compilar
extern FILE * func_file;
extern FILE * main_file;
FILE * fout; // Salida para el código generado

// Macro para imprimir la generación de código
#define genprintf(f_, ...) {if(!error) {fprintf(fout, (f_), ##__VA_ARGS__); fflush(fout);}}

int prox_etiqueta = 0;
int prox_temporal = 0;
char* etiqueta();
char* temporal();

int prof = 0;
void entraFuncion(){
  prof++;
  fout = func_file;
}

void salFuncion(){
  if(--prof == 0)
    fout = main_file;
}
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

programa                    : {
                            fout = main_file;
                            genprintf("#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include \"dec_fun\"\n#include \"dec_dat\"\n\n");
                            }
                              cabecera_programa
                              bloque
;

bloque                      : inicio_de_bloque
                              declar_de_variables_locales
                              declar_de_subprogs {
                            if (esMain()) {genprintf("\nint main() {\n");}
                            }
                              sentencias
                              fin_de_bloque
;

cabecera_programa           : CABECERA
;

inicio_de_bloque            : LLAVEIZQ {
                            entraBloqueTS();
                            if(!esMain()) genprintf("{\n");
                            }
;

fin_de_bloque               : LLAVEDCH {
                            salBloqueTS();
                            genprintf("}\n");
                            }
;

declar_de_subprogs          : /* empty */
                            | declar_de_subprogs declar_subprog
;

declar_subprog              : cabecera_subprog bloque {
                            salFuncion();
                            }
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
                            genprintf("%s ", tipodatoToStrC(strToTipodato($1.lexema)));
                            for (int i=0; i<$2.tope_listas; i++){
                                insertaVar($2.lista_ids[i], $1.lexema, $2.lista_dims1[i], $2.lista_dims2[i]);
                                genprintf("%s", $2.lista_ids[i]);
                                if ($2.lista_dims1[i] != 0) {
                                  genprintf("[%d]", $2.lista_dims1[i]);
                                  if ($2.lista_dims2[i] != 0) {
                                    genprintf("[%d]", $2.lista_dims2[i]);
                                  }
                                }
                                if (i < $2.tope_listas - 1) {
                                  genprintf(", ");
                                }
                            }
                            genprintf(";\n");
                            }
                              PYC
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

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == desconocido) {
                                semprintf("El identificador '%s' no está declarado en este ámbito.\n", $1.lexema);
                            } else {
                                $$.n_dims = nDimensiones($1.lexema);
                                unsigned i = encuentraTS($1.lexema);
                                $$.dim1 = TS[i].t_dim1;
                                $$.dim2 = TS[i].t_dim2;
                            }
                            }
                            | IDENTIFICADOR acceso_array {
                            $$.lexema = $1.lexema;

                            $$.tipo = encuentraTipo($1.lexema);
                            if ($$.tipo == desconocido) {
                                semprintf("El identificador '%s' no está declarado en este ámbito.\n", $1.lexema);
                            } else {
                                int ndims_e = nDimensiones($1.lexema);
                                $$.n_dims = ndims_e - $2.n_dims;
                                unsigned i = encuentraTS($1.lexema);

                                if (ndims_e == 0) {
                                    semprintf("El identificador '%s' no corresponde a un array.\n", $1.lexema);
                                }

                                if (ndims_e == 1 && $2.n_dims == 2) {
                                    semprintf("Intento de acceder a un array 1D usando dos índices.\n");
                                }

                                if (ndims_e == 2 && $2.n_dims == 1) {
                                    $$.dim1 = TS[i].t_dim2;
                                    $$.dim2 = 0;
                                }
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
                            $$.n_dims = 0;
                            }
                            | IDENTIFICADOR acceso_array_cte {
                            $$.lexema = $1.lexema;
                            $$.dim1 = $2.dim1;
                            $$.dim2 = $2.dim2;
                            $$.n_dims = $2.n_dims;
                            }
;

cabecera_subprog            : tipo_comp IDENTIFICADOR PARIZQ {
                            entraFuncion();
                            genprintf("%s %s(", tipodatoToStrC($1.tipo), $2.lexema);
                            insertaFuncion($2.lexema, $1.tipo, $1.dim1, $1.dim2);
                            } lista_argumentos PARDCH {
                            genprintf(") ");
                            }
;

lista_argumentos            : /* empty */
                            | argumentos
;

argumentos                  : argumentos COMA {
                            genprintf(", ");
                            } argumento
                            | argumento
;

argumento                   : TIPO identificador_comp_cte {
                            genprintf("%s %s", tipodatoToStrC(strToTipodato($1.lexema)), $2.lexema)
                            if ($2.dim1 != 0) {
                              genprintf("[%d]", $2.dim1);
                              if ($2.dim2 != 0) {
                                genprintf("[%d]", $2.dim2);
                              }
                            }
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

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones_o_vacio PARDCH {
                            char temp[1024];
                            sprintf(temp, "%s(", $1.lexema);
                            for (int i = 0; i < $3.tope_listas; i++) {
                              sprintf(temp + strlen(temp), "%s", $3.lista_ids[i]);
                              if (i < $3.tope_listas - 1) {
                                sprintf(temp + strlen(temp), ", ");
                              }
                            }
                            sprintf(temp + strlen(temp), ");\n");

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
                                            semprintf("En la llamada a la función %s, el parámetro actual número %d tiene tipo %s, mientras que el parámetro formal número %d tiene tipo %s.\n",
                                                $1.lexema, i + 1, tipodatoToStr($3.lista_tipos[i]), i + 1, tipodatoToStr(TS[indice + i + 1].tipo_dato));
                                        }

                                        else if (TS[indice + i + 1].t_dim1 != $3.lista_dims1[i] || TS[indice + i + 1].t_dim2 != $3.lista_dims2[i]) {
                                            semprintf("En la llamada a la función %s, el tamaño del parámetro actual %d no coincide con el tamaño del parámetro formal %d.\n",
                                                $1.lexema, i + 1, i + 1);
                                        }
                                    }
                                }
                            }

                            $$.tipo = encuentraTipo($1.lexema);
                            $$.n_dims = nDimensiones($1.lexema);
                            $$.dim1 = TS[indice].t_dim1;
                            $$.dim2 = TS[indice].t_dim2;
                            $$.lexema = temp;
                            }
;

expresion                   : PARIZQ expresion PARDCH
                            {
                              $$.tipo = $2.tipo;
                              $$.n_dims = $2.n_dims;
                              $$.dim1 = $2.dim1;
                              $$.dim2 = $2.dim2;
                              $$.lexema = $2.lexema;
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
                                    semprintf("No se puede aplicar el operador unario %s sobre un array.\n", tipodatoToStr($2.tipo), $1.lexema);
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = !%s;\n", $$.lexema, $2.lexema);
                            }
                            | MASMENOS expresion
                            {
                                if ($2.n_dims != 0) {
                                    semprintf("El operador unario %s no se puede aplicar a un array.\n", $1.lexema);
                                }
                                if (esNumero($2.tipo))
                                    $$.tipo = $2.tipo;
                                else {
                                    semprintf("El tipo %s no es numérico para aplicar el operador unario %s.\n", tipodatoToStr($2.tipo), $1.lexema);
                                    $$.tipo = desconocido;
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s%s;\n", $$.lexema, $1.lexema, $2.lexema);
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
                                    semprintf("Una de las dos expresiones es un array y no se puede aplicar el operador binario %s\n", $2.lexema);
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s || %s;\n", $$.lexema, $1.lexema, $3.lexema);
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
                                    semprintf("Una de las dos expresiones es un array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s && %s;\n", $$.lexema, $1.lexema, $3.lexema);
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
                                    semprintf("Una de las dos expresiones es un array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s ^ %s;\n", $$.lexema, $1.lexema, $3.lexema);
                            }
                            | expresion MASMENOS expresion
                            {
                                if ($1.tipo == $3.tipo){
                                    $$.tipo = $1.tipo;
                                } else {
                                    semprintf("Los tipos no son iguales para aplicar el operador %s.\n", $2.lexema);
                                    $$.tipo = desconocido;
                                }

                                if (!strcmp("+", $2.lexema)) {
                                    if ($1.n_dims != 0 && $3.n_dims != 0 && ($1.dim1 != $3.dim1 || $1.dim2 != $3.dim2) ) {
                                        semprintf("El operador %s solo se puede aplicar sobre dos números, un array y un número ó arrays de la misma dimensión.\n", $2.lexema);
                                    }
                                    else{
                                        $$.n_dims = max($1.n_dims, $3.n_dims);
                                        $$.dim1 = max($1.dim1, $3.dim1);
                                        $$.dim2 = max($1.dim2, $3.dim2);
                                    }
                                }
                                if (!strcmp("-", $2.lexema)) {
                                    if ( ($1.dim1 == $3.dim1 && $1.dim2 == $3.dim2) || $3.n_dims == 0){
                                        $$.dim1 = $1.dim1;
                                        $$.dim2 = $1.dim2;
                                        $$.n_dims = $1.n_dims;
                                    } else {
                                        semprintf("El operador %s solo puede actuar sobre elementos con la misma dimensión ó cuando el segundo elemento es numérico.\n", $2.lexema);
                                    }
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s %s %s;\n", $$.lexema, $1.lexema, $2.lexema, $3.lexema);
                            }
                            | expresion OPIG expresion
                            {
                                if ($1.tipo == $3.tipo)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("Los tipos no son iguales para aplicar el operador %s.\n", $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es un array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s %s %s;\n", $$.lexema, $1.lexema, $2.lexema, $3.lexema);

                            }
                            | expresion OPREL expresion
                            {
                                if ($1.tipo == $3.tipo)
                                    $$.tipo = booleano;
                                else {
                                    semprintf("Los tipos no son iguales para aplicar el operador binario %s.\n", $2.lexema);
                                    $$.tipo = desconocido;
                                }
                                if ($1.n_dims != 0 || $3.n_dims != 0){
                                    semprintf("Una de las dos expresiones es un array y no se puede aplicar el operador binario %s.\n", $2.lexema);
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s %s %s;\n", $$.lexema, $1.lexema, $2.lexema, $3.lexema);
                            }
                            | expresion OPMUL expresion
                            {
                                if ($1.tipo == $3.tipo){
                                    $$.tipo = $1.tipo;
                                } else {
                                    semprintf("Los tipos no son iguales para aplicar el operador %s.\n", $2.lexema);
                                    $$.tipo = desconocido;
                                }

                                if (!strcmp("**", $2.lexema)) {
                                    if ($1.n_dims == 2 && $3.n_dims == 2 && $1.dim2 == $3.dim1) {
                                        $$.n_dims = 2;
                                        $$.dim1 = $1.dim1;
                                        $$.dim2 = $3.dim2;
                                        genprintf("%s = producto_arrays2D(%s, %s, %d, %d, %d, %s);\n", $$.lexema, $1.lexema, $3.lexema, $1.dim1, $1.dim2, $3.dim2);

                                    } else {
                                        semprintf("Las dimensiones de %s y/o %s no son las correctas para aplicar el operador %s.\n",$1.lexema, $3.lexema, $2.lexema);
                                    }
                                }
                                else if (!strcmp("*", $2.lexema)) {
                                    if ($1.n_dims != 0 && $3.n_dims != 0 && ($1.dim1 != $3.dim1 || $1.dim2 != $3.dim2) ) {
                                        semprintf("El operador %s solo se puede aplicar sobre dos números, un array y un número ó arrays de la misma dimensión.\n", $2.lexema);
                                    }
                                    else{
                                      $$.n_dims = max($1.n_dims, $3.n_dims);
                                      $$.dim1 = max($1.dim1, $3.dim1);
                                      $$.dim2 = max($1.dim2, $3.dim2);
                                    }
                                }
                                else if (!strcmp("/", $2.lexema)) {
                                    if ( ($1.dim1 == $3.dim1 && $1.dim2 == $3.dim2) || $3.n_dims == 0){
                                        $$.dim1 = $1.dim1;
                                        $$.dim2 = $1.dim2;
                                        $$.n_dims = $1.n_dims;
                                    } else {
                                        semprintf("El operador %s solo puede actuar sobre elementos con la misma dimensión ó cuando el segundo elemento es una variable.\n", $2.lexema);
                                    }
                                }

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                /* genprintf("%s = %s %s %s;\n", $$.lexema, $1.lexema, $2.lexema, $3.lexema); */
                            }
                            | identificador_comp
                            {
                                $$.tipo = $1.tipo;
                                $$.n_dims = $1.n_dims;
                                $$.dim1 = $1.dim1;
                                $$.dim2 = $1.dim2;

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s;\n", $$.lexema, $1.lexema);
                            }
                            | CONSTANTE
                            {
                                $$.tipo = getTipoConstante($1.lexema);
                                $$.n_dims = 0;

                                $$.lexema = temporal();
                                char * cte = $1.lexema;
                                if ($$.tipo == booleano) {
                                  if (!strcmp(cte, "verdadero"))
                                    cte = "1";
                                  else if (!strcmp(cte, "falso"))
                                    cte = "0";
                                }
                                $$.lexema = cte;
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
                                $$.dim1 = $1.dim1;
                            }
                            | agregado2D
                            {
                                $$.tipo = $1.tipo;
                                $$.n_dims = 2;
                                $$.dim1 = $1.dim1;
                                $$.dim2 = $1.dim2;
                            }
                            | llamada_funcion
                            {
                                $$.tipo = $1.tipo;
                                $$.n_dims = $1.n_dims;
                                $$.dim1 = $1.dim1;
                                $$.dim2 = $1.dim2;

                                $$.lexema = temporal();
                                genprintf("%s %s;\n", tipodatoToStrC($$.tipo), $$.lexema);
                                genprintf("%s = %s", $$.lexema, $1.lexema);

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
                                else if ($2.lista_ndims[i] != 0) {
                                  semprintf("Todas las expresiones dentro de un agregado1D deben tener dimensión 0.\n");
                                }
                            }

                            $$.n_dims = 1;
                            $$.dim1 = $2.tope_listas;
                            }
;

agregado2D                  : LLAVEIZQ listas PYC expresiones_o_vacio LLAVEDCH {
                            $$.tipo = $2.tipo;

                            if ($4.tope_listas == 0) {
                                if ($2.dim1 > 1) {
                                    semprintf ("Sobra un ';' al final del agregado2D.\n");
                                }
                                else {
                                    $$.dim1 = $2.dim1;
                                    $$.dim2 = $2.dim2;
                                }
                            } else {
                                if ($2.dim2 != $4.tope_listas && $4.tope_listas != 0)  {
                                    semprintf ("Todas las listas de expresiones de un agregado2D tienen que tener el mismo número de expresiones.\n");
                                } else {
                                    $$.dim1 = $2.dim1 +1;
                                    $$.dim2 = $2.dim2;
                                }
                            }
                            $$.n_dims = 2;

                            for (int i = 0; i < $4.tope_listas; i++) {
                                if ($$.tipo != $4.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado2D tienen que ser del mismo tipo.\n");
                                    break;
                                }
                                else if ($4.lista_ndims[i] != 0) {
                                  semprintf("Todas las expresiones dentro de un agregado2D deben tener dimensión 0.\n");
                                }
                            }
                            }
;

listas                      : listas PYC expresiones {
                            $$.tipo = $1.tipo;

                            if ($1.dim2 != $3.tope_listas){
                                semprintf ("Todas las listas de expresiones de un agregado2D tienen que tener el mismo número de expresiones.\n");
                            } else
                                $$.dim2 = $1.dim2;

                            $$.dim1 = $1.dim1 + 1;

                            for (int i = 0; i < $3.tope_listas; i++) {
                                if ($$.tipo != $3.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado2D tienen que ser del mismo tipo.\n")
                                    break;
                                }
                                else if ($3.lista_ndims[i] != 0) {
                                  semprintf("Todas las expresiones dentro de un agregado2D deben tener dimensión 0.\n");
                                }
                            }

                            }
                            | expresiones {
                            $$.tipo = $1.lista_tipos[0];
                            for (int i = 1; i < $1.tope_listas; i++) {
                                if ($$.tipo != $1.lista_tipos[i]){
                                    $$.tipo = desconocido;
                                    semprintf("Todas las expresiones dentro de un agregado2D tienen que ser del mismo tipo.\n")
                                    break;
                                }
                                else if ($1.lista_ndims[i] != 0) {
                                  semprintf("Todas las expresiones dentro de un agregado2D deben tener dimensión 0.\n");
                                }
                            }
                            $$.dim1 += 1;
                            $$.dim2 = $1.tope_listas;
                            }
;

expresiones_o_vacio         : /* empty */ {
                            $$.tope_listas = 0;
                            }
                            | expresiones
;

expresiones                 : expresiones COMA expresion {
                            $$.lista_tipos[$$.tope_listas] = $3.tipo;
                            $$.lista_ndims[$$.tope_listas] = $3.n_dims;
                            $$.lista_dims1[$$.tope_listas] = $3.dim1;
                            $$.lista_dims2[$$.tope_listas] = $3.dim2;
                            $$.lista_ids[$$.tope_listas] = $3.lexema;
                            $$.tope_listas = $1.tope_listas + 1;
                            }
                            | expresion {
                            $$.lista_tipos[$$.tope_listas] = $1.tipo;
                            $$.lista_ndims[$$.tope_listas] = $1.n_dims;
                            $$.lista_dims1[$$.tope_listas]  = $1.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $1.dim2;
                            $$.lista_ids[$$.tope_listas] = $1.lexema;
                            $$.tope_listas = 1;
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

sentencia_llamada_funcion   : llamada_funcion PYC {
                            genprintf("%s", $1.lexema);
                            }
;

sentencia_asignacion        : identificador_comp ASIG {
                            genprintf("{\n");
                            } expresion PYC {
                            if ($1.tipo != $4.tipo) {
                                semprintf("El tipo de la expresión no coincide con el del identificador '%s'.\n", $1.lexema);
                            } else if ($1.n_dims != $4.n_dims) {
                                semprintf("Las dimensiones de la expresión no coinciden con las del identificador '%s'.\n", $1.lexema);
                            }
                            else if ($1.dim1 != $4.dim1 || $1.dim2 != $4.dim2){
                                semprintf("El tamaño de '%s' no coincide con el de la expresión asignada.\n", $1.lexema);
                            }
                            genprintf("%s = %s;\n}\n", $1.lexema, $4.lexema);
                            }
;

sentencia_if                : IF PARIZQ
                            {
                                genprintf("{\n");
                            }
                            expresion
                            {
                                if($4.tipo != booleano){
                                  semprintf("El tipo de la expresión es %s, y no es booleano para actuar como condición.\n", tipodatoToStr($4.tipo));
                                }
                                char* e_salida = etiqueta();
                                char* e_else = etiqueta();
                                insertaIf(e_salida, e_else);
                                genprintf("if(!%s) goto %s;\n", $4.lexema, encuentraGotoElse());
                            }
                            PARDCH sentencia
                            {
                                genprintf("goto %s;\n", encuentraGotoSalida());
                                genprintf("%s:;\n", encuentraGotoElse());
                            }
                            sentencia_else
                            {
                                genprintf("%s:;\n}\n", encuentraGotoSalida());
                                salEstructuraControl();
                            }
;

sentencia_else:             /* empty */
                            | ELSE sentencia
;

sentencia_while: WHILE PARIZQ {
                    char* e_entrada = etiqueta();
                    char* e_salida  = etiqueta();
                    insertaWhile(e_entrada, e_salida);
                    genprintf("{\n%s:;\n", e_entrada);
                }
                expresion {
                    if($4.tipo != booleano){
                        semprintf("El tipo de la expresión es %s, y no es booleano para actuar como condición.\n", tipodatoToStr($4.tipo));
                    }
                    genprintf("if (!%s) goto %s;\n", $4.lexema, encuentraGotoSalida());
                }
                PARDCH sentencia {
                    genprintf("goto %s;\n", encuentraGotoEntrada());
                    genprintf("%s:;\n}\n", encuentraGotoSalida());
                    salEstructuraControl();
                }
;

sentencia_switch: SWITCH PARIZQ {
                    genprintf("{\n");
                }
                expresion {
                    if($4.tipo != entero) {
                        semprintf("El tipo de la expresión es %s, y no es entero para actuar como condición del switch.\n", tipodatoToStr($4.tipo));
                    }
                    genprintf("switch (%s)", $4.lexema);
                }
                PARDCH bloque_switch {
                    genprintf("}\n");
                }
;

bloque_switch:   LLAVEIZQ {
                    genprintf("{");
                }
                opciones_y_pred LLAVEDCH {
                    genprintf("}");
                }
;

opciones_y_pred: opciones opcion_pred
               |
               opciones
;

opciones: opciones opcion
        |
        opcion
;

opcion: CASE NATURAL PYP {
            genprintf("case %s:\n", $2.lexema);
        }
        sentencias
;

opcion_pred: PREDET PYP {
                genprintf("default:\n");
            }
            sentencias
;

sentencia_break: BREAK PYC {
                    genprintf("break;\n");
                }
;

sentencia_return: RETURN {
                    genprintf("{\n");
                }
                expresion PYC {
                    genprintf("return %s;\n}\n", $3.lexema);
                }
;

sentencia_entrada           : CIN CADENA COMA lista_id_entrada PYC {
                            genprintf("printf(\"%%s\", %s);\n", $2.lexema);
                            for(int i = 0; i < $4.tope_listas; ++i) {
                                if ($4.lista_ndims[i] != 0) {
                                    semprintf("El identificador '%s' para leer de la entrada no tiene dimensión 0.\n", $4.lista_ids[i]);
                                }
                                char tipo = 'd';
                                if ($4.lista_tipos[i] == caracter)
                                  tipo = 'c';
                                genprintf("scanf(\"%%%c\", &%s);\n", tipo, $4.lista_ids[i]);
                            }
                            }
;

lista_id                    : lista_id COMA identificador_comp_cte {
                            $$.lista_ids[$$.tope_listas]    = $3.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $3.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $3.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $3.n_dims;
                            $$.lista_tipos[$$.tope_listas]  = $3.tipo;

                            $$.tope_listas = $1.tope_listas + 1;
                            }
                            | identificador_comp_cte {
                            $$.lista_ids[$$.tope_listas]    = $1.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $1.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $1.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $1.n_dims;
                            $$.lista_tipos[$$.tope_listas]  = $1.tipo;

                            $$.tope_listas = 1;
                            }
;

lista_id_entrada            : lista_id_entrada COMA identificador_comp {
                            $$.lista_ids[$$.tope_listas]    = $3.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $3.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $3.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $3.n_dims;
                            $$.lista_tipos[$$.tope_listas]  = $3.tipo;

                            $$.tope_listas += 1;
                            }
                            | identificador_comp {
                            $$.lista_ids[$$.tope_listas]    = $1.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $1.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $1.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $1.n_dims;
                            $$.lista_tipos[$$.tope_listas]  = $1.tipo;

                            $$.tope_listas += 1;
                            }
;

lista_exp_cad               : lista_exp_cad COMA exp_cad {
                            $$.lista_ids[$$.tope_listas]    = $3.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $3.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $3.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $3.n_dims;
                            $$.lista_tipos[$$.tope_listas]  = $3.tipo;

                            $$.tope_listas += 1;
                            }
                            | exp_cad {
                            $$.lista_ids[$$.tope_listas]    = $1.lexema;
                            $$.lista_dims1[$$.tope_listas]  = $1.dim1;
                            $$.lista_dims2[$$.tope_listas]  = $1.dim2;
                            $$.lista_ndims[$$.tope_listas]  = $1.n_dims;
                            $$.lista_tipos[$$.tope_listas]  = $1.tipo;

                            $$.tope_listas += 1;
                            }
;

exp_cad                     : expresion
                            | CADENA {
                            $$.lexema = $1.lexema;
                            $$.tipo = cadena;
                            }
;

sentencia_salida            : COUT {
                            genprintf("{\n");
                            } lista_exp_cad PYC {
                            for(int i = 0; i < $3.tope_listas; ++i) {
                                if ($3.lista_ndims[i] != 0) {
                                    semprintf("El identificador '%s' para imprimir en la salida no tiene dimensión 0.\n", $3.lista_ids[i]);
                                }
                                int expr = 0;
                                char tipo = 'd';
                                if ($3.lista_tipos[i] == caracter)
                                  tipo = 'c';
                                else if ($3.lista_tipos[i] == cadena)
                                  tipo = 's';

                                genprintf("printf(\"%%%c\", %s);\n", tipo, $3.lista_ids[i]);
                            }
                            genprintf("}\n");
                            }
;

%%

#include "lex.yy.c"

char* etiqueta() {
  char* buffer = malloc(sizeof(char)* TAM_BUFFER);
  snprintf(buffer, TAM_BUFFER, "etiq%d", prox_etiqueta++);
  return buffer;
}

char* temporal() {
  char* buffer = malloc(sizeof(char)* TAM_BUFFER);
  snprintf(buffer, TAM_BUFFER, "temp%d", prox_temporal++);
  return buffer;
}
