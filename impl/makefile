CC=gcc
LEX=flex
YACC=yacc
CFLAGS=-lfl

.PHONY: clean

sintactico: y.tab.c lex.yy.c
	$(CC) $^ -o $@

y.tab.h y.tab.c: babaa.y
	$(YACC) -d $<

debug: babaa.y
	$(YACC) -v $<

lexico: lex.yy.c y.tab.h
	$(CC) $< -o $@ $(CFLAGS)

lex.yy.c: babaa.l
	$(LEX) $<

clean:
	-@rm -f lexico lex.yy.c
	-@rm -f sintactico y.tab.h y.tab.c
