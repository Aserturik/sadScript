#!/usr/bin/env bash
set -euo pipefail

bison -d a_sintactico.y
flex a_lexico.l
cc lex.yy.c a_sintactico.tab.c -o sadScript -lfl -lm
chmod +x sadScript
