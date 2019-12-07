#include "ts.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"

#define DEBUG 0

void insertaParametrosComoVariables(){
    for (unsigned i = 1; i <= TS[ultima_funcion].parametros; i++){
        EntradaTS entrada = TS[ultima_funcion + i];
        insertaVarTipo(
            entrada.nombre,
            entrada.tipo_dato,
            entrada.t_dim1,
            entrada.t_dim2
        );
    }
}

void entraBloqueTS(){

    if(DEBUG){
        printf("Estoy entrando en un bloque.\n");
        fflush(stdout);
    }

    bloques_anidados++;
    const EntradaTS MARCA_BLOQUE = {marca, "[MARCA]", desconocido, 0, {NULL, NULL}, 0, 0};
    insertaTS(MARCA_BLOQUE);

    if(sub_prog){
        insertaParametrosComoVariables();
        sub_prog = 0;
    }
}

void salBloqueTS(){
    if(DEBUG){
        printf("Estoy saliendo de un bloque.\n");
        fflush(stdout);
    }

    bloques_anidados--;
    for(int j = tope - 1; j >= 0; j--){
        if(TS[j].tipo_entrada == marca){
            tope = j;
            return;
        }
    }
    printf("[Linea %d] Error de implementación, se intentó salir de un bloque cuando no hay\n", linea);
}

void salEstructuraControl(){
    if(DEBUG){
        printf("Estoy saliendo de una estructura de control.\n");
        fflush(stdout);
    }

    for(int j = tope - 1; j >= 0; j--){
        if(TS[j].tipo_entrada == instr_control){
            tope = j;
            free(TS[j].etiquetas_control.EtiquetaSalida);
            free(TS[j].etiquetas_control.EtiquetaElse);
            return;
        }
    }

    printf("[Linea %d] Error de implementación, se intentó salir de una estructura de control cuando no hay\n", linea);
}

char* encuentraGotoSalida(){
    for (int j = tope - 1; j >= 0; j--)
        if (TS[j].tipo_entrada == instr_control)
            return TS[j].etiquetas_control.EtiquetaSalida;

    printf("[Linea %d] Error de implementación, se intentó encontrar la etiqueta de salida de la estructura de control actual cuando no la hay\n", linea);
    return NULL;
}

char* encuentraGotoElse(){
    for (int j = tope - 1; j >= 0; j--)
        if (TS[j].tipo_entrada == instr_control)
            return TS[j].etiquetas_control.EtiquetaElse;

    printf("[Linea %d] Error de implementación, se intentó encontrar la etiqueta de else de la estructura de control actual cuando no la hay\n", linea);
    return NULL;
}

void insertaTS(EntradaTS entrada){

    if (DEBUG) {
        printf("[insertaTS] entrada con nombre '%s' en línea %d\n", entrada.nombre, linea);
        fflush(stdout);
    }

    if (tope >= MAX_TS) {
        printf("[%d] Error: La tabla de símbolos está llena\n", linea);
        fflush(stdout);
        exit(2);
    }

    TS[tope] = entrada;
    tope++;
}

void insertaVarTipo(char* identificador, TipoDato tipo_dato, unsigned dimension1, unsigned dimension2){

    if (DEBUG) {
        printf("[insertaVar] variable '%s' con tipo '%s' en línea %d\n", identificador, imprimeTipoD(tipo_dato), linea);
        fflush(stdout);
    }

    if(esDuplicado(identificador)){
        printf("[%d] Error semántico: Identificador duplicado '%s'\n", linea, identificador);
        return;
    }

    EntradaTS entrada = { variable,
                          strdup(identificador),
                          tipo_dato,
                          0,
                          {NULL, NULL},
                          dimension1,
                          dimension2 
                        };

    insertaTS(entrada);
}

void insertaVar(char* identificador, char* nombre_tipo, unsigned dimension1, unsigned dimension2){
    TipoDato tipo_dato = strToTipodato(nombre_tipo);
    insertaVarTipo(identificador, tipo_dato, dimension1, dimension2);
}

