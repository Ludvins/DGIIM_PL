#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
int yyparse();  // Para evitar warning al compilar

int main(int argc, char * argv[]) {
  if (argc >= 2) {
    yyin = fopen (argv[1], "rt");
    if (yyin == NULL) {
      printf ("El fichero %s no se puede abrir\n", argv[1]);
      exit (1);
    }
    else {
      printf("Leyendo fichero '%s'...\n", argv[1]);
    }
  }
  else {
    printf("Leyendo entrada estándar...\n");
    yyin = stdin;
  }

  int val = yyparse();

  if (!val)
    printf("--> Programa sintácticamente correcto.\n");
  else
    printf("--> Hay errores sintácticos.\n");

  return val;
}
