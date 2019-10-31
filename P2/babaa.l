
// Declaraciones
tipo      "entero"|"real"|"buleano"|"caracter"
id        [a-zA-Z_][a-zA-Z0-9_]*
constante -?[0-9]+(.[0-9]+)?|"verdadero"|"falso"|\'[^\']\'
opbin     [<>]=? \| [=!]= \| "*"| "/"\| "^" \| " \|\| " \| "&&"
masmenos  +|-
cadena    \"[^\"]*\"

%%

"programa()" #return CABECERA
"{" #return LLAVEIZQ
"}" #return LLAVEDCH
"var" #return INILOCAL
"finvar" #return FINLOCAL
{tipo} #return TIPO
"si" #return IF
"otro" #return ELSE
"mientras" #return WHILE
"casos" #return SWITCH
"caso" #return CASE
"roto" #return BREAK
"entrada" #return CIN
"salida" #return COUT
"predeterminado" #return PREDET
"=" #return ASIG
"[" #return CORCHIZQ
"]" #return CORCHDCH
"," #return COMA
";" #return PYC
":" #return PYP
"(" #return PARIZQ
")" #return PARDCH
{id} #return IDENTIFICADOR
{constante} #return CONSTANTE
"devolver" #return RETURN
"!"

.   {; printf("Error: %s", yytext);}
%%

int main()

{
    yylex();
}
