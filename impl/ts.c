#include "ts.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"

#define DEBUG 0



/*
 * Halla índice de identificador de variable o procedimiento en TS
*/
int encuentraTS(char* identificador){

    if (DEBUG) {
        printf("[findTS] '%s' en línea %d\n", identificador, linea);
        fflush(stdout);
    }

    for(int j = TOPE - 1; j >= 0; j--)
        if (!strcmp(TS[j].nombre, identificador) && (TS[j].tipo_entrada == variable || TS[j].tipo_entrada == funcion))
            return j; // Devuelve primera ocurrencia de abajo a arriba

    return -1;
}

/*
 * Comprueba si un identificador está duplicado en su ámbito.
 * 0 si no es duplicado, 1 si sí lo es
 */
int esDuplicado(char* identificador){

    for(int j = TOPE - 1; j >= 0; j--){
        if (!strcmp(TS[j].nombre, identificador) && (TS[j].tipo_entrada == variable || TS[j].tipo_entrada == funcion))
            return 1;
        if (TS[j].tipo_entrada == marca)
            break;
    }
    return 0;
}

TipoDato tipoTS(char* identificador){

    int p = encuentraTS(identificador);
    if (p == -1)
        return no_asignado;

    return TS[p].tipo_dato;


}
// ---------------------------------------------------------------- //
// --------------------------- Impresión -------------------------- //
// ---------------------------------------------------------------- //


char* imprimeTipoE(TipoEntrada tipo){
    switch (tipo) {
        case marca: return "marca";
        case funcion : return "funcion";
        case variable: return "variable";
        case parametro_formal: return "parámetro";
        case instr_control: return "instrucción de control";
        default: return "error";
    }
}

char* imprimeTipoD(TipoDato tipo){
    switch (tipo) {
        case entero: return "entero";
        case real: return "real";
        case booleano: return "booleano";
        case caracter: return "carácter";
        case desconocido: return "desconocido";
        default: return "error";
    }
}

void imprimeTS(){
    char sangria[100] = "\0";
    printf("Tabla de símbolos en la línea %d:\n", linea);
    fflush(stdout);
    for (unsigned i = 0; i < TOPE; i++) {

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

// ---------------------------------------------------------------- //
// ----------------------- Lectura de tipos ----------------------- //
// ---------------------------------------------------------------- //

/*
 * Devuelve una cadena con el tipo que corresponda en C
 */
char* tipoCStr(TipoDato tipo) {
   
    switch(tipo) {
        case entero:
        case booleano: // en C las variables booleanas son int
            return "int";
        case real:
            return "double";
        case caracter:
            return "char";
        default:
            printf("[Línea %d] Error de implementación, %s no está asociado a ningún tipo nativo de C ni a una lista\n", linea, tipoStr(tipo));
            return "error"; // TODO: este error puede aparecer como consecuencia de una variable no declarada, en cuyo caso probablemente no debería mostrarse (ejemplo en el que aparece: b = b sin haber declarado b)
    }
}

/*
 * Devuelve una cadena con el tipo del parámetro
 */
char* tipoStr(TipoDato tipo){

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

// ---------------------------------------------------------------- //
// ---------------- Insertar en la tabla de símbolos -------------- //
// ---------------------------------------------------------------- //

/* Inserta entrada en TS */
void insertaTS(EntradaTS entrada){

    if (DEBUG) {
        printf("[insertaTS] entrada con nombre '%s' en línea %d\n", entrada.nombre, linea);
        fflush(stdout);
    }

    if (TOPE >= MAX_TS) {
        printf("[%d] Error: La tabla de símbolos está llena\n", linea);
        fflush(stdout);
        exit(2);
    }

    TS[TOPE] = entrada;
    TOPE++;
}

/*
 *  Introduce un identificador en la tabla de símbolos
 */
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
                          dimension2 };

    insertaTS(entrada);
}

void insertaVar(char* identificador, char* nombre_tipo, unsigned dimension1, unsigned dimension2){
    TipoDato tipo_dato = leeTipoDato(nombre_tipo);
    insertaVarTipo(identificador, tipo_dato, dimension1, dimension2);
}
/*
 * Inserta función en la tabla de símbolos
 */
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
                          dim2_ret };

    insertaTS(entrada);
    ultima_funcion = TOPE - 1;
    Subprog = 1; // Indica que hay que insertar parámetros como variables
}

