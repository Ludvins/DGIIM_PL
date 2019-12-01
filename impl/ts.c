#include "ts.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"

#define DEBUG 0

// Tope de la tabla de símbolos
long int tope = 0;

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
        case array:
            return "Array";
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
        case array:
            return "array";
        case desconocido:
            return "desconocido";
        case no_asignado:
            return "no-asignado";
        default:
            return "error";
    }
}


/* Inserta entrada en TS */
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


/* 
 * Halla índice de identificador de variable o procedimiento en TS
*/
int findTS(char* identificador){

    if (DEBUG) {
        printf("[findTS] '%s' en línea %d\n", identificador, linea);
        fflush(stdout);
    }

    for(int j = tope - 1; j >= 0; j--)
        if (!strcmp(TS[j].nombre, identificador) && (TS[j].tipo_entrada == variable || TS[j].tipo_entrada == funcion))
            return j; // Devuelve primera ocurrencia de abajo a arriba

    return -1;
}