void insertaFuncion(char* identificador, TipoDato tipo_ret, unsigned dim1_ret, unsigned dim2_ret){

    if (DEBUG) {
        printf("[insertaFuncion] procedimiento '%s' en línea %d\n", identificador, linea);
        fflush(stdout);
    }

    if(esDuplicado(identificador)){
        printf("[%d] Error semántico: Identificador duplicado '%s'\n", linea, identificador);
        return;
    }

    EntradaTS entrada = { funcion,
                          strdup(identificador),
                          tipo_ret,
                          0, // Inicialmente hay 0 parámetros
                          {NULL, NULL},
                          dim1_ret,
                          dim2_ret 
                        };

    insertaTS(entrada);
    ultima_funcion = tope - 1;
    sub_prog = 1; // Indica que hay que insertar parámetros como variables
}

void insertaParametro(char* identificador, char* nombre_tipo){

    if (DEBUG) {
        printf("[insertaParametro] '%s' con tipo '%s' en línea %d\n", identificador, nombre_tipo, linea);
        fflush(stdout);
    }

    if (ultima_funcion == -1) {
        printf("[%d] Error de implementación: Parámetro formal '%s' sin procedimiento anterior\n",
               linea, identificador);
        return;
    }

    TipoDato tipo_dato = strToTipodato(nombre_tipo);
    EntradaTS entrada = { parametro_formal,
                          strdup(identificador),
                          tipo_dato,
                          0,
                          {NULL, NULL},
                          0,
                          0
                        };

    insertaTS(entrada);
    TS[ultima_funcion].parametros += 1;
}

void insertaIf(char* etiqueta_salida, char* etiqueta_else) {

    if (DEBUG){
        printf("[insertaIf] etiqueta de salida '%s'", etiqueta_salida);
       
        if (etiqueta_else != NULL)
            printf(" y etiqueta de else '%s'", etiqueta_else);

        printf(" en línea %d\n", linea);
        fflush(stdout);
    }

    EntradaTS entrada = { instr_control,
                          "",
                          desconocido,
                          0,
                          {etiqueta_salida, etiqueta_else},
                          0,
                          0 
                        };

    insertaTS(entrada);
}

void insertaWhile(char* etiqueta_entrada, char* etiqueta_salida) {

    if (DEBUG) {
        printf("[insertaWhile] etiqueta de entrada '%s' y etiqueta de salida '%s' en línea %d\n", etiqueta_entrada, etiqueta_salida, linea);
        fflush(stdout);
    }

    EntradaTS entrada = { instr_control,
                          "",
                          desconocido,
                          0,
                          {etiqueta_salida, etiqueta_entrada},
                          0,
                          0 
                        };

    insertaTS(entrada);
}

void insertaSwitch(char* etiqueta_entrada, char* etiqueta_salida) {
        if (DEBUG) {
        printf("[insertaSwitch] etiqueta de entrada '%s' y etiqueta de salida '%s' en línea %d\n", etiqueta_entrada, etiqueta_salida, linea);
        fflush(stdout);
    }

    EntradaTS entrada = { instr_control,
                          "",
                          desconocido,
                          0,
                          {etiqueta_salida, etiqueta_entrada},
                          0,
                          0 
                        };

    insertaTS(entrada);
}

int encuentraTS(char* identificador){

    if (DEBUG) {
        printf("[encuentraTS] '%s' en línea %d\n", identificador, linea);
        fflush(stdout);
    }

    for(int j = tope - 1; j >= 0; j--)
        if (!strcmp(TS[j].nombre, identificador) && (TS[j].tipo_entrada == variable || TS[j].tipo_entrada == funcion))
            return j; 

    return -1;
}

TipoDato encuentraTipo(char* identificador){

    int p = encuentraTS(identificador);
    if (p == -1)
        return no_asignado;

    return TS[p].tipo_dato;
}

int esDuplicado(char* identificador){

    if (DEBUG) {
        printf("[esDuplicado] '%s' en línea %d\n", identificador, linea);
        fflush(stdout);
    }

    for(int j = tope - 1; j >= 0; j--){
        if (!strcmp(TS[j].nombre, identificador)
          && (TS[j].tipo_entrada == variable || TS[j].tipo_entrada == funcion))
            return 1;
        if (TS[j].tipo_entrada == marca)
            break;
    }
    return 0;
}

