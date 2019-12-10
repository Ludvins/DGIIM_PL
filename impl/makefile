CC = gcc
LEX = flex
YACC = yacc
CFLAGS = -lfl
YCCFLAGS = -d

OBJ = obj

.PHONY: all clean debug

all: semantico

debug: YCCFLAGS += -vt
debug: semantico

semantico: $(OBJ)/y.tab.o $(OBJ)/main.o $(OBJ)/ts.o
	$(CC) $^ -o $@

$(OBJ)/y.tab.o: y.tab.c lex.yy.c
	$(CC) -c $< -o $@

$(OBJ)/main.o: main.c
	$(CC) -c $< -o $@

$(OBJ)/ts.o: ts.c ts.h
	$(CC) -c $< -o $@

$(OBJ)/error.o: error.c error.h
	$(CC) -c $< -o $@

y.tab.h y.tab.c: semantico.y
	$(YACC) $< $(YCCFLAGS)

lexico: lex.yy.c y.tab.h
	$(CC) $< -o $@ $(CFLAGS)

lex.yy.c: lexico.l y.tab.h
	$(LEX) $<

clean:
	-@rm -f lexico lex.yy.c
	-@rm -f semantico y.tab.h y.tab.c y.output $(OBJ)/*
