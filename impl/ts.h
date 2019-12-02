#ifndef __TS_H_
#define __TS_H_

typedef enum {
  marca,            // Indica que la entrada es una marca de principio de bloque
  funcion,          // La entrada describe una funcion
  variable,         // La entrada describe una variable local
  parametro_formal, // La entrada describe un parámetro formal de un procedimiento o función situado en una entrada anterior de la tabla.
  instr_control
} TipoEntrada;


// Tipo de dato.
// Sólo aplicable cuando sea función, variable o parametroFormal

typedef enum {
  entero,
  real,
  booleano,
  caracter,
  array,
  desconocido,
  no_asignado
} TipoDato;

typedef struct {
  char* EtiquetaSalida;
  char* EtiquetaElse;
} DescriptorDeInstrControl;

typedef struct {
  TipoEntrada  tipo_entrada;
  char*        nombre;
  TipoDato     tipo_dato;
  unsigned int parametros;
  DescriptorDeInstrControl etiquetas_control;
  unsigned int dimensiones;
  unsigned int t_dim1;
  unsigned int t_dim2;
} EntradaTS;


#define MAX_TS 500
#define MAX_IDS 50
#define MAX_ELEM 50

unsigned int  TOPE = 0;            // Tope de la pila
unsigned int  Subprog;             // Indicador de comienzo de bloque de un subprog
unsigned int ultima_funcion = -1;  // Posición en la tabla de símbolos del último procedimiento
unsigned int bloques_anidados = 0; // Numero de bloques anidados
EntradaTS     TS[MAX_TS];          // Pila de la tabla de símbolos
extern int linea;

typedef struct {
  int tope_id;
  char* lista_ids[MAX_IDS];
} Ids;

typedef struct {
  int tope_elem;
  TipoDato tipos[MAX_ELEM];
} Elem;

typedef struct {
  int      atrib;       // Atributo del símbolo (si tiene)
  char*    lexema;      // Nombre del lexema
  TipoDato tipo;        // Tipo del símbolo
  Ids      lid;         // Lista de identificadores
  Elem     el;          // Lista de lementos
} Atributos;


//  A partir de ahora, cada símbolo tiene una estructura de tipo atributos.
#define YYSTYPE Atributos

// ----------------------------------------------------------------- //
// --- Lista de funciones y procedimientos para manejo de la TS  --- //
// ----------------------------------------------------------------- //

void entraBloqueTS();
void salBloqueTS();

void insertaVar(char* identificador, char* nombre_dato);
void insertaFuncion(char* identificador);
void insertaParametro(char* identificador, char* nombre_dato);

void insertaIf(char* etiqueta_salida, char* etiqueta_else);
void insertaWhile(char* etiqueta_entrada, char* etiqueta_salida);
void insertaSwitch(char* etiqueta_entrada, char* etiqueta_salida);
void salEstructuraControl();

TipoDato tipoTS(char* identificador);
// Lee el tipo de dato.
TipoDato leeTipoDato(char * nombre_tipo);

// Devuelve una cadena con el tipo del parámetro.
char* tipoStr(TipoDato tipo);
// Devuelve una cadena con el tipo que corresponde en C
char* tipoCStr(TipoDato tipo);

// Halla el índice de identificador de variable o procedimiento en TS
int encuentraTS(char* identificador);

char* encuentraGotoSalida();
char* encuentraGotoElse();

// ---------------------------------------------------------------- //
// ---- Fin de funciones y procedimientos para manejo de la TS ---- //
// ---------------------------------------------------------------- //


#endif // __TS_H_