unsigned nDimensiones(char* dimensiones){

    if (DEBUG) {
        printf("[nDimensiones] '%s' en línea %d\n", identificador, linea);
        fflush(stdout);
    }
    int n_dims = 0;

    for(int j = tope - 1; j >= 0; j--)
        if (strcmp(TS[j].nombre, identificador) 
            && (TS[j].tipo_entrada == variable || TS[j].tipo_entrada == funcion))
            
            if (TS[j].t_dim1 != 0)
                n_dims++;
            if (TS[j].t_dims2 != 0)
                n_dims++;
            break;

    return n_dims;
}

TipoDato strToTipodato(char* nombre_tipo) {

    if (DEBUG) {
        printf("[strToTipodato] Lee tipo '%s' en línea %d\n", nombre_tipo, linea);
        fflush(stdout);
    }

    if(!strcmp(nombre_tipo, "entero"))
        return entero;
    if(!strcmp(nombre_tipo, "real"))
        return real;
    if(!strcmp(nombre_tipo, "booleano"))
        return booleano;
    if(!strcmp(nombre_tipo, "caracter"))
        return caracter;

    printf("[Linea %d] Error de implementación, '%s' no es un tipo válido\n", linea, nombre_tipo);
    return desconocido;
}

char* tipodatoToStr(TipoDato tipo){

    if (DEBUG) {
        printf("[tipodatoToStr] Lee tipo '%s' en línea %d\n", nombre_tipo, linea);
        fflush(stdout);
    }
    switch (tipo) {
        case entero:
            return "entero";
        case real:
            return "real";
        case booleano:
            return "booleano";
        case caracter:
            return "caracter";
        case desconocido:
            return "desconocido";
        case no_asignado:
            return "no-asignado";
        default:
            return "error";
    }
}

char* tipodatoToStrC(TipoDato tipo) {

    switch(tipo) {
        case entero:
        case booleano:
            return "int";
        case real:
            return "double";
        case caracter:
            return "char";
        default:
            printf("[Línea %d] Error de implementación, %s no está asociado a ningún tipo nativo de C ni a una lista\n", linea, tipodatoToStr(tipo));
            return "error";
    }
}

char* imprimeTipoE(TipoEntrada tipo){
    switch (tipo) {
        case marca: 
            return "marca";
        case funcion: 
            return "funcion";
        case variable: 
            return "variable";
        case parametro_formal: 
            return "parámetro";
        case instr_control: 
            return "instrucción de control";
        default: 
            return "error";
    }
}

char* imprimeTipoD(TipoDato tipo){
    switch (tipo) {
        case entero: 
            return "entero";
        case real: 
            return "real";
        case booleano: 
            return "booleano";
        case caracter: 
            return "carácter";
        case desconocido: 
            return "desconocido";
        default: 
            return "error";
    }
}

void imprimeTS(){
    char sangria[100] = "\0";
    printf("Tabla de símbolos en la línea %d:\n", linea);
    fflush(stdout);
    for (unsigned i = 0; i < tope; i++) {

        if (TS[i].tipo_entrada == marca) {
            strcat(sangria, "  ");
            printf("%s%s [marca]\n", sangria, "↳");
        }
        else {
            printf("%s%s: '%s'", sangria, imprimeTipoE(TS[i].tipo_entrada), TS[i].nombre);

            if(TS[i].tipo_entrada == variable || TS[i].tipo_entrada == parametro_formal)
                printf(" de tipo %s\n", imprimeTipoD(TS[i].tipo_dato));
            else
                printf(" con %d parámetros\n", TS[i].parametros);

        }
    }
}

int esNumero(TipoDato tipo){
    if (tipo == entero || tipo == real)
        return 1;
    else
        return 0;
}

TipoDato getTipoConstante(char* constante){
    c = constante[0]
    if (c == 'v' || c == 'f')
        return booleano;
    if (c == '\'')
        return caracter;
    return real;

}
