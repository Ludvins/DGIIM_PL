CC = gcc
LEX = flex
YACC = yacc
CFLAGS = -lfl
YCCFLAGS = -d

OBJ = obj
.PHONY: clean debug

all: sintactico

debug: YCCFLAGS += -vt
debug: sintactico

sintactico: $(OBJ)/y.tab.o $(OBJ)/main.o
	$(CC) $^ -o $@

$(OBJ)/y.tab.o: y.tab.c lex.yy.c
	$(CC) -c $< -o $@

$(OBJ)/main.o: main.c
	$(CC) -c $< -o $@

y.tab.h y.tab.c: sintactico.y
	$(YACC) $< $(YCCFLAGS)

lexico: lex.yy.c y.tab.h
	$(CC) $< -o $@ $(CFLAGS)

lex.yy.c: lexico.l y.tab.h
	$(LEX) $<

clean:
	-@rm -f lexico lex.yy.c
	-@rm -f sintactico y.tab.h y.tab.c y.output $(OBJ)/*
