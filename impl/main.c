#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
FILE * fout;
extern unsigned error;
int yyparse();  // Para evitar warning al compilar

const char * DEFAULT_OUT = "salida.c";

int main(int argc, char * argv[]) {
  if (argc > 1) {
    yyin = fopen (argv[1], "rt");
    if (yyin == NULL) {
      fprintf (stderr, "---> El fichero %s no se puede abrir\n", argv[1]);
      exit (1);
    }
    else {
      fprintf(stderr, "---> Leyendo fichero '%s'...\n", argv[1]);
    }
  }
  else {
    fprintf(stderr, "---> Leyendo entrada estándar...\n");
    yyin = stdin;
  }

  fflush(stderr);

  char nombre[100];

  if (argc > 2) {
    sprintf(nombre, argv[2]);
  }
  else {
    sprintf(nombre, DEFAULT_OUT);
  }
  fout = fopen(nombre, "w");

  yyparse();

  fprintf(stderr, "---> Se ha llegado al final del programa.\n");
  fprintf(stderr, "Número de errores: %d.\n", error);

  if (!error) {
    char llamada[100];

    fprintf(stderr, "Compilando programa...\n");
    sprintf(llamada, "gcc %s -o salida.out", nombre);
    system(llamada);
  }

  return error;
}
