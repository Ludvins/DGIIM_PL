CC=gcc
LEX=flex
CFLAGS=-lfl

.PHONY: clean

lexico: lex.yy.c
	$(CC) lex.yy.c -o lexico $(CFLAGS)

lex.yy.c: babaa.l
	$(LEX) babaa.l

clean:
	-@rm lexico lex.yy.c
