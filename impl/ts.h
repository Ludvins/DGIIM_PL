#ifndef __TS_H_
#define __TS_H_


// ----------------------------------------------------------------- //
// ---------------- Declaración de variables globales -------------- //
// ----------------------------------------------------------------- //

#define MAX_TS 500
#define MAX_ARGS 50
// Cada símbolo tiene una estructura de tipo atributos.
#define YYSTYPE Atributos

unsigned int  tope = 0;              // Tope de la pila
unsigned int  sub_prog;              // Indicador de comienzo de bloque de un subprog
int           ultima_funcion = -1;   // Posición en la tabla de símbolos del último procedimiento
unsigned int  bloques_anidados = 0;  // Numero de bloques anidados
extern int    linea;


// ----------------------------------------------------------------- //
// ------------------- Declaración de estructuras ------------------ //
// ----------------------------------------------------------------- //
//
/*
 * TipoEntrada
 */
typedef enum {
  marca,            // Indica que la entrada es una marca de principio de bloque
  funcion,          // La entrada describe una funcion
  variable,         // La entrada describe una variable local
  parametro_formal, // La entrada describe un parámetro formal de una función
  instr_control
} TipoEntrada;

/*
 * TipoDato
 *
 * Sólo aplicable cuando sea función, variable o parametro_formal
 */
typedef enum {
  entero,    real,    booleano,    caracter,
  /* entero1D,  real1D,  booleano1D,  caracter1D, */
  /* entero2D,  real2D,  booleano2D,  caracter2D, */
  desconocido,
  no_asignado
} TipoDato;

/*
 * DescriptorDeInstrControl
 */
typedef struct {
  char* EtiquetaSalida;
  char* EtiquetaElse;
} DescriptorDeInstrControl;

/*
 * EntradaTS
 */
typedef struct {
  TipoEntrada               tipo_entrada;
  char*                     nombre;
  TipoDato                  tipo_dato;
  unsigned int              parametros;
  DescriptorDeInstrControl  etiquetas_control;
  unsigned int              t_dim1; //Tamaño de la primera dimension (Array)
  unsigned int              t_dim2; //Tamaño de la segunda dimension (Array)
} EntradaTS;

/*
 * Ids
 *
 * Lista de identificadores, y dimensiones de cada una de las variables que le corresponden.
 */
typedef struct {
  int        tope_id;
  char*      lista_ids[MAX_ARGS];
  unsigned*  lista_dims1[MAX_ARGS];
  unsigned*  lista_dims2[MAX_ARGS];
} Ids;

/*
 * Tipos
 *
 * Lista de tipos
 */

typedef struct {
  int        tope_tipo;
  TipoDato   lista_tipos[MAX_ARGS];
} Tipos;

/*
 * Atributos
 */
typedef struct {
  int           atrib;           // Atributo del símbolo (si tiene)
  char*         lexema;          // Nombre del lexema
  TipoDato      tipo;            // Tipo del símbolo
  Ids           lids;            // Lista de identificadores
  Tipos         ltipos;          // Lista de tipos de argumentos
} Atributos;

EntradaTS     TS[MAX_TS];           // Pila de la tabla de símbolos

// ----------------------------------------------------------------- //
// --- Lista de funciones y procedimientos para manejo de la TS  --- //
// ----------------------------------------------------------------- //


// -------------------------------------------------- //
// --------- Entrada y salida de bloques  ----------- //
// -------------------------------------------------- //

/*
 * Inserta los parámetros de la ultima funcion como variables en la TS.
 */
void insertaParametrosComoVariables();
/*
 * Añade a la tabla de símbolos marca de comienzo
 */
void entraBloqueTS();

/*
 * Sal de bloque y elimina de la tabla de símbolos todos los símbolos hasta la última marca
 */
void salBloqueTS();

/*
 * Sale del bloque y elimina en la tabla de símbolos todos los símbolos
 * hasta el último descriptor de una instrucción de control.
 */
void salEstructuraControl();

/*
 * Encuentra el nombre de la etiqueta de salida de la estructura de control actual
 */
char* encuentraGotoSalida();

/*
 * Encuentra el nombre de la etiqueta de ese de la estructura de control actual
 */
char* encuentraGotoElse();

// -------------------------------------------------- //
// -------- Insercion en tabla de simbolos  --------- //
// -------------------------------------------------- //

/*
 * Inserta la entrada en la Tabla de Símbolos
 */
void insertaTS (EntradaTS entrada);

/*
 * Introduce una variable en la tabla de símbolos, dado su tipo como TipoDato
 */
void insertaVarTipo(char* identificador, TipoDato tipo_dato, unsigned dimension1, unsigned dimension2);

/*
 * Inserta una variable en la tabla de símbolos, dado su tipo como string.
 *
 * Llama a "leeTipoDato" y luego a "insertaVarTipo"
 */
void insertaVar(char* identificador, char* nombre_tipo, unsigned dimension1, unsigned dimension2);

/*
 * Inserta la función en la tabla de símbolos, requiere de el tipo y las dimensiones del valor que devuelve.
 */
void insertaFuncion(char* identificador, TipoDato tipo_ret, unsigned dim1_ret, unsigned dim2_ret);

/*
 * Inserta el parámetro formal en la tabla de símbolos.
 */
void insertaParametro(char* identificador, char* nombre_tipo);

/*
 * Inserta el descriptor de una instrucción if/else
 */
void insertaIf(char* etiqueta_salida, char* etiqueta_else);

/*
 * Inserta el descriptor de una instrucción de control while.
 */
void insertaWhile(char* etiqueta_entrada, char* etiqueta_salida);

/*
 * Inserta el descriptor de una instrucción de control de switch.
 */
void insertaSwitch(char* etiqueta_entrada, char* etiqueta_salida);

// -------------------------------------------------- //
// -------- Extracción de informacion de TS --------- //
// -------------------------------------------------- //

/*
 * Halla el índice de identificador de variable o procedimiento en TS
 */
int encuentraTS(char* identificador);

/*
 * Encuentra el identificador en la tabla de símbolos y devuelve su tipo.
 */
TipoDato encuentraTipo(char* identificador);

/*
 * Comprueba si un identificador está duplicado en su ámbito.
 * 0 si no es duplicado, 1 si sí lo es
 */
int esDuplicado(char* identificador);

// -------------------------------------------------- //
// ---------- Transformaciones de TipoDato ---------- //
// -------------------------------------------------- //

/*
 * Transforma el tipo de char* a TipoDato
 */
TipoDato strToTipodato(char* nombre_tipo);

/*
 * Transforma el tipo de tipoDato a string
 */
char* tipodatoToStr(TipoDato tipo);

/*
 * Transforma el tipo de tipoDato a string (nombre en C)
 */
char* tipodatoToStrC(TipoDato tipo);


// -------------------------------------------------- //
// --------------- Impresión DEBUG ------------------ //
// -------------------------------------------------- //

/*
 * Imprime el tipo de la entrada.
 */
char* imprimeTipoE(TipoEntrada tipo);

/*
 * Imprime el tipo de dato
 */
char* imprimeTipoD(TipoDato tipo);

/*
 * Imprime la tabla de símbolos
 */
void imprimeTS();


// ---------------------------------------------------------------- //
// ---- Fin de funciones y procedimientos para manejo de la TS ---- //
// ---------------------------------------------------------------- //

#endif // __TS_H_
