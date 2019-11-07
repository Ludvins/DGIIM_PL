#!/usr/bin/env bash

flex babaa.l && gcc lex.yy.c -o lexico -lfl && ./lexico $1
