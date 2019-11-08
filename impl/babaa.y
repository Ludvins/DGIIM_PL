
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

declar_de_variables_locales : marca_ini_declar_variables
                              variables_locales
                              marca_fin_declar_variables
;

marca_ini_declar_variables  : INILOCAL
;

marca_fin_declar_variables  : FINLOCAL
;

variables_locales           : variables_locales cuerpo_declar_variable PYC
                            | cuerpo_declar_variable PYC
;

cuerpo_declar_variable      : TIPO lista_id
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

argumentos                  : argumento COMA argumentos
                            | argumento
;

argumento                   : TIPO identificador_comp_cte
;

tipo_comp                   : TIPO
                            | TIPO acceso_array
;

expresion                   : PARIZQ expresion PARDCH
                            | identificador_comp
                            | CONSTANTE
                            | NATURAL
                            | op_unario_izquierda expresion
                            | expresion OPBIN expresion
                            | agregado1D
                            | agregado2D
                            | llamada_funcion
;

agregado1D                  : LLAVEIZQ expresiones LLAVEDCH
;

agregado2D                  : LLAVEIZQ listas PYC expresiones LLAVEDCH
;

listas                      : listas PYC expresiones
                            | expresiones
;

expresiones                 : expresion COMA expresiones
                            | expresion
;

llamada_funcion             : IDENTIFICADOR PARIZQ expresiones PARDCH
                            | IDENTIFICADOR PARIZQ PARDCH
;

op_unario_izquierda         : OPUNARIOIZQ
                            | MASMENOS
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
                            | sentencia_entrada
                            | sentencia_salida
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

bloque_switch               : LLAVEIZQ opciones LLAVEDCH
;

opciones                    : opciones opcion
                            | opcion opcion_pred
                            | opcion_pred
;

opcion                      : CASE NATURAL PYP sentencias
;

opcion_pred                 : PREDET PYP sentencias
;

sentencia_break             : BREAK PYC
;

sentencia_return            : RETURN expresion PYC
;

sentencia_entrada           : CIN lista_id PYC
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

#include "../P2/lex.yy.c"

int yyerror(char * msg) {
  printf("error: %s\n", msg);
  return 1;
}