/*
 * Inserta parámetro formal en la tabla de símbolos
 */
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

    TipoDato tipo_dato = leeTipoDato(nombre_tipo);
    EntradaTS entrada = { parametro_formal,
                          strdup(identificador),
                          tipo_dato,
                          0,
                          {NULL, NULL},
                          0,
                          0};

    insertaTS(entrada);
    TS[ultima_funcion].parametros += 1;
}

/*
 * Inserta el descriptor de una instrucción de control if/else
 */
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
                          0 };

    insertaTS(entrada);
}

/*
 * Inserta el descriptor de una instrucción de control while
 */
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
                          0 };

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
                          0 };

    insertaTS(entrada);
}

// ----------------------------------------------------------------- //
// ------------------- Entrada y salida de bloques  ---------------- //
// ----------------------------------------------------------------- //

// Inserta parámetros como variables en la TS
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

/*
 * Añade a la tabla de símbolos marca de comienzo
 */
void entraBloqueTS(){
  // Entrada que indica comienzo de bloque
    if(DEBUG){
        printf("Estoy entrando en un bloque.\n");
        fflush(stdout);
    }

    bloques_anidados++;
    const EntradaTS MARCA_BLOQUE = {marca, "[MARCA]", desconocido, 0, {NULL, NULL}, 0, 0};
    insertaTS(MARCA_BLOQUE);

    if(Subprog){
        insertaParametrosComoVariables();
        Subprog = 0;
    }
}


/*
 * Sal de bloque y elimina de la tabla de símbolos todos los símbolos hasta la última marca
 */
void salBloqueTS(){
    if(DEBUG){
        printf("Estoy saliendo de un bloque.\n");
        fflush(stdout);
    }

    bloques_anidados--;
    for(int j = TOPE - 1; j >= 0; j--){
        if(TS[j].tipo_entrada == marca){
            TOPE = j;
            return;
        }
    }

    printf("[Linea %d] Error de implementación, se intentó salir de un bloque cuando no hay\n", linea);
}


/* Sale de bloque y elimina de la tabla de símbolos todos los símbolos
 * hasta el último descriptor de una instrucción de control
 */
void salEstructuraControl(){
    if(DEBUG){
        printf("Estoy saliendo de una estructura de control.\n");
        fflush(stdout);
    }

    for(int j = TOPE - 1; j >= 0; j--){
        if(TS[j].tipo_entrada == instr_control){
            TOPE = j;
            free(TS[j].etiquetas_control.EtiquetaSalida);
            free(TS[j].etiquetas_control.EtiquetaElse);
            return;
        }
    }

    printf("[Linea %d] Error de implementación, se intentó salir de una estructura de control cuando no hay\n", linea);
}

/* Encuentra el nombre de la etiqueta de salida de la estructura de control actual
 */
char* encuentraGotoSalida(){
    for (int j = TOPE - 1; j >= 0; j--)
        if (TS[j].tipo_entrada == instr_control)
            return TS[j].etiquetas_control.EtiquetaSalida;

    printf("[Linea %d] Error de implementación, se intentó encontrar la etiqueta de salida de la estructura de control actual cuando no la hay\n", linea);
    return NULL;
}

/* Encuentra el nombre de la etiqueta de else de la estructura de control actual
 */
char* encuentraGotoElse(){
    for (int j = TOPE - 1; j >= 0; j--)
        if (TS[j].tipo_entrada == instr_control)
            return TS[j].etiquetas_control.EtiquetaElse;

    printf("[Linea %d] Error de implementación, se intentó encontrar la etiqueta de else de la estructura de control actual cuando no la hay\n", linea);
    return NULL;
}

/*
 *  Lee el tipo de dato
 */
TipoDato leeTipoDato(char* nombre_tipo) {

    if (DEBUG) {
        printf("[leeTipoDato] Lee tipo '%s' en línea %d\n", nombre_tipo, linea);
        fflush(stdout);
    }
 
    if(!strcmp(nombre_tipo, "entero"))
        return entero;
    else if(!strcmp(nombre_tipo, "real"))
        return real;
    else if(!strcmp(nombre_tipo, "booleano"))
        return booleano;
    else if(!strcmp(nombre_tipo, "caracter"))
        return caracter;

    printf("[Linea %d] Error de implementación, '%s' no es un tipo válido\n", linea, nombre_tipo);
    return desconocido;
}
