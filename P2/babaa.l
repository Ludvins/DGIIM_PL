
%%

"programa()" ;

.   {; printf("Error: %s", yytext);}
%%

int main()

{

    yylex();

    printf("\n total no. of token = %d\n", n);

}

"programa()"~
"{"~
"}"~
"var"~
"finvar"~
"entero"~ \vert ~"real"~ \vert ~"buleano"~ \vert ~"caracter"~

"si"~
"otro"~
"mientras"~
"casos"~
"caso"~
"roto"~
"entrada"~
"salida"~
"predeterminado"~
"="~
"["~
"]"~
","~
";"~
":"~
"("~
")"~
[a-zA-Z_][a-zA-Z0-9_]*~
-?[0-9]+(.[0-9]+)?~ \vert ~"verdadero"~ \vert ~"falso"~
vert ~\'[^\']\'~
"devolver"~
[<>]=?~ \vert ~[=!]=~ \vert ~"*"~
vert ~"/"~\vert ~"^"~ \vert ~"~ \vert\vert ~"~ \vert ~"&&"~
"!"~
+~ \vert ~-~
\"[^\"]*\"~
