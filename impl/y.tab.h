/* A Bison parser, made by GNU Bison 3.4.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2019 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    CABECERA = 258,
    INILOCAL = 259,
    FINLOCAL = 260,
    LLAVEIZQ = 261,
    LLAVEDCH = 262,
    CORCHIZQ = 263,
    CORCHDCH = 264,
    PARIZQ = 265,
    PARDCH = 266,
    PYC = 267,
    COMA = 268,
    PYP = 269,
    TIPO = 270,
    IDENTIFICADOR = 271,
    NATURAL = 272,
    CONSTANTE = 273,
    CADENA = 274,
    ASIG = 275,
    IF = 276,
    ELSE = 277,
    WHILE = 278,
    SWITCH = 279,
    CASE = 280,
    PREDET = 281,
    BREAK = 282,
    RETURN = 283,
    CIN = 284,
    COUT = 285,
    OPBIN = 286,
    OPUNARIOIZQ = 287,
    MASMENOS = 288
  };
#endif
/* Tokens.  */
#define CABECERA 258
#define INILOCAL 259
#define FINLOCAL 260
#define LLAVEIZQ 261
#define LLAVEDCH 262
#define CORCHIZQ 263
#define CORCHDCH 264
#define PARIZQ 265
#define PARDCH 266
#define PYC 267
#define COMA 268
#define PYP 269
#define TIPO 270
#define IDENTIFICADOR 271
#define NATURAL 272
#define CONSTANTE 273
#define CADENA 274
#define ASIG 275
#define IF 276
#define ELSE 277
#define WHILE 278
#define SWITCH 279
#define CASE 280
#define PREDET 281
#define BREAK 282
#define RETURN 283
#define CIN 284
#define COUT 285
#define OPBIN 286
#define OPUNARIOIZQ 287
#define MASMENOS 288

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
