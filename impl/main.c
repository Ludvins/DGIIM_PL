#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
FILE * main_file;
FILE * func_file;
extern unsigned error;
int yyparse();  // Para evitar warning al compilar

const char * DEFAULT_OUT = "salida.c";

int main(int argc, char * argv[]) {
  if (argc > 1) {
    yyin = fopen (argv[1], "rt");
    if (yyin == NULL) {
      printf ("> El fichero %s no se puede abrir\n", argv[1]);
      exit (1);
    }
    else {
      printf("> Leyendo fichero '%s'...\n", argv[1]);
    }
  }
  else {
    printf("> Leyendo entrada estándar...\n");
    yyin = stdin;
  }

  fflush(stdout);

  char nombre[100];

  if (argc > 2) {
    sprintf(nombre, argv[2]);
  }
  else {
    sprintf(nombre, DEFAULT_OUT);
  }
  main_file = fopen(nombre, "w");
  func_file = fopen("dec_fun", "w");

  yyparse();

  printf("> Se ha llegado al final del programa.\n");
  printf("> Número de errores: %d.\n", error);

  if (!error) {
    char llamada[100];

    printf("> Compilando programa %s...\n", nombre);
    sprintf(llamada, "gcc %s -o salida.out", nombre);
    int e = system(llamada);

    if (e) {
      printf("> Se produjeron errores de compilación.\n");
    }

    else {
      printf("> Se ha generado el ejecutable salida.out.\n");
    }

  }

  return error;
}
