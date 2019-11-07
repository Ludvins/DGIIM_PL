
%{
   /* Definition section */
  #include<stdio.h>
  #include<stdlib.h>
 %}

/* Rule Section */
%%
<Programa>                    : <Cabecera_programa> <Bloque>
<Bloque>                      : <Inicio_de_bloque>
                                  <Declar_de_variables_locales>
                                  <Declar_de_subprogs>
                                  <Sentencias>
                                  <Fin_de_bloque>;
<Declar_de_subprogs>          : <Declar_de_subprogs> <Declar_subprog>;
<Declar_subprog>              : <Cabecera_subprograma> <Bloque>
<Declar_de_variables_locales> : <Marca_ini_declar_variables>
                                  <Variables_locales>
                                  <Marca_fin_declar_variables>;
<Marca_ini_declar_variables>  : INILOCAL;
<Marca_fin_declar_variables>  : FINLOCAL;
<Cabecera_programa>           : programa();
<Inicio_de_bloque>            : LLAVEIZQ;
<Fin_de_bloque>               : LLAVEDCH;
<Variables_locales>           : <Variables_locales> <Cuerpo_declar_variable> PYC
                              |   <Cuerpo_declar_variable> PYC;
<Cuerpo_declar_variable>      : <Tipo> <Lista_id>
<Acceso_array>                : CORCHIZQ <Expresion> CORCHDCH
                              |   CORCHIZQ <Expresion>,<Expresion> CORCHDCH;
<Identificador_comp>          : <Identificador>
                              |   <Identificador><Acceso_array>;
<Acceso_array_cte_>           : CORCHIZQ <Natural> CORCHDCH
                              |   CORCHIZQ <Natural>,<Natural> CORCHDCH;
<Identificador_comp_cte>      : <Identificador>
                              |   <Identificador><Acceso_array_cte>;
<Cabecera_subprog>            : <Tipo_comp> <Identificador>PARIZQ <Lista_argumentos> PARDCH;
<Lista_argumentos>            : <Argumentos>;
                              |
<Argumentos>                  : <Argumento> , <Argumentos>
                              |   <Argumento>;
<Argumento>                   : <Tipo> <Identificador_comp_cte>;
<Booleano>                    : verdadero | falso ;
<Digito>                      : 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 ;
<Natural>                     : <Digito> <Natural>
                              |   <Digito> ;
<Real>                        : <Natural>.<Natural> ;
<Caracter>                    : a | ... | z | A | ... | Z | _ ;
<Alfanum>                     : <Caracter>
                              |   <Natural> ;
<Caracter_ascii>              :  (Cualquier carácter ASCII menos las comillas (' o "))
                              |   \"
                              |   \'
<Cadena>                      : <Cadena> <Caracter_ascii>
                              |   <Caracter_ascii> ;
<Cadena_const>                : "<Cadena>" ;
<Constante>                   : <Natural>
                              |   <Real>
                              |   <Booleano>
                              |   '<Caracter_ascii>' ;
<Tipo>                        : entero
                              |   real
                              |   buleano
                              |   caracter ;
<Tipo_comp>                   : <Tipo>
                              |   <Tipo><Acceso_array> ;
<Identificador>               : <Identificador> <Alfanum>
                              |   <Caracter> ;
<Expresion>                   : PARIZQ <Expresion> PARDCH
                              |   <Identificador_comp>
                              |   <Constante>
                              |   <Op_unario_izquierda> <Expresion>
                              |   <Expresion> <Op_binario> <Expresion>
                              |   <Agregado1D>
                              |   <Agregado2D>
                              |   <Llamada_funcion> ;
<Agregado1D>                  : LLAVEIZQ <Expresiones> LLAVEDCH ;
<Agregado2D>                  : LLAVEIZQ <Listas>  PYC <Expresiones> LLAVEDCH ;
<Listas>                      : <Listas>  PYC <Expresiones>
                              |   <Expresiones> ;
<Expresiones>                 : <Expresion>, <Expresiones>
                              |   <Expresion> ;
<Llamada_funcion>             : <Identificador>PARIZQ <Expresiones> PARDCH
                              |   <Identificador>PARIZQ  PARDCH ;
<Op_unario_izquierda>         : !
                              |   +
                              |   - ;
<Op_binario>                  : ==
                              |   >=
                              |   <=
                              |   !=
                              |   *
                              |   /
                              |   +
                              |   -
                              |   ^
                              |   <
                              |   >
                              |   &&
                              |   || ;
<Sentencias>                  : <Sentencias> <Sentencia> ;
<Sentencia>                   : <Bloque>
                              |   <Sentencia_asignacion>
                              |   <Sentencia_if>
                              |   <Sentencia_while>
                              |   <Sentencia switch>
                              |   <Sentencia_break>
                              |   <Sentencia_return>
                              |   <Sentencia_entrada>
                              |   <Sentencia_salida> ;
<Sentencia_asignacion>        : <Identificador_comp> = <Expresion> PYC ;
<Sentencia_if>                : si PARIZQ <Expresion> PARDCH <Sentencia> <Sentencia_else> ;
<Sentencia_else>              : otro <Sentencia> ;
<Sentencia_while>             : mientras PARIZQ <Expresion> PARDCH <Sentencia> ;
<Sentencia_switch>            : casos PARIZQ <Expresion> PARDCH <Bloque_switch> ;
<Bloque_switch>               : LLAVEIZQ  <Opciones>  LLAVEDCH ;
<Opciones>                    : <Opciones> <Opcion>
                              |   <Opcion> <Opcion_pred>
                              |   <Opcion_pred> ;
<Opcion>                      : caso <Natural>: <Sentencias> ;
<Opcion_pred>                 : predeterminado: <Sentencias> ;
<Sentencia_break>             : roto PYC ;
<Sentencia_return>            : devolver <Expresion> ;
<Sentencia_entrada>           : entrada <Lista_id> PYC ;
<Lista_id>                    : <Lista_id>, <Identificador_comp>
                              |   <Identificador_comp> ;
<Lista_exp_cad>               : <Lista_exp_cad>, <Exp_cad>
                              |   <Exp_cad> ;
<Exp_cad>                     : <Expresion>
                              |   <Cadena> ;
<Sentencia_salida>            : salida <Lista_exp_cad> PYC ;

%%

#include "../P2/lex.yy.c"

int yyerror(char *msg)
 {
  printf("invalid string\n");
  exit(0);
 }

//driver code
main()
 {
  printf("enter the string\n");
  yyparse();
 }